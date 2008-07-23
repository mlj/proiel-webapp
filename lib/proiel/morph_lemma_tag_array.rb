#!/usr/bin/env ruby
#
# morph_lemma_tag_array.rb - Convenience class for mltag arrays
#
# Written by Marius L. Jøhndal, 2008.
#
module PROIEL
  class MorphLemmaTagArray < Array
    def intersection
      r = MorphLemmaTag.new('')
      r.morphtag = Logos::PositionalTag::intersection(PROIEL::MorphTag, *morphtags)

      if lemmata.length > 1
        r.lemma = nil
        r.variant = nil
      else
        r.lemma = lemmata.first

        variants = self.map(&:variant).uniq
        r.variant = variants.length > 1 ? nil : variants.first
      end
      r
    end

    def lemmata
      self.map(&:lemma).uniq
    end

    def morphtags
      self.map(&:morphtag).uniq
    end
  end
end
