#--
#
# Copyright 2007, 2008 University of Oslo
# Copyright 2007, 2008 Marius L. Jøhndal
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

  # Returns true if there is a previous source division in a source.
  def has_previous?
    source.source_divisions.exists?(["position < ?", position])
  end

  # Returns true if there is a next source division in a source.
  def has_next?
    source.source_divisions.exists?(["position > ?", position])
  end

  # Returns a citation-form reference for this source division.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    [source.citation(options), options[:abbreviated] ? abbreviated_title : title] * ' '
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

  # Returns the reference field indentified by +key+ from the the
  # +fields+ attribute.
  def field(key)
    case key
    when :book
      fields.match(/book=([0-9A-Z]+)/)[1]
    when :chapter
      fields.match(/chapter=(\d+|Incipit|Explicit)/)[1]
    else
      raise ArgumentError, 'invalid key'
    end
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['title LIKE ?', "%#{query}%"] unless query.blank?

    paginate options
  end
end
