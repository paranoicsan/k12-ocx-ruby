#!/usr/bin/env ruby
# frozen_string_literal: true

# Execute the script to build the HTML page with graph
# represented as HTML

require_relative 'environment-rdfa'

GRAPH_FILE = 'graph-rdfa.html'

graph = RDF::Repository.new.from_html File.read(SOURCE_DATA)
RDF::RDFa::Writer.open(GRAPH_FILE) { |writer| writer << graph }
