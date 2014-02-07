#--
#
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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
  module MorphologyTagger
    module FrequencyMethod
      def compute_weight(frequency, sum)
        # We rely on integer arithmetic only here since we are going to squeeze
        # the weight into an integer column anyway.
        (count * MAXIMUM_WEIGHT) / sum
      end

      MINIMUM_WEIGHT = 0

      MAXIMUM_WEIGHT = 100

      # Recomputes the weights in the instance table based on the frequency of
      # occurrences in the tokens table. If a record already exists in the
      # inflections table for a given annotation, its weight will be updated.
      # If no record exists, a new record is created. If a record in the
      # inflections table no longer corresponds to any annotation, its weight
      # is set to the minimum value.
      #
      # Options:
      #
      #   status_tag_filter: If set, filters the annotation taken into account
      #   on the basis of the annotation status tag on the corresponding
      #   sentence. May be a string, symbol or an array of strings or symbols.
      #   The default is no filtering.
      def create_or_update_weights!(language_tag, options = {})
        status_tags =
          options[:status_tag_filter] || %w(unannotated annotated reviewed)

        frequencies = annotation_frequencies(language_tag, status_tags)

        Inflection.transaction do
          # Reset all weights in case some have ceased to be used.
          Inflection.
            where(language_tag: language_tag).
            update_all(weight: MINIMUM_WEIGHT)

          # Iterate forms in the frequencies hash and update records in the
          # inflections table with new weights.
          frequencies.each do |form, annotation_and_count|
            sum = annotation_and_count.values.sum

            annotation_and_count.each do |annotation, count|
              lemma, part_of_speech_tag, morphology_tag = annotation

              inflection =
                Inflection.find_or_initialize_by(language_tag: language_tag,
                  form: form,
                  lemma: lemma,
                  part_of_speech_tag: part_of_speech_tag,
                  morphology_tag: morphology_tag)

              inflection.weight = compute_weight(count, sum)

              inflection.save!
            end
          end
        end
      end

      def annotation_frequencies(language_tag, status_tags)
        scope = Token.
          joins(sentence: [source_division: :source], lemma: []).
          where('sentences.status_tag' => status_tags).
          where('sources.language_tag' => language_tag)

        frequencies_by_form_and_annotation = scope.
          group(:form, 'lemmata.lemma', 'lemmata.part_of_speech_tag',
                :morphology_tag).
          count

        # Reindex frequencies hash by form
        Hash.new.tap do |frequencies_by_form|
          frequencies_by_form_and_annotation.each do |k, count|
            form, *rest = k
            frequencies_by_form[form] ||= {}
            frequencies_by_form[form][rest] = count
          end
        end
      end
    end
  end
end
