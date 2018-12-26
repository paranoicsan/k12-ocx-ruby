#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require

require 'environment'

UPDATED_DATA = File.join File.expand_path('data', __dir__), 'json-ld-updated.html'

raise 'Generate framed tree first. Execute "generate-framed-doc.rb" script' unless File.exist?(FRAMED_DOC)

framed_doc = JSON.load File.read(FRAMED_DOC)

source_doc = Nokogiri::HTML.parse File.read(SOURCE_DATA)
updared_doc = Nokogiri::HTML.parse
# Write update data
File.open(UPDATED_DATA, 'wb') { |f| f.write html.to_html }
