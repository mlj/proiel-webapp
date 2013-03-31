# encoding: UTF-8
#--
#
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

class Metadata
  attr_reader :error_message

  HTML_STYLESHEET_FILE_NAME = Rails.root.join('lib', 'metadata.xsl')
  HTML_STYLESHEET = Nokogiri::XSLT(File.read(HTML_STYLESHEET_FILE_NAME))
  NAMESPACE = 'http://www.tei-c.org/ns/1.0'
  ROOT_PATH = '/TEI.2/teiHeader'

  # Creates a new instance from an XML fragment containing the header. The header
  # should be a TEI header and the top level element in the XML fragment must be
  # a +teiHeader+ element.
  def initialize(header)
    if header.blank?
      @error_message = 'Header is empty'
      @valid = false
    else
      @error_message = nil
      @valid = true

      @header = Nokogiri::XML(header)

      if @header.errors.empty?
        unless @header./(ROOT_PATH).length == 1
          @error_message = 'Header top element is invalid'
          @valid = false
          @header = nil
        end
      else
        @error_message = @header.errors.join(', ')
        @valid = false
      end
    end
  end

  # Checks if the metadata header is valid.
  def valid?
    @valid
  end

  def to_s
    @header ? @header.to_s : nil
  end

  # Coverts the header to TEI using a stylesheet.
  def to_html
    if @header
      HTML_STYLESHEET.transform(@header).to_s
    else
      nil
    end
  end

  # Returns the header on a format that is suitable for embedding within
  # other XML documents, e.g. in text exports. The top-level element is
  # +teiHeader+ and it contains the correct namespace attribute.
  def export_form
    if @header
      h = @header./(ROOT_PATH).first.dup
      h.default_namespace = NAMESPACE
      h.to_s
    end
  end
end
