#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'environment-json-ld'

html = Nokogiri::HTML.parse File.read(SOURCE_DATA)
json = html.xpath(%(*//script[@type="application/ld+json"])).map { |x| JSON.parse x }

# Prepare the input:
# create single JSON object with 2 nodes:
# - @context
# - @graph
result = {
  '@context' => json.first['@context'],
  '@graph' => json.map { |x| x.delete '@context'; x } # rubocop:disable Style/Semicolon
}

# Build the frame
doc = JSON::LD::API.frame result, result

# Write resulting tree into the file
File.open(FRAMED_DOC, 'wb') { |f| f.write doc.to_json }
