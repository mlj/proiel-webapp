# encoding: UTF-8
#--
#
# Copyright 2013 University of Oslo
# Copyright 2013 Marius L. Jøhndal
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

class TextImporter < SourceImporter
  protected

  def parse(file)
    sr = Source.new
    sd = nil
    sd_position = 0
    s_number = nil

    file.each_line do |l|
      l.chomp!

      case l
      when /^\s*$/
        # ignore blank lines
      when /^%/
        # source header information
        field, value = l.sub(/^%/, '').split(/=/, 2).map(&:strip)

        case field
        when 'export_time'
          # ignore this
        when 'title', 'author', 'edition', 'citation_part', 'language'
          sr.send("#{field}=", value)
        else
          raise SourceImporterParseError, "invalid header field #{field}"
        end
      when /^#/
        # new source division
        title = l.sub(/^#/, '').strip

        if sr.new_record?
          puts "Creating new source #{sr.title}...".green
          sr.save!
          puts "  Created with ID #{sr.id}"
        end

        puts "  Importing source division #{title}...".green
        sd = sr.source_divisions.create! :title => title, :position => sd_position
        sd_position += 1
        s_number = 0
      else
        # untokenized line with citation
        citation_part, sentence_text = l.split(/\t/, 2)
        raise SourceImporterParseError, "invalid sentence line #{l}" if sentence_text.nil?

        s = sd.sentences.create! :status_tag => 'unannotated', :sentence_number => s_number
        s_number += 1

        sentence_text.scan(/([^\w]+)?(\w+)([^\w]+)/).each_with_index do |(before, form, after), i|
          s.tokens.create! :citation_part => citation_part,
            :presentation_before => before,
            :form => form,
            :presentation_after => after,
            :token_number => i
        end
      end
    end
  end
end
