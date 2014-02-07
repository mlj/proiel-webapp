module Proiel
  module MorphologyTagger
  # Any morphological features already
  # set for the token will take precedence, as will any value of the
  # +source_morph_features+ attribute. If features can be guessed, these
  # are set for the token, but the token is not saved. The function returns
  # a list of alternative suggestions in order of decreasing probability.
  # To check if the guesser altered the features of the token, check the
  # value of +changed?+.
    def guess_morphology(language_tag, form, options = {})
    # Guess morphology using both +morph_features+ and
    # +source_morph_features+. The only way of making use of
    # +source_morph_features+ is to include them here as there is no
    # guarantee that these will be complete, so we may have to use the
    # guesser to complete them. The motivation for also filtering the
    # guesses using +morph_features+ is so that we can supply a
    # 'reasonable' set of alternative suggestions (for example of
    # alternative lemmata) along for a token with +morph_features+ already
    # set.
    _, pick, *suggestions = language.guess_morphology(form, morph_features || source_morph_features)

    # Figure out which features to use. The following is the sequence of
    # priority: 1) Any value set by the caller, 2) any value already set on
    # the token. +source_morphology_tag+ only has an effect on the guessing of
    # morphology.
    new_morph_features = if overlaid_features
                           # FIXME
                           x, y, z, w = overlaid_features.split(',')
                           MorphFeatures.new([x, y, z].join(','), w)
                         elsif morph_features
                           morph_features
                         elsif pick
                           pick
                         else
                           nil
                         end

    # FIXME: find a way of unifying this with morph_features=() ideally by
    # avoiding the implicit saving of objects.
    if new_morph_features
      self.morphology = new_morph_features.morphology
      self.lemma = new_morph_features.lemma
    else
      self.morphology = nil
      self.lemma = nil
    end

    # Return all suggestions but strip off the probabilities.
    suggestions.map(&:first)

    end
  end
end
