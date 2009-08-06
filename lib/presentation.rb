#--
#
# Copyright 2009 University of Oslo
# Copyright 2009 Marius L. Jøhndal
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

module Presentation
  # Returns the presentation level as verbatim UTF-8 HTML, i.e.
  # without converting the data to proper presentation HTML.
  #
  # === Options
  #
  # <tt>:coloured</tt> -- If true, will colour the output.
  def presentation_as_prettyprinted_code(options = {})
    unless options[:coloured]
      presentation.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    else
      presentation.gsub(/&([^;]+);/, '<font color="blue">&\1;</font>').gsub(/<([^>]+)>/, '<font color="blue">&lt;\1&gt;</font>')
    end
  end

  # Returns the presentation level as UTF-8 HTML.
  #
  # === Options
  #
  # <tt>:section_numbers</tt> -- If true, output will include section
  # numbers.
  #
  # <tt>:length_limit</tt> -- If set, will limit the length of
  # the formatted sentence to the given number of words and append an
  # ellipsis if the sentence exceeds that limit. If a negative number
  # is given, the ellipis is prepended to the sentence. The conversion
  # will also use a less rich form of HTML.
  def presentation_as_html(options = {})
    xsl_params = {
      :language_code => "'#{language.iso_code.to_s}'",
      :default_language_code => "'en'"
    }
    xsl_params[:sectionNumbers] = "'1'" if options[:section_numbers]

    presentation_as(APPLICATION_CONFIG.presentation_as_html_stylesheet, xsl_params)
  end

  private

  def presentation_as(stylesheet_method, xsl_params = {})
    parser = XML::Parser.string('<presentation>' + presentation + '</presentation>')

    begin
      xml = parser.parse
    rescue LibXML::XML::Parser::ParseError => p
      raise "Invalid presentation string for sentence #{id}: #{p}"
    end

    s = stylesheet_method.apply(xml, xsl_params).to_s

    # FIXME: libxslt-ruby bug #21615: XML decl. shows up in the output
    # even when omit-xml-declaration is set
    s.gsub!(/<\?xml version="1\.0" encoding="UTF-8"\?>\s+/, '')

    # FIXME: Why is there an additional CR at the end of the string?
    s.chomp!

    s
  end
end
