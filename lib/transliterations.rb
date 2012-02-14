#!/usr/bin/env ruby
#
# transliterations.rb - Transliteration services
#
# Written by Marius L. Jøhndal <mariuslj at ifi.uio.no>, 2008
#
require 'singleton'
require 'yaml'
require 'unicode'
require 'sfst'

class TransliteratorFactory < Hash
  include Singleton

  private

  CONFIGURATION_FILE = File.join(File.dirname(__FILE__), 'transliterations.yml')
  MACHINE_DIRECTORY = File.join(File.dirname(__FILE__), 'transliterations')

  def initialize
    config = YAML.load_file(CONFIGURATION_FILE)
    config.each_pair do |identifier, c|
      self[identifier] = c
      self[identifier][:object] = nil
      self[identifier][:machine] = File.join(MACHINE_DIRECTORY, self[identifier][:machine])
    end
  end

  public

  def self.get_transliterator(identifier)
    instance.get_transliterator(identifier)
  end

  def get_transliterator(identifier)
    identifier = identifier.to_s

    if self[identifier]
      self[identifier][:object] ||= Transliterator.new(identifier, self[identifier])
    else
      raise ArgumentError, "unknown transliterator #{identifier}"
    end
  end
end

class Transliterator
  attr_reader :identifier
  attr_reader :human_readable_name
  attr_reader :supported_scripts
  attr_reader :supported_languages

  def initialize(identifier, options = {})
    @identifier = identifier
    @machine = SFST::RegularTransducer.new(options[:machine])
    @human_readable_name = options[:human_readable_name]
    @supported_scripts = options[:scripts]
    @supported_languages = options[:languages]
    @decomposed = options[:decomposed] || false
  end

  def generate_string(string)
    @machine.generate(Unicode.normalize_D(string))
  end

  def transliterate_string(string, options = {})
    s = @machine.analyse(string).map do |t|
      t.force_encoding("UTF-8") # FIXME: deal with broken ruby-sfst
    end
    r = @decomposed ? s.map { |c| Unicode.normalize_C(c) } : s
    r
  end
end
