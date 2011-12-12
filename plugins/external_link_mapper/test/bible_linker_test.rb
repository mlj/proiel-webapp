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

require 'test/unit'
require File.join(File.dirname(__FILE__), '..', 'bible_linker')

class BibleLinkerTest < Test::Unit::TestCase
  def test_loading
    BiblosExternalLinkMapper.instance
  end

  def test_applies
    assert BiblosExternalLinkMapper.instance.applies?("GNT MATT 1.1")
  end

  def test_mapping_long
    assert_equal "http://biblos.com/matthew/1-1.htm", BiblosExternalLinkMapper.instance.to_url("GNT MATT 1.1")
  end
end

class BibelenNOReferenceTest < Test::Unit::TestCase
  def test_loading
    BibelenNOExternalLinkMapper.instance
  end

  def test_applies
    assert BibelenNOExternalLinkMapper.instance.applies?("GNT MATT 1.1")
  end

  def test_mapping
    assert_equal "http://www.bibel.no/nb-NO/sitecore/content/Home/Hovedmeny/Nettbibelen/Bibeltekstene.aspx?book=MAT&chapter=1", BibelenNOExternalLinkMapper.instance.to_url("GNT MATT 1.1")
  end
end
