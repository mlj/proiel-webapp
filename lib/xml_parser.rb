#--
#
# Copyright 2009 Marius L. Jøhndal
#
# The program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# The program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the program. If not, see <http://www.gnu.org/licenses/>.
#
#++

class XMLParser
  include Singleton

  attr_reader :errors

  def initialize
    # Prevent errors from going to STDERR
    @errors = []
    XML::Error.set_handler do |error|
      @errors << error
    end
  end

  # Parses XML and returns a LibXML parse tree or +nil+ if an error
  # occurred. If an error occurred, error messages are available in
  # +errors+.
  def parse(data)
    @errors = []

    case data
    when String
      @parser = XML::Parser.string(data)
    else
      raise ArgumentError, 'invalid data type'
    end

    begin
      @parser.parse
    rescue
      nil
    end
  end

  private

  # Transforms XML and returns a LibXML parse tree or +nil+ if an error
  # occurred. If an error occurred, error messages are available in
  # +errors+. +parameters+ may be a hash of XSL parameters, which
  # should be strings but not escaped in quotes.
  def transform(data, xsl, parameters = {})
    xml = XMLParser.instance.parse(data)
    return nil unless xml

    xsl_parameters = parameters.inject({}) { |p, k, v| p[k] = "'#{v}'"; p }
    xsl.apply(xml, xsl_parameters)
  end

  public

  # Transforms XML and returns a string containing the resulting XML
  # or +nil+ if an error occurred. If an error occurred, error
  # messages are available in +errors+. +parameters+ may be a hash of
  # XSL parameters, which should be strings but not escaped in quotes.
  def transform_s(data, xsl, parameters = {})
    xml = transform(data, xsl, parameters)
    return nil unless xml

    s = xml.to_s

    # FIXME: libxslt-ruby bug #21615: XML decl. shows up in the output
    # even when omit-xml-declaration is set
    s.gsub!(/<\?xml version="1\.0" encoding="UTF-8"\?>\s+/, '')

    # FIXME: Why is there an additional CR at the end of the string?
    s.chomp!

    s
  end
end
