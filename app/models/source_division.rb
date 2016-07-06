# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
# Copyright 2011 Dag Haug
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
  attr_accessible :source_id, :position, :title, :aligned_source_division_id, :presentation_before, :presentation_after,
    :created_at, :updated_at

  change_logging except: %i(cached_has_discourse_annotation cached_citation cached_status_tag)

  blankable_attributes :aligned_source_division_id, :presentation_after,
    :presentation_before, :title

  belongs_to :source
  has_many :sentences
  has_many :tokens, :through => :sentences
  belongs_to :aligned_source_division, :class_name => "SourceDivision"

  ordered_on :position, "source.source_divisions"

  citation_on

  delegate :citation_part, to: :source, prefix: :source

  def tokens_with_citation
    Token.
      where(sentence_id: sentences).
      includes(:sentence).
      order('sentences.sentence_number', 'tokens.token_number').
      with_citation
  end

  def cached_citation
    read_attribute(:cached_citation) || citation.tap { |x| update_attribute(:cached_citation, x) }
  end

  presentation_on

  # Returns the parent object for the source division, which will be its
  # source.
  def parent
    source
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

  # Language tag for the source division
  delegate :language_tag, :to => :source

  # Language for the source division
  delegate :language, :to => :source

  # Returns a collection of source divisions that are candidates for
  # alignment with this source division.
  def alignment_candidates
    SourceDivision.find(:all, :conditions => ["source_id != ?", self.source.id])
  end

  def visualize_semantic_relation(srt)
    result = nil
    errors = nil

    Open3.popen3("dot -Tsvg") do |dot, img, err|
      dot.write semantic_relation_dot(srt)
      dot.close
      result = img.read
      errors = err.read
    end

    raise VisualizationError, "graphviz exited: #{errors}" unless errors.blank?

    result
  end

  private

  def semantic_relation_heads(srt)
    tokens.select do |t|
     t.outgoing_semantic_relations.any? { |osa| osa.semantic_relation_type == srt} or t.incoming_semantic_relations.any? { |isa| isa.semantic_relation_type == srt }
    end.uniq
  end

  def semantic_relation_dot(srt)
    srh = semantic_relation_heads(srt)
    "digraph discourse {\n" +
     "\trankdir=TD;\n" +
      "\tnode [shape = ellipse];\n" +
      (srh.map do |head|
         l = "\t#{head.id} [label = " + '"' + head.label_semantic_relation_span(srt) + '"];' + "\n" +
           "\tH#{head.id} [label = " + '"", shape=none];' + "\n" +
           "\t#{head.id} -> H#{head.id} [style=invis];"
         if head.outgoing_semantic_relations.empty? and head.find_semantic_relation_head(srt)
           l += "\n\t#{head.find_semantic_relation_head(srt).id} -> #{head.id} [label = " + '"CONTAINS", style=dashed];'
         end
         l += (head.outgoing_semantic_relations.map do |sr|
                 "\t#{sr.target.id} -> #{sr.controller.id} [ label = " + '"' + sr.semantic_relation_tag.tag + '"];'
                 end.join("\n"))
         l
       end.join("\n")) +
      "\n}"
  end

  public

  def has_discourse_annotation?
    sentences.first.tokens.any? do |t|
      t.has_relation_type?(SemanticRelationType.find_by_tag('Discourse'))
    end
  end

  def cached_has_discourse_annotation?
    v = read_attribute(:cached_has_discourse_annotation)

    if v.nil?
      v = has_discourse_annotation?
      update_attribute(:cached_has_discourse_annotation, v)
    end

    v
  end

  def aggregate_status
    if sentences.unannotated.exists?
      'unannotated'
    elsif sentences.unreviewed.exists?
      'annotated'
    else
      'reviewed'
    end
  end

  def cached_status_tag
    read_attribute(:cached_status_tag) || aggregate_status.tap { |x| update_attribute(:cached_status_tag, x) }
  end

  # Returns all contrast groups defined in the source division.
  def contrast_groups
    tokens.where('contrast_group IS NOT NULL').uniq.pluck(:contrast_group)
  end

  # Delete contrast group from source division.
  def delete_contrast_group!(contrast_number)
    contrast_number = contrast_number.to_i
    raise 'Invalid contrast number' unless contrast_number > 0

    tokens.where('contrast_group LIKE ?', "#{contrast_number}%").update_all :contrast_group => nil
  end
end
