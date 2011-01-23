#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
require 'yaml'
require 'singleton'

class ExternalLinkMapper
  attr_reader :name

  include Singleton

  # Returns an array of mapping objects that apply to a given citation.
  def self.get_mappings(citation)
    [BibelenNOExternalLinkMapper, BiblosExternalLinkMapper].select do |mapper|
      mapper.instance.applies?(citation)
    end.map(&:instance)
  end

  def initialize(identifier)
    datadir = File.expand_path(File.dirname(__FILE__))
    definition = YAML::load_file(File.join(datadir, File.basename(__FILE__).sub(/rb$/, 'yml')))
    raise "Cannot find definition for #{identifier}" unless definition.has_key?(identifier)
    @book_mapping = definition[identifier][:books]
    @base_url = definition[identifier][:url]
    @name = definition[identifier][:name]
  end
end

class BibleExternalLinkMapper < ExternalLinkMapper
  BIBLE_BOOKS = %w(2JOHN COL 2PET 2THESS MARK REV 1PET PHILEM 1THESS JOHN
                   JUDE HEB ROM ACTS JAS 2TIM 1TIM EPH GAL LUKE 3JOHN TIT
                   PHIL 2COR MATT 1JOHN 1COR)

  def applies?(citation)
    book, rest = citation.split(/\s+/, 2)

    BIBLE_BOOKS.include?(book)
  end
end

class BiblosExternalLinkMapper < BibleExternalLinkMapper
  def initialize
    super 'biblos'
  end

  def to_url(citation)
    raise ArgumentError, "citation not mappable" unless applies?(citation)

    book, rest = citation.split(/\s+/, 2)

    case rest
    when /^(\d+)\.(\d+)$/
      "#{@base_url}#{@book_mapping[book]}/#{$1}-#{$2}.htm"
    else
      "#{@base_url}#{@book_mapping[book]}/"
    end
  end
end

class BibelenNOExternalLinkMapper < BibleExternalLinkMapper
  def initialize
    super 'bibelen.no'
  end

  def to_url(citation)
    raise ArgumentError, "citation not mappable" unless applies?(citation)

    book, rest = citation.split(/\s+/, 2)

    case rest
    when /^(\d+)\.(\d+)$/
      "#{@base_url}chapter.aspx?book=#{@book_mapping[book]}&chapter=#{$1}"
    else
      "#{@base_url}chapter.aspx?book=#{@book_mapping[book]}"
    end
  end
end
