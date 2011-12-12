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

require 'plugin.rb'
require 'yaml'

class BibleExternalLinkMapper < PROIEL::ExternalLinkMapper
  @@definition = YAML::load <<EOYAML
:sources:
  - GNT
  - Vulg.
  - Marianus
  - The Gothic Bible
  - ARMNT
  - Supr.
  - Zogr.
:biblos:
  :url: http://biblos.com/
  :books:
    2JOHN: 2_john
    COL: colossians
    2PET: 2_peter
    2THESS: 2_thessalonians
    MARK: mark
    REV: revelation
    1PET: 1_peter
    PHILEM: philemon
    1THESS: 1_thessalonians
    JOHN: john
    JUDE: jude
    HEB: hebrews
    ROM: romans
    ACTS: acts
    JAS: james
    2TIM: 2_timothy
    1TIM: 1_timothy
    EPH: ephesians
    GAL: galatians
    LUKE: luke
    3JOHN: 3_john
    TIT: titus
    PHIL: philippians
    2COR: 2_corinthians
    MATT: matthew
    1JOHN: 1_john
    1COR: 1_corinthians
:bibelen_no:
  :url: http://www.bibel.no/nb-NO/sitecore/content/Home/Hovedmeny/Nettbibelen/Bibeltekstene.aspx
  :books:
    MATT: MAT
    MARK: MRK
    LUKE: LUK
    JOHN: JHN
    ACTS: ACT
    ROM: ROM
    1COR: 1CO
    2COR: 2CO
    GAL: GAL
    EPH: EPH
    PHIL: PHP
    COL: COL
    1THESS: 1TH
    2THESS: 2TH
    1TIM: 1TI
    2TIM: 2TI
    TIT: TIT
    PHILEM: PHM
    HEB: HEB
    JAS: JAS
    1PET: 1PE
    2PET: 2PE
    1JOHN: 1JN
    2JOHN: 2JN
    3JOHN: 3JN
    JUDE: JUD
    REV: REV
EOYAML

  def initialize(identifier, name)
    super identifier, name

    raise "Cannot find definition for #{identifier}" unless @@definition.has_key?(identifier)
    @book_mapping = @@definition[identifier][:books]
    @base_url = @@definition[identifier][:url]
    @source_regexp = Regexp.union(@@definition[:sources])
  end

  def applies?(citation)
    source, book, rest = split_citation(citation)

    source and @@definition[@identifier][:books].include?(book)
  end

  protected

  def split_citation(citation)
    if citation[/^(#{@source_regexp})\s+([^\s]+)\s+(.*)$/]
      [$1, $2, $3]
    else
      [nil, nil, nil]
    end
  end
end

class BiblosExternalLinkMapper < BibleExternalLinkMapper
  def initialize
    super :biblos, 'Biblos'
  end

  def to_url(citation)
    raise ArgumentError, 'cannot map citation to link' unless applies?(citation)

    source, book, rest = split_citation(citation)

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
    super :bibelen_no, 'bibel.no'
  end

  def to_url(citation)
    raise ArgumentError, 'cannot map citation to link' unless applies?(citation)

    source, book, rest = split_citation(citation)

    case rest
    when /^(\d+)\.(\d+)$/
      "#{@base_url}?book=#{@book_mapping[book]}&chapter=#{$1}"
    else
      "#{@base_url}?book=#{@book_mapping[book]}"
    end
  end
end

PROIEL::register_plugin BiblosExternalLinkMapper
PROIEL::register_plugin BibelenNOExternalLinkMapper
