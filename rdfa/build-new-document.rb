#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'environment-rdfa'

UPDATED_DATA = File.join File.expand_path('../data', __dir__), 'rdfa-updated.html'

# Custom vocabularies
VOCAB = 'http://schema.org/'
Schema = RDF::Vocabulary.new VOCAB
VOCAB_OER = 'http://oerschema.org/'
OER = RDF::Vocabulary.new VOCAB_OER
VOCAB_OCX = "https://github.com/K12OCX/k12ocx-specs/"
OCX = RDF::Vocabulary.new VOCAB_OCX

class DataParser
  attr_reader :main_info, :lessons

  def initialize(source)
    # Source graph
    @graph = RDF::Repository.new.from_html File.read(source)
  end

  def parse
    # Traverse the graph and look for main part of the page
    @main_entity = graph.query([nil, Schema.mainEntity]).first&.object
    raise 'Cannot find mainEntity!' if main_entity.nil?

    @main_info = fetch_main_info
    @lessons = fetch_lessons
  end

  private

  attr_reader :main_entity, :graph

  def fetch_activities_for(lesson)
    [].tap do |data|
      graph.query([lesson.subject, Schema.hasPart]).each do |part|
        graph.query([part.object, nil, OER.Activity]) do |activity|
          # iterate over child objects
          data << {}.tap do |result|
            graph.query([activity.subject]).each do |statement|
              # Iterate over activity parts
              result[:materials] = fetch_materials_for statement

              # TODO: Add support for other types
              next unless statement.object.is_a?(RDF::Literal)
              fetch_literals statement, result
            end
          end
        end
      end
    end
  end

  def fetch_lessons
    [].tap do |data|
      # <section id="Lesson1" property="hasPart" resource="#Lesson1" typeof="CreativeWork oer:Lesson">
      graph.query([main_entity, Schema.hasPart]).each do |part|
        graph.query([part.object, nil, OER.Lesson]) do |lesson|
          # iterate over child objects
          data << {}.tap do |result|
            graph.query([lesson.subject]).each do |statement|
              # TODO: Add support for other types
              next unless statement.object.is_a?(RDF::Literal)
              fetch_literals statement, result
            end
            result[:activities] = fetch_activities_for lesson
          end
        end
      end
    end
  end

  def fetch_literals(from, into)
    key = from.predicate.object[:path].tr('/', '')
    into[key] = {
      statement: from,
      value: from.object.value
    }
  end

  def fetch_main_info
    {}.tap do |data|
      graph.query([main_entity]).each do |statement|
        # TODO: Add support for other types
        next unless statement.object.is_a?(RDF::Literal)

        key = statement.predicate.object[:path].tr('/', '')
        data[key] = {
          statement: statement,
          value: statement.object.value
        }
      end
    end
  end

  def fetch_materials_for(activity)
    [].tap do |data|
      graph.query([activity.subject, OCX.material]).each do |material|
        data << {}.tap do |result|
          graph.query([material.object]).each do |statement|
            fetch_literals statement, result
          end
        end
      end
    end
  end
end

data = DataParser.new(SOURCE_DATA)
data.parse

# Build the new HTML
doc = Nokogiri::HTML::Document.parse '<!doctype html><html lang="en"><head></head><body></body></html>'
doc.root.at_xpath('head').add_child doc.create_element('link', href: STYLE_CDN, rel: 'stylesheet')

body = doc.at_xpath('//body')
body['prefix'] = "ocx: #{VOCAB_OCX} oer: #{VOCAB_OER}"
body['typeof'] = 'WebPage'
body['vocab'] = VOCAB
main = doc.create_element('div', property: 'mainEntity', typeof: 'CreativeWork ocx:SupplementalMaterial')
body.add_child main

#
# Display the root information
#
main_info = data.main_info
table = <<~HTML
  <table class="table">
    <tbody>
      <tr>
        <td>Name</td>
        <td property="#{main_info.dig('name', :statement).predicate.value}">
          #{main_info.dig('name', :value)}
        </td>
      </tr>
      <tr>
        <td>Learning resource type</td>
        <td property="#{main_info.dig('learningResourceType', :statement).predicate.value}">
          #{main_info.dig('learningResourceType', :value)}
        </td>
      </tr>
      <tr>
        <td>Description</td>
        <td property="#{main_info.dig('description', :statement).predicate.value}">
          #{main_info.dig('description', :value)}
        </td>
      </tr>
      <tr>
        <td>Creator</td>
        <td property="#{main_info.dig('creator', :statement).predicate.value}">
          #{main_info.dig('creator', :value)}
        </td>
      </tr>
    </tbody>
  </table>
HTML
main.add_child table

#
# Display lessons
#
data.lessons.each do |lesson|
  activities = [].tap do |result|
    lesson[:activities].each do |activity|
      activity[:materials].each.with_index do |material, idx|
        result << <<~HTML
          <p>Activity: #{idx + 1}</p>
          <div>#{material.dig('mainContent', :value)}</div>
        HTML
      end
    end
  end

  html = <<~HTML
    <div>
      <h4 property="#{lesson.dig('name', :statement).predicate.value}">
        Lesson: #{lesson.dig('name', :value)}
      </h4>
      <dl class="row">
        <dt property="#{lesson.dig('learningResourceType', :statement).predicate.value}" class="col-sm-3">
          Learning resource type
        </dt>
        <dd class="col-sm-9">#{lesson.dig('learningResourceType', :value)}</dd>
      </dl>
      #{activities.join}
    </div>
    <br/>
    <br/>
    <br/>
  HTML
  main.add_child html
end


# Write update data
File.open(UPDATED_DATA, 'wb') { |f| f.write doc.to_html }
