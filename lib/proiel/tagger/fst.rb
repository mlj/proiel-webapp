#!/usr/bin/env ruby
#
# fst.rb - Morphological tagger: FST method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'proiel/tagger/analysis_method'
require 'sfst'

module Tagger
    class FSTMethod < TaggerAnalysisMethod
      def initialize(language, analysis, normalisation = nil, orthography = nil)
        super(language)

        @analysis = load_fst(analysis)
        @normalisation = normalisation ? load_fst(normalisation) : nil
        @orthography = orthography ? load_fst(orthography) : nil
      end

      def analyze(form)
        if @normalisation
          normalised_forms = @normalisation.analyze(form)

          if normalised_forms.length == 0
            raise "FST normalisation of #{form} (#{@language}) failed"
          elsif normalised_forms.length > 1
            raise "FST normalisation of #{form} (#{@language}) is ambiguous"
          else
            form = normalised_forms.first
          end
        end

        candidates = @analysis.analyze(form).collect { |t| features2morph_features(t) }.flatten

        if @orthography
          candidates.each do |c|
            orthographic_forms = @orthography.analyse(c.lemma)

            if orthographic_forms.length == 0
              raise "FST orthography translation of #{c.lemma} (#{@language}) failed"
            elsif orthographic_forms.length > 1
              # Pick the shortest one
              # FIXME: find a better solution
              c.lemma = orthographic_forms.sort_by(&:length).first
              #raise "FST orthography translation of #{form} (#{@language}) is ambiguous"

            else
              c.lemma = orthographic_forms.first
            end
          end
        end

        candidates
      end

      private

      def load_fst(file_name)
        SFST::CompactTransducer.new(file_name)
      end

      PROIEL_FEATURE_MAP = {
        'NOM' => '--------n',
        'VOC' => '--------v',
        'ACC' => '--------a',
        'GEN' => '--------g',
        'DAT' => '--------d',
        'INS' => '--------i',
        'ABL' => '--------b',
        'LOC' => '--------l',

        'SIN' => '---s',
        'DUA' => '---d',
        'PLU' => '---p',

        'MASCULINE' => '-------m',
        'FEMININE' => '-------f',
        'NEUTER' => '-------n',

        '1' => '--1',
        '2' => '--2',
        '3' => '--3',

        'NOUN' => 'Nb', # FIXME: inaccurate
        'VERB' => 'V',

        'PRESENT' => '----p',
        'IMPERFECT' =>  '----i',
        'AORIST'  => '----a',

        'INDICATIVE' => '-----i',
        'IMPERATIVE' => '-----m',
        'INFINITIVE' => '-----n',

        'ACTIVE' => '------a',
      }.freeze

      def features2morph_features(t)
        pieces = t.split('>')
        lemma, *features = pieces.reverse
        features.collect! { |f| f.sub('<', '') }
        compose_features(features)
      end

      def compose_features(features, collected = nil)
        return collected if features.empty?

        alternatives, *rest = features
        morphtags = []

        alternatives.split('/').collect do |f|
          raise "Unable to translate feature #{f} to positional tag" unless PROIEL_FEATURE_MAP.has_key?(f)
          mapped = PROIEL_FEATURE_MAP[f]
          mf = MorphFeatures.new(",#{mapped[0, 2]},#{language}", mapped[2, 11])

          if collected
            morphtags << compose_features(rest, collected.union(mf))
          else
            morphtags << compose_features(rest, mf)
          end
        end

        morphtags
      end
    end
end
