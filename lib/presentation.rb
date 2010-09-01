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

  UNICODE_HORIZONTAL_ELLIPSIS = Unicode::U2026

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
  # is given, the ellipsis is prepended to the sentence. The conversion
  # will also use a less rich form of HTML.
  def presentation_as_html(options = {})
    xsl_params = {
      :language_code => "#{language.tag.to_s}",
      :default_language_code => "en"
    }
    xsl_params[:sectionNumbers] = "1" if options[:section_numbers]

    markup = if limit = options[:length_limit]
      s = presentation_as(APPLICATION_CONFIG.presentation_as_minimal_html_stylesheet, xsl_params)

      # We assume here that all strings have an outer span with a
      # language attribute
      seq = Hpricot.XML(s).search("//span/.").map do |t|
        if t.class == Hpricot::Text
          t.to_s.split(/\s+/)
        else
          t.to_s
        end
      end.flatten.reject(&:blank?)

      if limit and seq.length > limit
        if limit < 0
          UNICODE_HORIZONTAL_ELLIPSIS + seq.last(-limit).join(' ')
        else
          seq.first(limit).join(' ') + UNICODE_HORIZONTAL_ELLIPSIS
        end
      else
        s
      end
    else
      presentation_as(APPLICATION_CONFIG.presentation_as_html_stylesheet, xsl_params)
    end

    "<span class='formatted-text'>#{markup}</span>"
  end

  def presentation_as_editable_html
    s = presentation_as(APPLICATION_CONFIG.presentation_as_editable_html_stylesheet)

    # The xslt processor ignores all instructions and inserts
    # non-sense "\n" characters all over the place. That seriously
    # messes with out code. Try to mend it by removing all "\n"
    # characters.
    s.gsub!("\n", '')

    s
  end

  # Returns the presentation level as UTF-8 text.
  def presentation_as_text
    presentation_as(APPLICATION_CONFIG.presentation_as_text_stylesheet)
  end

  # Returns the presentation level as a sequence of references. The
  # references are returned as a hash with reference units as keys and
  # reference values as values.
  def presentation_as_reference
    refs = presentation_as(APPLICATION_CONFIG.presentation_as_reference_stylesheet)

    refs.gsub(/\s+/, ' ').split(/\s*,\s*/).reject { |t| t.blank? }.inject({}) do |fields, field|
      r, v = field.split('=')

      case fields[r]
      when NilClass
        fields[r] = v
      when Array
        fields[r] << v
        fields[r].sort!
        fields[r].uniq!
      else
        fields[r] = [fields[r], v].sort.uniq
      end

      fields
    end
  end

  # Returns the presentation string as an array of tokens. This
  # presupposes that the presentation string already contains
  # tokenization markup.
  def presentation_as_tokens
    presentation_as(APPLICATION_CONFIG.presentation_as_tokens_stylesheet).split('#').map { |form| form.sub(/^-/, '') }
  end

  # Returns true if the presentation XML is well-formed.
  def presentation_well_formed?
    x = XMLParser.instance.parse('<presentation>' + presentation + '</presentation>')
    !x.nil?
  end

  protected

  def presentation_as(xsl, parameters = {})
    s = XMLParser.instance.transform_s('<presentation>' + presentation + '</presentation>', xsl, parameters)
    raise "Invalid presentation string #{presentation} for sentence #{id}: #{XMLParser.instance.errors.join(', ')}" unless s

    s
  end
end
