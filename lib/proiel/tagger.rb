# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
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

require 'lingua/normalisation'
require 'proiel/tagger/analysis_method'
require 'proiel/tagger/fst'
require 'proiel/tagger/instance_frequency'
require 'proiel/tagger/inflections_table'

module Tagger
  class WeightedMorphFeatures
    # A weight assigned to the tag
    attr_accessor :weight

    # A human-readable identifier used for tracing the origin of the tag when
    # inspected.
    attr_accessor :source_identifier

    attr_accessor :morph_features

    def initialize(morph_features, weight, source_identifier)
      @morph_features = morph_features
      @weight = weight
      @source_identifier = source_identifier
    end

    # Returns an integer, -1, 0 or 1, suitable for sorting the tag. The weight
    # is taken as the primary criterion for sorting, then the morphtag values.
    def <=>(o)
      s = (self.weight <=> o.weight)
      return s unless s.zero?

      @morph_features <=> o.morph_features
    end
  end

    class Tagger
      WEIGHTS = {
        # The weight given to a rule from the inflections table.
        :inflections_table => 1.0,

        # The weight given to an FST rule
        :fst => 0.2,

        # The weight given to a hand-written rule from rule files
        :manual_rules => 1.0,

        # The weight *ratio* for existing instances
        :instance_frequencies => 0.5,
      }

      # The weight given to a complete, existing tag
      EXISTING_TAG_WEIGHT = 1.0

      # The weight ratio for contradictory, incomplete, existing tags
      CONTRADICTION_RATIO = 0.5

      # Creates a new tagger.
      #
      # ==== Options
      # data_directory:: Specifies the directory in which to look for data files. The default
      # is the current directory.
      def initialize(configuration_file, options = {})
        @data_directory = options[:data_directory] || '.'

        @analysis_methods = {}
        @methods = {}

        # Load configuration and prepare methods hash.
        @configuration = YAML::load_file(configuration_file).freeze

        if @configuration[:languages]
          @configuration[:languages].each_pair do |language, methods|
            @methods[language] = []
            @analysis_methods[language] = {}

            methods.each_pair do |method, args|
              case method

              # Includes candidates from pre-generated word lists.
              when :inflections_table
                @analysis_methods[language][method] = InflectionsTableMethod.new(language)
                @methods[language] << lambda { |form| analyze_form(language, method, form) }

              # Includes candidates from existing annotation.
              when :instance_frequencies
                @analysis_methods[language][method] =
                  InstanceFrequencyMethod.new(language, args[:completion_level] || nil)
                @methods[language] << lambda { |form| analyze_form(language, method, form) }

              # Includes candidates from an FST guesser/analyzer.
              when :fst
                @analysis_methods[language][method] = FSTMethod.new(language,
                  File.join(@data_directory, args[:analysis]),
                  args[:normalisation] ? File.join(@data_directory, args[:normalisation]) : nil,
                  args[:orthography] ? File.join(@data_directory, args[:orthography]) : nil)
                @methods[language] << lambda { |form| analyze_form(language, method, form) }
              end
            end
          end
        end
      end

      private

      def analyze_form(language, method, form)
        @analysis_methods[language][method].analyze(form).collect do |t|
          if t.is_a?(Array)
            WeightedMorphFeatures.new(t[0], t[1] * WEIGHTS[method], method)
          else
            WeightedMorphFeatures.new(t, WEIGHTS[method], method)
          end
        end
      end

      public

      # Generates a list of tags for a token.
      #
      # ==== Options
      # <tt>:ignore_instances</tt> - If set, ignores all instance matches.
      # <tt>:force_method</tt> - If set, forces the tagger to use a specific tagging method,
      #                          e.g. <tt>:manual_rules</tt> for manual rules. All other
      #                          methods are disabled.
      def tag_token(language, form, existing = nil, options = {})
        raise ArgumentError unless language.class == Symbol
        raise "Undefined language #{language}" unless @methods.has_key?(language)

        raw_candidates = unless options[:force_method]
                           @methods[language].collect { |method| method.call(form) }.flatten
                         else
                           # FIXME
                           if options[:force_method] == :manual_rules
                             form = normalise_form(language, form)
                           end
                           analyze_form(language, options[:force_method], form)
                         end
        raw_candidates.sort!

        # Try to make sense of any existing information that we have
        if existing
          m = @configuration[:languages][language]

          if m[:include_new_source_tags]
            found = nil
            m[:include_new_source_tags].each_pair do |src, dst|
              if Regexp.new(src).match(existing.pos_s + existing.morphology_s)
                existing = existing.union(MorphFeatures.new(",#{dst[0, 2]},#{language}", dst[2, 11])) if dst
                found = true
              end
            end

            if found and existing.valid? and !existing.lemma.nil?
              raw_candidates << WeightedMorphFeatures.new(existing, EXISTING_TAG_WEIGHT, :source) if found
            end
          end

          if m[:source_tag_pattern_filtering]
            # Do source-based filtering. Assuming that we already have information,
            # partial or complete, from our source text on morphtag or lemma, we
            # can partition our guesses in more likely and less likely candidates.
            # Lower the score of (morphtag, lemma) pairs whose morphtags contradict
            # the (probably incomplete) morphtag in the source_morphtag field.
            raw_candidates.each do |c|
              c.weight = c.weight * CONTRADICTION_RATIO if c.morph_features.contradict?(existing)
            end
          end
        end

        # Filter out duplicates, accumulating scores
        candidates = raw_candidates.inject({}) do |candidates2, raw_candidate|
          candidates2[raw_candidate.morph_features] ||= 0.0
          candidates2[raw_candidate.morph_features] += raw_candidate.weight
          candidates2
        end

        # Try to pick the best match and keep all entries with the
        # same weight in a predictable order.
        ordered_candidates = candidates.sort_by { |c, w| [w, c] }.reverse

        # If the first candidate in the ordered list has the same as the next,
        # we're unable to decide, so pick none but return all as suggestions. Otherwise,
        # pick the first and return the remainder as suggestions.
        if ordered_candidates.length > 1 and ordered_candidates[0][1] == ordered_candidates[1][1]
          [:ambiguous, nil] + ordered_candidates
        elsif ordered_candidates.length == 0
          [:failed, nil]
        else
          [ordered_candidates.length == 1 ? :unambiguous : :ambiguous,
            ordered_candidates.first.first] + ordered_candidates
        end
      end

      private

      def normalise_form(language, form)
        raise ArgumentError unless language.class == Symbol
        case language
        when :grc
          # Strip all accents
          # FIXME: duplication
          form = Lingua::GRC::strip_accents(form)
        else
          form
        end
      end
    end
end
