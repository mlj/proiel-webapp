#
# alignment.rb - Alignment support functions
#
# Written by Marius L. Jøhndal, 2007, 2008
#

# Returns a list of alignments of two lists of sentences. The alignment
# is done automatically, but takes into account the +unalignable+ flag
# on sentences, and any +sentence_alignment+ associations that already
# exist. The +sentence_alignment+ associations make up a list of sentence
# pairs which has to be monotonic for the function to function properly.
# Also, sentences with a +sentence_alignment+ association are assumed
# not to have +unalignable+ set.
# 
# +sentences1+ contains sentences from the primary source and +sentences2+
# sentences from some secondary source that should be aligned with the primary
# source. All sentences in both lists must be part of the final alignment, and
# the start and end of the two lists represent a lower and upper bounds on the
# alignment permutations.
def align_sentences(sentences1, sentences2)
  alignments = []

  anchor_sentences(sentences1, sentences2) do |grouped_sentences1, grouped_sentences2|
    alignables1 = generate_alignables(grouped_sentences1)
    alignables2 = generate_alignables(grouped_sentences2)
    alignments << Logos::Alignment::align_regions(alignables1, alignables2)
  end

  alignments.flatten
end

private

# Returns an array of alignables, i.e. lists of sentences that are to be
# treated as units during alignment. This will merge sentences with
# the +unalignable+ flag set with the immediately preceding sentence.
# If the first sentence in the +sentences+ array is marked as +unalignable+,
# it is quitely ignored.
def generate_alignables(sentences)
  sentences.inject([]) do |alignables, sentence|
    if alignables.length > 0 and sentence.unalignable
      alignables.last << sentence
    else
      alignables << Alignable.new([sentence])
    end

    alignables
  end
end

def anchor_sentences(sentences1, sentences2, &block)
  # If we iterate both sentence lists one sentence at a time,
  # we will only fail if the anchor list is not monotonic.
  unaccumulated1, unaccumulated2 = sentences1.dup, sentences2.dup
  accumulated1, accumulated2 = [], []

  # Grab sentences from first sentence list until we a) reach the end or b) find
  # an anchor.
  until unaccumulated2.empty?
    if unaccumulated2.first.sentence_alignment
      # We've found an anchor. Look for the other end of it in the secondary
      # sentence list.
      until unaccumulated1.first == unaccumulated2.first.sentence_alignment
        accumulated1 << unaccumulated1.shift
      end

      yield accumulated1, accumulated2

      # Start a new accumulation
      accumulated2 = [unaccumulated2.shift]
      accumulated1 = []
    else
      accumulated2 << unaccumulated2.shift
    end
  end

  yield unaccumulated1, accumulated2
end

class Alignable < Array
  def weight
    # Sum up the number of words in this sentence
    @weight ||= sum { |sentence| sentence.tokens.morphology_annotatable.count }
  end
end

if $0 == __FILE__
  Sentence = Struct.new(:id, :sentence_alignment)

  s23 = Sentence.new(23)
  sentences1 = [Sentence.new(11), Sentence.new(12, s23), Sentence.new(13)]
  sentences2 = [Sentence.new(21), Sentence.new(22), s23]
  anchor_sentences(sentences1, sentences2) do |x, y|
    p [x.join(','), y.join(',')].join(' : ')
  end
end
