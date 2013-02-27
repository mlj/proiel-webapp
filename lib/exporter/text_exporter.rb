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

class TextExporter < SourceExporter
  protected

  def write_source!(file, s)
    file.puts "% #{Time.now}"
    file.puts "% #{s.title}"
    file.puts "% #{s.author}"
    file.puts "% #{s.edition}"
    file.puts "% #{s.citation_part}"
    file.puts "% #{s.language_tag}"

    yield file
  end

  def write_source_division!(file, sd)
    file.puts
    file.puts "# #{sd.title}"

    txt = Token.joins(:sentence).where(:sentences => { :source_division_id => sd.id }, :empty_token_sort => nil).order('sentence_number, token_number').pluck('concat(citation_part, "\t", ifnull(tokens.presentation_before, ""), tokens.form, ifnull(tokens.presentation_after, ""))')

    current_citation = nil

    txt = txt.map do |t|
      new_citation, t = t.split(/\t/)

      if current_citation != new_citation
        file.write("\n" + new_citation + "\t")
        current_citation = new_citation
      end

      file.write t
    end.join('')

    file.puts
  end
end
