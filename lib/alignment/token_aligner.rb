#!/usr/bin/env ruby
#--
#
# token_aligner.rb - Token alignment within Bible verses
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


unless __FILE__ == $0
  require 'alignment/aligned_unit'
  require 'alignment/collocations'
end

ORIG_SOURCE = 1
LIMIT = 10000000

class TokenAligner
  def initialize(dictionary, format, sds, out = STDOUT)
    @out = File.open(out, "w") unless out == STDOUT
    @out = STDOUT if out == STDOUT
    @format = format.to_sym
    raise "Unknown format" unless [:csv, :human, :db].include?(@format)
    @sds = sds
    @d = dictionary
  end

  def execute
    @sds.each do |sd|

      #Find the aligned sd if it exists
      original_sd = sd.aligned_source_division

      unless original_sd
        # fall back to title identity
        original_sd = SourceDivision.find(:first, :conditions => ["title = ? and source_id = ?", sd.title, ORIG_SOURCE])
      end

      if original_sd
        ttokens_by_verse = {}
        Token.find(:all, :conditions => ["sentences.source_division_id = ? AND lemma_id IS NOT NULL", sd.id], :include => :sentence).each do |t|
          v, l = t.reference_fields["verse"]
          ttokens_by_verse[v] ||= []
          ttokens_by_verse[v] << t
        end
        unless ttokens_by_verse.empty?
          otokens_by_verse = {}
          Token.find(:all, :conditions => ["sentences.source_division_id = ? AND lemma_id IS NOT NULL", original_sd.id], :include => :sentence).each do |t|
            v, l = t.reference_fields["verse"]
            otokens_by_verse[v] ||= []
            otokens_by_verse[v] << t
          end
          (ttokens_by_verse.keys & otokens_by_verse.keys).sort.each do |v|
            STDERR.write("Processing verse #{v} of #{sd.title}...\n")
            reference = "#{sd.title}:#{v}"
            a = AlignedUnit.new(otokens_by_verse[v], ttokens_by_verse[v], @d, reference)
            #process options
            @out.write(a.to_csv) if @format == :csv
            @out.write(a.to_s) if @format == :human
            a.save! if @format == :db
          end
        end
      end
    end
    @out.close unless @out == STDOUT
  end
end


if __FILE__ == $0
  require '../../config/environment'
  require 'alignment/aligned_unit'
  require 'alignment/collocations'
  require 'ruby-prof'
  RubyProf.start

  ta = TokenAligner.new(Lingua::Collocations.new(ARGV[0]), :human, [SourceDivision.find(621)])
  ta.execute
  result = RubyProf.stop
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT, 0)
end

