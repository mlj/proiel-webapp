# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
# Copyright 2010, 2011, 2012 Dag Haug
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

# Exporter for the CoNLL shared task format.
# Note that this exporter does not support secondary edges.
class CoNLLExporter < SourceExporter
  protected

  def write_sentence!(file, s)
    id_to_number = s.tokens.pluck(:id).each_with_index.inject({}) do |m, (id, i)|
      m[id] = i + 1
      m
    end

    yield [file, id_to_number]

    file.puts
  end

  def write_token!(context, t)
    file, id_to_number = context

    if t.is_visible?
      hr = find_lexical_head_and_relation(id_to_number, t)

      file.puts([id_to_number[t.id],
                 t.form.gsub(' ', ''),
                 t.lemma.export_form.gsub(' ', ''),
                 t.lemma.part_of_speech_tag.first,
                 t.lemma.part_of_speech_tag,
                 t.morph_features.morphology_to_hash.map { |k, v| (v == '-' or (k == :inflection and v =='i') ) ? nil : "#{k.upcase[0..3]}#{v}" }.compact.join("|"),
                 hr.first,
                 hr.last,
                 "_",
                 "_"].join("\t"))
    end
  end

  private

  def find_lexical_head_and_relation(id_to_number, t, rel = '')
    if t.head.nil? or !t.head.is_empty?
      [t.head ? id_to_number[t.head_id] : 0, rel + t.relation.tag]
    else
      find_lexical_head_and_relation(id_to_number, t.head, rel + "#{t.relation.tag}(#{id_to_number[t.head_id]})")
    end
  end
end
