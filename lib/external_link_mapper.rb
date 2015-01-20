# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Marius L. Jøhndal
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

require 'singleton'
require 'yaml'

# External linkers are plugins that map text citations to external URLs.
# These external URLs will be linked to in the relevant annotation views in
# the web application.
class ExternalLinkMapper
  include Singleton
end

class BibleExternalLinkMapper < ExternalLinkMapper
  def initialize
    # FIXME
    sources = ['GNT', 'Vulg.', 'Marianus', 'The Gothic Bible', 'ARMNT', 'Supr.', 'Zogr.']
    @source_regexp = Regexp.union(sources)
  end

  def split_citation(citation)
    if citation[/^(#{@source_regexp})\s+([^\s]+)\s+(.*)$/]
      [$1, $2, $3]
    else
      [nil, nil, nil]
    end
  end

  def to_url(citation)
    source, book, rest = split_citation(citation)

    if source and @books.include?(book)
      File.join(@base_url, local_name(book, rest))
    else
      nil
    end
  end
end

class BiblosExternalLinkMapper < BibleExternalLinkMapper
  def initialize
    super

    @base_url = 'http://biblehub.com'

    @books = YAML::load <<EOYAML
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
EOYAML
  end

  def site_name
    'Biblehub'
  end

  def local_name(book, rest)
    case rest
    when /^(\d+)\.(\d+)$/
      "#{@books[book]}/#{$1}-#{$2}.htm"
    else
      "#{@books[book]}/"
    end
  end
end
