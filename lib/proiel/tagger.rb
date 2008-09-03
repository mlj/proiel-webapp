#!/usr/bin/env ruby
#
# tagger.rb - Morphological tagger
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'lingua/normalisation'
require 'proiel/morphtag'
require 'proiel/tagger/analysis_method'
require 'proiel/tagger/fst'
require 'proiel/tagger/word_list'
require 'proiel/tagger/instance_frequency'

module PROIEL
  class WeightedMorphLemmaTag
    # A weight assigned to the tag
    attr_accessor :weight

    # A human-readable identifier used for tracing the origin of the tag when
    # inspected.
    attr_accessor :source_identifier

    attr_accessor :mltag

    def initialize(mltag, weight, source_identifier)
      @mltag = mltag
      @weight = weight
      @source_identifier = source_identifier
    end

    # Returns an integer, -1, 0 or 1, suitable for sorting the tag. The weight
    # is taken as the primary criterion for sorting, then the morphtag values.
    def <=>(o)
      s = (self.weight <=> o.weight)
      return s unless s.zero?

      @mltag <=> o.mltag
    end
  end

  module Tagger
    class Tagger
      WEIGHTS = {
        # The weight given to a generated rule
        :generated_rules => 0.2, 

        # The weight given to an FST rule
        :fst => 0.2, 

        # The weight given to a hand-written rule
        :manual_rules => 1.0,

        # The weight *ratio* for existing instances
        :instance_frequencies => 0.5,
      }

      # The weight given to a complete, existing tag
      EXISTING_TAG_WEIGHT = 1.0

      # The weight ratio for contradictory, incomplete, existing tags
      CONTRADICTION_RATIO = 0.5

      attr_accessor :logger

      # Creates a new tagger.
      #
      # ==== Options
      # logger:: Specifies a logger object.
      #
      # data_directory:: Specifies the directory in which to look for data files. The default
      # is the current directory. 
      def initialize(configuration_file, options = {})
        @logger = options[:logger]
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
              when :generated_rules
                @analysis_methods[language][method] = 
                  WordListMethod.new(language, File.join(@data_directory, args))
                @methods[language] << lambda { |form| analyze_form(language, method, form) }

              # Includes candidates from hand-crafterd word lists.
              when :manual_rules
                @analysis_methods[language][method] = 
                  WordListMethod.new(language, File.join(@data_directory, args))
                @methods[language] << lambda { |form| analyze_form(language, method, normalise_form(language, form)) }

              # Includes candidates from existing annotation.
              when :instance_frequencies
                @analysis_methods[language][method] =
                  InstanceFrequencyMethod.new(language)
                @methods[language] << lambda { |form| analyze_form(language, method, form) }
              
              # Includes candidates from an FST guesser/analyzer.
              when :fst
                @analysis_methods[language][method] = FSTMethod.new(language, 
                  File.join(@data_directory, args[:analysis]),
                  File.join(@data_directory, args[:normalisation]),
                  File.join(@data_directory, args[:orthography]))
                @methods[language] << lambda { |form| analyze_form(language, method, form) }
              end
            end
          end
        end
      end

      def analyze_form(language, method, form)
        @analysis_methods[language][method].analyze(form).collect do |t|
          if t.is_a?(Array)
            WeightedMorphLemmaTag.new(t[0], t[1] * WEIGHTS[method], method)
          else
            WeightedMorphLemmaTag.new(t, WEIGHTS[method], method)
          end
        end
      end

      # Generates a list of tags for a token.
      #
      # ==== Options
      # <tt>:ignore_instances</tt> - If set, ignores all instance matches.
      # <tt>:force_method</tt> - If set, forces the tagger to use a specific tagging method,
      #                          e.g. <tt>:manual_rules</tt> for manual rules. All other
      #                          methods are disabled.
      def tag_token(language, form, existing = nil, options = {})
        language = language.to_sym
        raise "Undefined language #{language}" unless @methods.has_key?(language) 

        begin
          raw_candidates = unless options[:force_method]
                             @methods[language].collect { |method| method.call(form) }.flatten
                           else
                             # FIXME
                             if options[:force_method] == :manual_rules
                               form = normalise_form(language, form)
                             end
                             analyze_form(language, options[:force_method], form)
                           end
        rescue Exception => e
          if @logger
            @logger.error { "Tagger method failed: #{e}" }
            return [:failed, nil]
          else
            raise e
          end
        end

        raw_candidates.sort!

        # Try to make sense of any existing information that we have
        if existing
          m = @configuration[:languages][language]

          if m[:include_new_source_tags]
            found = nil
            m[:include_new_source_tags].each_pair do |src, dst|
              if Regexp.new(src).match(existing.morphtag.to_s)
                existing.morphtag.union!(dst) if dst
                found = true
              end
            end
              
            if found and existing.morphtag.is_valid?(language) and !existing.lemma.nil?
              raw_candidates << WeightedMorphLemmaTag.new(existing, EXISTING_TAG_WEIGHT, :source) if found
            end
          end

          if m[:source_tag_pattern_filtering]
            # Do source-based filtering. Assuming that we already have information,
            # partial or complete, from our source text on morphtag or lemma, we
            # can partition our guesses in more likely and less likely candidates.
            # Lower the score of (morphtag, lemma) pairs whose morphtags contradict
            # the (probably incomplete) morphtag in the source_morphtag field.
            raw_candidates.each do |c|
              if (c.mltag.morphtag and c.mltag.morphtag.contradicts?(existing.morphtag)) || (existing.lemma and c.mltag.lemma != existing.lemma)
                c.weight = c.weight * CONTRADICTION_RATIO
              end
            end
          end
        end 

        # Filter out duplicates, accumulating scores 
        candidates = raw_candidates.inject({}) do |candidates, raw_candidate| 
          candidates[raw_candidate.mltag] ||= 0.0
          candidates[raw_candidate.mltag] += raw_candidate.weight
          candidates
        end

        # Try to pick the best match.
        ordered_candidates = candidates.sort_by { |c, w| w }.reverse

        # If the first candidate in the ordered list has the same as the next,
        # we're unable to decide, so pick none but return all as suggestions. Otherwise,
        # pick the first and return the remainder as suggestions. 
        if ordered_candidates.length > 1 and ordered_candidates[0][1] == ordered_candidates[1][1]
          [:ambiguous, nil] + ordered_candidates
        elsif ordered_candidates.length == 0
          [:failed, nil]
        else
          [ordered_candidates.tail.length == 0 ? :unambiguous : :ambiguous, 
            ordered_candidates.head.first] + ordered_candidates
        end
      end

      def normalise_form(language, form)
        case language
        when :grc
          # Strip all accents
          # FIXME: duplication
          form = Lingua::GRC::strip_accents(form)
        else
          form
        end
      end

      # Generate the complete tag space using any known tag and language as a constraint.
      # +limit+ ensures that the generated space will not exceed a certain number of
      # members and instead return nil.
      def generate_tag_space(language, known_tag, limit = 10)
        morphtags = MorphTag.new(known_tag).completions(language)
        morphtags.length > limit ? nil : morphtags 
      end
    end
  end
end
