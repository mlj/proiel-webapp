#!/usr/bin/env ruby
#
# tagsets.rb - PROIEL tag sets
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'lingua/tagset'
require 'yaml'

module PROIEL
  DATADIR = File.expand_path(File.dirname(__FILE__))

  MORPHOLOGY = Lingua::PositionalTagSet.new(File.join(DATADIR, 'morphology.xml')).freeze

  INFERENCES = YAML::load_file(File.join(DATADIR, 'inferences.yml')).freeze
end
