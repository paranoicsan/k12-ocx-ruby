#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'environment'

SCRIPT_SELECTOR = 'script[@type="application/ld+json"]'
STYLE_CDN = 'https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css'
UPDATED_DATA = File.join File.expand_path('data', __dir__), 'json-ld-updated.html'

raise 'Generate framed tree first. Execute "generate-framed-doc.rb" script' unless File.exist?(FRAMED_DOC)

# Get the root entity and revert the order of the lessons
framed_doc = JSON.parse File.read(FRAMED_DOC)
main_entity = framed_doc['@graph'].first['mainEntity']
main_entity['hasPart'].reverse!

# Extract data from the source HTML
source = Nokogiri::HTML.parse File.read(SOURCE_DATA)
root_script_node = source.at_xpath("//body/#{SCRIPT_SELECTOR}")
raise 'No MainEntity script tag exists' if root_script_node.nil?

# Original node of the main entity
main_entity_id = main_entity['id'].tr('#', '')
source_main_entity_node = source.at_xpath(%(*//*[@id="#{main_entity_id}"]))
source_main_entity_script = source_main_entity_node.at_xpath(SCRIPT_SELECTOR)

# Build the new HTML from the updated graph
doc = Nokogiri::HTML::Document.parse '<!doctype html><html lang="en"></html>'
doc.root.add_child doc.create_element('link', href: STYLE_CDN, rel: 'stylesheet')
doc.root.add_child root_script_node

# Add new main entity node with its script tag containing JSON+LD structure
main_entity_node = doc.create_element 'div', class: 'container', id: main_entity_id
doc.root.add_child main_entity_node
main_entity_node.add_child source_main_entity_script

# Iterate over all parts of the main entity
main_entity['hasPart'].each do |lesson|
  lesson_id = lesson['id'].tr('#', '')

  # Look for the source lesson node
  source_lesson_node = source_main_entity_node.at_xpath(%(//*[@id="#{lesson_id}"]))
  source_lesson_script = source_lesson_node.at_xpath(SCRIPT_SELECTOR)

  # Create new lesson node with its script tag containing JSON+LD structure
  new_lesson_node = doc.create_element 'div', class: 'row', id: lesson_id
  new_lesson_node.add_child source_lesson_script
  new_lesson_node.add_child doc.create_element('h2', "Lesson: #{lesson['name']}")

  # Iterate over lesson content
  activities = lesson['hasPart'].is_a?(Array) ? lesson['hasPart'] : [lesson['hasPart']]
  activities.each do |activity|
    activity_id = activity['id'].tr('#', '')
    source_activity_node = source_lesson_node.at_xpath(%(//*[@id="#{activity_id}"]))
    source_activity_script = source_activity_node.at_xpath(SCRIPT_SELECTOR)

    new_activity_node = doc.create_element 'div', id: activity_id
    new_activity_node.add_child source_activity_script

    # Populate activity materials
    activity['ocx:material'].each do |material|
      material_id = material['id'].tr('#', '')
      material_node = source_activity_node.at_xpath(%(//*[@id="#{material_id}"]))
      raise "Cannot find material with ID=#{material_id}" if material_node.nil?

      new_material_node = doc.create_element 'div', id: material_id
      new_material_node.add_child doc.create_element('h4', material['ocx:partType'])
      new_material_node.add_child doc.create_element('p', material_node.inner_text)

      new_activity_node.add_child new_material_node
    end

    new_lesson_node.add_child new_activity_node
  end

  main_entity_node.add_child new_lesson_node
end

# Write update data
File.open(UPDATED_DATA, 'wb') { |f| f.write doc.to_html }
