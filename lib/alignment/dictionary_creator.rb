#!/usr/bin/env ruby
#
# dictionary_creator.rb - creation of correspondences dictionaries
#
# Copyright 2009 University of Oslo
# Copyright 2009 Dag Haug
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

require 'alignment/collocations'

class DictionaryCreator
  ORIG_SOURCE = 1

  def initialize(source, format, file, method)
    @source = Source.find(source)
    raise ArgumentError, "invalid source" unless @source
    @d = Lingua::Collocations.new(nil, true, method)
    @format = format
    @file = File.open(file, "w")
  end

  def execute
    @source.source_divisions.each do |sd|
      chunks = []
      # Find the aligned source division.
      original_sd = sd.aligned_source_division

      unless original_sd
        # Fall back to title identity
        original_sd = SourceDivision.find(:first, :conditions => ["title = ? and source_id = ?", sd.title, ORIG_SOURCE])
      end

      if original_sd
        ttokens_by_verse = {}
        Token.find(:all, :conditions => ["sentences.source_division_id = ? AND lemma_id IS NOT NULL", sd.id], :include => :sentence).each do |t|
          v, l = t.reference_fields["verse"]
          ttokens_by_verse[v] ||= []
          ttokens_by_verse[v] << t.lemma_id
        end

        otokens_by_verse = {}
        Token.find(:all, :conditions => ["sentences.source_division_id = ? AND lemma_id IS NOT NULL", original_sd.id], :include => :sentence).each do |t|
          v, l = t.reference_fields["verse"]
          otokens_by_verse[v] ||= []
          otokens_by_verse[v] << t.lemma_id
        end

        # Only do this for verses in both collections.
        (ttokens_by_verse.keys & otokens_by_verse.keys).sort.each do |v|
          tverselemmata = ttokens_by_verse[v]
          overselemmata = otokens_by_verse[v]
          chunks << [tverselemmata, overselemmata]
        end
        STDERR.puts("Sending verses from #{sd.title}")
        @d.update(chunks)
      end
    end
    @d.make
    if @format == :human
      @d.to_csv(30, lambda{ |x| Lemma.find(x).export_form}, @file)
    else
      @d.to_csv(30, nil, @file)
    end
  end
end
