#!/usr/bin/env ruby
#
# sfst.rb - SFST interface
#
# Written by Marius L. Jøhndal, 2008.
#
require 'sfst'

class SFSTAnalyzer
  def initialize(language, analyzer, normalizer = nil, orthographer = nil)
    @language = language
    @analysis = load_fst(analyzer)
    @normalization = normalizer ? load_fst(normalizer) : nil
    @orthography = orthographer ? load_fst(orthographer) : nil
  end

  def analyze(form)
    form = normalize(form) if @normalization

    candidates = @analysis.analyze(form).map { |t| translate_features(t) }.flatten

    candidates.each { |c| c.lemma = orthographize(c.lemma) } if @orthography

    candidates
  end

  private

  def normalize(form)
    normalized_forms = @normalization.analyze(form)

    raise "FST normalization of #{form} (#{@language}) failed" if normalized_forms.length == 0
    raise "FST normalization of #{form} (#{@language}) is ambiguous" if normalized_forms.length > 1

    normalized_forms.first
  end

  def orthographize(form)
    candidates.each do |c|
      orthographic_forms = @orthography.analyse(c.lemma)

      raise "FST orthography translation of #{c.lemma} (#{@language}) failed" if orthographic_forms.length == 0

      if orthographic_forms.length > 1
        # FIXME: find a better solution
        c.lemma = orthographic_forms.sort_by(&:length).first
      else
        c.lemma = orthographic_forms.first
      end
    end
  end

  def load_fst(file_name)
    SFST::CompactTransducer.new(file_name)
  end

  FEATURE_MAP = {
    'nom' => {:case => 'n'},
    'voc' => {:case => 'v'},
    'acc' => {:case => 'a'},
    'gen' => {:case => 'g'},
    'dat' => {:case => 'd'},
    'ins' => {:case => 'i'},
    'abl' => {:case => 'b'},
    'loc' => {:case => 'l'},

    'sg' => {:number => 's'},
    'du' => {:number => 'd'},
    'pl' => {:number => 'p'},

    'm' => {:gender => 'm'},
    'f' => {:gender => 'f'},
    'n' => {:gender => 'n'},

    '1' => {:person => '1'},
    '2' => {:person => '2'},
    '3' => {:person => '3'},

    'noun' => {:major => 'N'},
    'verb' => {:major => 'V'},
    'adjective' => {:major => 'A'},
    'adverb' => {:major => 'D', :minor => 'f'},

    'present' => {:tense => 'p'},
    'imperfect' => {:tense => 'i'},
    'pluperfect' => {:tense => 'l'},
    'aorist' => {:tense => 'a'},
    'future' => {:tense => 'f'},
    'perfect' => {:tense => 'r'},
    'futureperfect' => {:tense => 't'},

    'indicative' => {:mood => 'i'},
    'subjunctive' => {:mood => 's'},
    'imperative' => {:mood => 'm'},
    'optative' => {:mood => 'o'},
    'infinitive' => {:mood => 'n'},
    'participle' => {:mood => 'p'},
    'gerund' => {:mood => 'd'},
    'gerundive' => {:mood => 'g'},
    'supine' => {:mood => 'u'},

    'active' => {:voice => 'a'},
    'middle' => {:voice => 'm'},
    'passive' => {:voice => 'p'},

    'positive' => {:degree => 'p'},
    'comparative' => {:degree => 'c'},
    'superlative' => {:degree => 's'},

    'noninflecting' => {:inflection => 'n'},
  }.freeze

  def translate_features(t)
    pieces = t.split('<')
    lemma, *features = pieces
    features.collect! { |f| f.sub('>', '') }
    compose_features(features).map do |fv|
      morphology = '-' * MorphFeatures::MORPHOLOGY_LENGTH
      morphology[-1] = 'i' # default to inflecting

      fv.each do |f, v|
        next if f == :major or f == :minor
        morphology[MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.index(f), 1] = v
      end

      # FIXME: guess at proper/common
      if fv[:major] == 'N'
        fv[:minor] = (lemma.capitalize == lemma) ? 'e' : 'b'
      end

      MorphFeatures.new("#{lemma},#{fv[:major] || '-'}#{fv[:minor] || '-'},#{@language}", morphology)
    end
  end

  def compose_features(features, collected = {})
    unless features.empty?
      alternatives, *rest = features

      alternatives.split('/').map do |f|
        mapped = FEATURE_MAP[f]
        raise "Unable to translate feature #{f} to positional tag (#{features.join(',')})" unless mapped

        compose_features(rest, collected.merge(mapped))
      end.flatten
    else
      collected
    end
  end
end
