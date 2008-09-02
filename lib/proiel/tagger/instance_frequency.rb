#!/usr/bin/env ruby
#
# instance_frequency.rb - Morphological tagger: Instance frequency method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'fastercsv'

module PROIEL
  module Tagger
    class InstanceFrequencyMethod < TaggerAnalysisMethod
      @@statistics_callback = nil

      def initialize(language, statistics_callback)
        super(language)

        raise "Invalid statistics callback" unless statistics_callback
        @@statistics_callback = statistics_callback
      end

      def analyze(form)
        instances = @@statistics_callback.call(@language, form)

        # Filter out those that fail validation or lack a lemma.
        instances.reject! { |tag, lemma, frequency| not PROIEL::MorphTag.new(tag).is_valid?(@language) or lemma.nil? }

        # Compute frequency
        sum = instances.inject(0) { |sum, instance| sum + instance[2] }
        instances.collect do |tag, lemma, frequency|
          [PROIEL::MorphLemmaTag.new("#{tag}:#{lemma}"), frequency / sum.to_f]
        end
      end
    end
  end
end
