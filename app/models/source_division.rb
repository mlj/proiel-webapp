#--
#
# Copyright 2007, 2008, 2009 University of Oslo
# Copyright 2007, 2008, 2009 Marius L. Jøhndal
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

  # Returns the parent object for the source division, which will be its
  # source.
  def parent
    source
  end

  # Returns the completion state of the source division.
  def completion
    if sentences.exists?(["reviewed_by IS NULL and annotated_by IS NULL"])
      :unannotated
    elsif sentences.exists?(["reviewed_by IS NULL"])
      :annotated
    else
      :reviewed
    end
  end

  protected

  # Returns the reference-format for this source division.
  def reference_format
    source.reference_format[:source_division] || ""
  end

  # Returns the source title for this source division.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the title.
  def source_title(options = {})
    options[:abbreviated] ? source.abbreviation : source.title
  end

  public

  # Returns a citation-form reference for this source division.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    reference_fields.merge({ :title => source_title }).inject(reference_format) { |s, f| s.gsub("##{f.first}#", f.last) }
  end

  # Re-indexes the references.
  def reindex!
    SourceDivision.transaction { sentences.find_each(&:reindex!) }
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

  serialize :reference_fields

  # Sets the reference fields. Also updates fields in the source
  # division.
  def reference_fields=(x)
    write_attribute(:reference_fields, x.slice(*source.tracked_references["source_division"]))
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['title LIKE ?', "%#{query}%"] unless query.blank?

    paginate options
  end
end
