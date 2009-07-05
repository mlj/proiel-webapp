#!/usr/bin/env ruby
#
# source.rb - PROIEL source file manipulation functions
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'unicode'
require 'open-uri'
require 'hpricot'
require 'builder'

module PROIEL
  class Dictionary
    def initialize(uri)
      doc = Hpricot.XML(open(uri))

      t = doc.at("dictionary")
      @id = t.attributes["id"]
      @language = t.attributes["lang"].to_sym

      @entries = Hash[*(doc/:entries/:entry).collect { |b| [b.attributes["lemma"], b] }.flatten]
    end

    # Reads entries from a source.
    def read_lemmata(options = {})
      @entries.values.each do |entry|
        references = (entry/:references/:reference).collect(&:attributes)
        attributes = Hash[*entry.attributes.collect { |k, v| [k.gsub('-', '_').to_sym, v] }.flatten]
        
        yield attributes.merge({ :language => @language }), references
      end
    end
  end
end
