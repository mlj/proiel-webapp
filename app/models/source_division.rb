#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
require 'differ'

class SourceDivision < ActiveRecord::Base
  belongs_to :source
  has_many :sentences, :order => 'sentence_number ASC'
  has_many :tokens, :through => :sentences, :order => 'sentences.sentence_number ASC, token_number ASC'
  belongs_to :aligned_source_division, :class_name => "SourceDivision"

  # Returns the previous source division in a source.
  def previous
    source.source_divisions.find(:first, :conditions =>  ["position < ?", position], :order => "position DESC")
  end

  # Returns the next source division in a source.
  def next
    source.source_divisions.find(:first, :conditions =>  ["position > ?", position], :order => "position ASC")
  end

  include Ordering

  def ordering_attribute
    :position
  end

  def ordering_collection
    source.source_divisions
  end

  # Returns the parent object for the source division, which will be its
  # source.
  def parent
    source
  end

  # Returns the completion state of the source division.
  def completion
    if sentences.exists?(["reviewed_at IS NULL and annotated_at IS NULL"])
      :unannotated
    elsif sentences.exists?(["reviewed_at IS NULL"])
      :annotated
    else
      :reviewed
    end
  end

  SD_CITATION_PREFIX_DIVIDERS = /([\s\.]+)/u

  # Returns a citation for the source division.
  def citation
    [source.citation_part,
      citation_make_range(sentences.first.tokens.first.citation_part,
                          sentences.last.tokens.last.citation_part)].join(' ')
  end

  # Returns sentence alignments for the source division.
  #
  # ==== Options
  # <tt>:automatic</tt> -- If true, will automatically align sentences
  # whose sentence alignment has not been set.
  def sentence_alignments(options = {})
    if aligned_source_division
      base_sentences = sentences
      aligned_sentences = aligned_source_division.sentences

      align_sentences(aligned_sentences, base_sentences, options[:automatic])
    else
      []
    end
  end

  # Returns the language for the source division. This is a
  # convenience method for +source_division.source.language+.
  def language
    source.language
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= query.inject([nil,[]]) do |m,v|
      [[m.first, (case v[0]
                 when :source_id
                   'source_id = ?'
                 when :title
                   'title LIKE ?'
                 else
                   raise "Unknown key #{v[0]}"
                  end)].compact.join(" AND "),
       m.last + [(v[1].to_i.to_s == v[1] ? v[1].to_i : "%#{v[1]}%" )]
      ]
    end.flatten unless query.empty?

    paginate options
  end

  public

  # Returns a collection of source divisions that are candidates for
  # alignment with this source division.
  def alignment_candidates
    SourceDivision.find(:all, :conditions => ["source_id != ?", self.source.id])
  end
end
