#--
#
# metadata.rb - TEI metadata functions for PROIEL sources
#
# Copyright 2008, 2009 University of Oslo
# Copyright 2008, 2009 Marius L. Jøhndal
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

  TEI_HEADER_HTML_STYLESHEET = File.join(Rails.root, 'lib', 'teiheader.xsl')

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

      parser = XML::Parser.string(header)
      begin
        @header = parser.parse
      rescue LibXML::XML::Parser::ParseError => p
        @error_message = p
        @valid = false
      end
    end

    stylesheet_doc = XML::Document.file(TEI_HEADER_HTML_STYLESHEET)
    @stylesheet = XSLT::Stylesheet.new(stylesheet_doc)
  end

  # Checks if the metadata header is valid.
  def valid?
    @valid
  end

  def to_s
    @header ? @header.to_s : nil
  end

  # Writes the metadata header using an XML builder. The function takes care
  # of setting up the necessary namespace.
  def write(builder)
    builder.teiHeader(:xmlns => "http://www.tei-c.org/ns/1.0") { write_header(builder) }
  end

  # Coverts the header to TEI using a stylesheet.
  def to_html
    if @header
      xml_doc = XML::Document.new
      xml_doc.root = (XML::Node.new('TEI.2') << @header.root.copy(true))
      @stylesheet.apply(xml_doc)
    else
      nil
    end
  end

  private

  def write_header(builder)
    @header and @header.find("/teiHeader/*").each { |e| builder << e.to_s }
  end
end
