#--
#
# source.rb - PROIEL source file manipulation functions
#
# Copyright 2008, 2009, 2010 University of Oslo
# Copyright 2008, 2009, 2010 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++
require 'unicode'
require 'open-uri'
require 'nokogiri'

module PROIEL
  class Dictionary
    def initialize(uri)
      doc = Nokogiri::XML(open(uri))

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
