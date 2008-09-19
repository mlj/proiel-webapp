Data model
==========

`sentences`
-----------

Column                  Description
------                  -----------
`unalignable`           If true, the sentence is, for the purposes of sentence alignment,
                        not to be considered as an independent unit, but rather as part
                        of the previous sentence in the linear ordering of sentences. This
                        is, in other words, an indication that the sentence has been 'black-
                        listed' from sentence alignment.

`automatic_alignment`   If true, this alignment has been generated automatically
                        and is therefore more likely to be wrong and thus more likely
                        to be a candidate for deletion should alignment need
                        to be adjusted at a later stage.

`sentence_alignment_id` The sentence this sentence is aligned with. This alignment has
                        been provided manually unless `automatic_alignment` is set.
