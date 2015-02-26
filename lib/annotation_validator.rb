# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

module Proiel
  class TokenAnnotationValidator < ::ActiveModel::Validator
    def validate(record)
      if record.is_empty? and !record.form.nil?
        record.errors[:base] << "Empty tokens must have NULL form"
      end

      if !record.is_empty? and record.form.nil?
        record.errors[:base] << "Non-empty tokens cannot have NULL form"
      end

      if record.lemma_id.blank?
        record.errors.add(:lemma, "must be present") if record.morphology_tag
      else
        record.errors.add(:lemma, "not allowed") unless record.is_visible?
      end

      if record.morphology_tag.blank?
        record.errors.add(:morphology, "must be present") unless record.lemma_id.blank?
      else
        record.errors.add(:morphology, "not allowed") unless record.is_visible?
      end

      if record.relation_tag.blank?
        record.errors.add(:relation, "must be present when head token is set") unless record.head_id.blank?
      end

      unless record.source_lemma.blank?
        record.errors.add(:source_lemma, "not allowed") unless record.is_visible?
      end

      unless record.source_morphology_tag.blank?
        record.errors.add(:source_morphology, "not allowed") unless record.is_visible?
      end

      if record.is_reviewed?
        if record.is_visible?
          record.errors.add(:lemma, "must be present on a reviewed token") if record.lemma_id.blank?
          record.errors.add(:morphology, "must be present on a reviewed token") if record.morphology_tag.blank?
        end

        record.errors.add(:relation, "must be present on a reviewed token") if record.relation_tag.blank?
      end

      if m = record.morph_features
        record.errors[:base] << "morph-features #{m.to_s} are invalid" unless m.valid?
      end
    end
  end

  class SentenceAnnotationValidator < ::ActiveModel::Validator
    def validate(record)
      # FIXME? This breaks creation of new sentences
      # # Constraint: sentence must have at least one token.
      # if tokens.length < 1
      #   errors.add_to_base("Sentence must have at least one token")
      # end

      # Pairwise attributes: reviewed_by && reviewed_at
      # Pairwise attributes: annotated_by && annotated_at

      #   is_reviewed? <=> reviewed_by    sentence is reviewed
      #   is_annotated? <=> annotated_by  sentence is annotated
      #   has_dependency_annotation       sentence is dependency annotated

      # Invariant: sentence is reviewed => sentence is annotated
      if record.is_reviewed? and not record.is_annotated?
        record.errors[:base] << "Reviewed sentence must be annotated"
      end

      # Invariant: sentence is annotated => sentence is dependency annotated
      if record.is_annotated? and not record.has_dependency_annotation?
        record.errors[:base] << "Annotated sentence must have dependency annotation"
      end

      # Invariant: sentence is dependency annotated <=>
      # all dependency tokens have non-nil relation attributes <=> there exists one
      # dependency token with non-nil relation.
      relation_tags = record.tokens.takes_syntax.pluck(:relation_tag)
      if relation_tags.any? and !relation_tags.all?
        errors[:base] << "Dependency annotation must be complete"
      end

      record.tokens.takes_syntax.each do |t|
        t.slash_out_edges.each do |se|
          add_dependency_error("Unconnected slash edge", [t]) if se.slashee.nil?
          add_dependency_error("Unlabeled slash edge", [t]) if se.relation.nil?
        end
      end

      # Check each token for validity (this could of course also be done with validates_associated),
      # but that leads to confusing error messages for users.
      record.tokens.each do |t|
        unless t.valid?
          t.errors.to_a.each { |msg| add_dependency_error(record, msg, [t]) }
        end
      end

      # Invariant: sentence is dependency annotated => dependency graph is valid
      if record.is_annotated? and record.has_dependency_annotation?
        begin
          record.dependency_graph.valid?(lambda { |token_ids, msg| add_dependency_error(record, msg, Token.find(token_ids)) })
        rescue
          record.errors[:base] << "An inconsistency in the dependency graph prevented validation"
        end
      end
    end

    def add_dependency_error(record, msg, tokens)
      ids = tokens.map(&:token_number)
      record.errors[:base] << "Token #{'number'.pluralize(ids)} #{ids.to_sentence}: #{msg}"
    end
  end
end
