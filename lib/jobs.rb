#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2016 Marius L. Jøhndal
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
  module Jobs
    class DatabaseChecker < Job
      PERSISTED_MODELS = [
        DependencyAlignmentTerm,
        ImportSource,
        Inflection,
        Lemma,
        Note,
        SemanticAttribute,
        SemanticAttributeValue,
        SemanticRelation,
        SemanticRelationType,
        Sentence,
        SlashEdge,
        Source,
        SourceDivision,
        Token,
        User,
      ]

      def run_once!
        check_lemmata
        check_tokens
        check_sentences
        check_persisted_models
      end

      # TODO: move to job and keep this as an error
      def destroy_orphaned_lemmata!
        Lemma.joins(:tokens).where('lemmata.foreign_ids IS NULL AND tokens.id IS NULL').each do |o|
          warning { "Destroying orphaned lemma #{o.id}" }
          o.destroy
        end
      end

      private

      def warning(&block)
        STDERR.puts "#{self.class}: #{block.call}"
      end

      def error(&block)
        STDERR.puts "#{self.class}: #{block.call}"
      end

      def check_lemmata
        Lemma.joins(:tokens).where('lemmata.foreign_ids IS NULL AND tokens.id IS NULL').each do |o|
          error { "lemma #{lemma.id} is orphaned" }
        end

        duplicates = []

        Lemma.joins("left join lemmata as b on lemmata.lemma = b.lemma and lemmata.part_of_speech_tag = b.part_of_speech_tag and lemmata.language_tag = b.language_tag").where(:variant => nil).where("b.variant IS NOT NULL").each do |l|
          duplicates << "lemma #{l.lemma},#{l.part_of_speech_tag} in language #{l.language_tag} occurs both with and without variant numbers"
        end

        duplicates.sort!
        duplicates.uniq!

        duplicates.each do |msg|
          error { msg }
        end
      end

      def check_tokens
        Token.joins(:sentence).where("sentences.id IS NULL").each do |t|
          error { "token #{t.id} is orphaned" }
        end

        Token.where('token_number is NULL').each do |o|
          error { "token #{o.id} lacks token_number" }
        end

        empty_tokens = Token.where('empty_token_sort IS NOT NULL')
        non_empty_tokens = Token.where('empty_token_sort IS NULL')

        empty_tokens.where('form IS NOT NULL').each do |o|
          error { "token #{o.id} is empty but has non-NULL form" }
        end

        non_empty_tokens.where('form IS NULL').each do |o|
          error { "token #{o.id} is non-empty but has NULL form" }
        end

        empty_tokens.where('lemma_id IS NOT NULL').each do |o|
          error { "token #{o.id} is empty but has lemma_id" }
        end

        empty_tokens.where('morphology_tag IS NOT NULL').each do |o|
          error { "token #{o.id} is empty but has morphology_tag" }
        end

        empty_tokens.where('source_morphology_tag IS NOT NULL').each do |o|
          error { "token #{o.id} is empty but has source_morphology_tag" }
        end

        empty_tokens.where('source_lemma IS NOT NULL').each do |o|
          error { "token #{o.id} is empty but has source_lemma" }
        end

        Token.where('morphology_tag IS NOT NULL').where('lemma_id IS NULL').each do |o|
          error { "token #{o.id} has morphology but not lemma" }
        end

        Token.where('morphology_tag IS NULL').where('lemma_id IS NOT NULL').each do |o|
          error { "token #{o.id} has lemma but not morphology" }
        end

        Token.where('head_id IS NOT NULL and relation_tag IS NULL').each do |o|
          error { "token #{o.id} has head_id but no relation_tag" }
        end

        non_empty_tokens.joins(:sentence).where('sentences.status_tag = "reviewed"').where("lemma_id IS NULL").each do |o|
          error { "token #{o.id} is non-empty and reviewed but lemma_id is NULL" }
        end

        non_empty_tokens.joins(:sentence).where('sentences.status_tag = "reviewed"').where("morphology_tag IS NULL").each do |o|
          error { "token #{o.id} is non-empty and reviewed but morphology_tag is NULL" }
        end

        Token.joins(:sentence).where('sentences.status_tag = "reviewed"').where("relation_tag IS NULL").each do |o|
          error { "token #{o.id} is reviewed but relation_tag is NULL" }
        end

        Token.joins(:sentence, :lemma).where('sentences.status_tag = "reviewed"').where('morphology_tag IS NOT NULL').each do |o|
          unless MorphFeatures.new([o.lemma.export_form, o.part_of_speech_tag, o.language_tag].join(','), o.morphology_tag).valid?
            error { "token #{o.id} is reviewed and has morphology_tag but morphology_tag is invalid" }
          end
        end
      end

      def check_sentences
        Sentence.joins(:source_division).where("source_divisions.id IS NULL").each do |o|
          error { "sentence #{o.id} is orphaned" }
        end

        Sentence.where('sentence_number is NULL').each do |o|
          error { "sentence #{o.id} lacks sentence_number" }
        end

        annotated_and_reviewed_sentences = Sentence.where(status_tag: %i(annotated reviewed))
        annotated_sentences = Sentence.where(status_tag: :annotated)
        reviewed_sentences = Sentence.where(status_tag: :reviewed)

        annotated_sentences.joins(:tokens).where('tokens.empty_token_sort IS NULL OR tokens.empty_token_sort != "P"').where('tokens.relation_tag IS NULL').each do |o|
          @logger.error { "#{self.class}: Sentence #{o.id} is tagged as annotated but annotated_by is missing" }
        end

        annotated_and_reviewed_sentences.where('annotated_by IS NULL').each do |o|
          @logger.error { "#{self.class}: Sentence #{o.id} is tagged as annotated but annotated_by is missing" }
        end

        annotated_and_reviewed_sentences.where('annotated_at IS NULL').each do |o|
          @logger.error { "#{self.class}: Sentence #{o.id} is tagged as annotated but annotated_at is missing" }
        end

        reviewed_sentences.where('reviewed_by IS NULL').each do |o|
          @logger.error { "#{self.class}: Sentence #{o.id} is tagged as reviewed but reviewed_by is missing" }
        end

        reviewed_sentences.where('reviewed_at IS NULL').each do |o|
          @logger.error { "#{self.class}: Sentence #{o.id} is tagged as reviewed but reviewed_at is missing" }
        end
      end

      def check_persisted_models
        PERSISTED_MODELS.each do |klass|
          puts "Validating #{klass}..."
          klass.find_each do |record|
            unless record.valid?
              case record
              when Sentence
                @logger.error { "#{self.class}: #{record.class} in database fails validation: id=#{record.id} (#{record.is_reviewed? ? 'Reviewed' : 'Not reviewed'})" }
              else
                @logger.error { "#{self.class}: #{record.class} in database fails validation: id=#{record.id}" }
              end
              record.errors.full_messages do |message|
                @logger.error { "#{self.class}: #{message}" }
              end
            end
          end
        end
      end
    end
  end
end
