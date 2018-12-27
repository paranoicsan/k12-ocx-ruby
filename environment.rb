# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require

FRAMED_DOC = 'result.json'
SOURCE_DATA = File.join File.expand_path('data', __dir__), 'json-ld.html'
