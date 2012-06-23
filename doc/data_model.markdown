% Data model
% Marius L. Jøhndal
% 23 June 2012

# Presentation text

_Presentation text_ is textual material that should be included when the
sentence is formatted for presentation but should not itself be annotated.

Presentation text is stored in the columns `presentation_before` and
`presentation_after` in the tables `tokens`, `sentences` and `source_divisions`.
The semantics of these columns differ from table to table. The
`source_divisions` columns can contain any amount of text. This is therefore
suitable for introductory material like prologues or chapter headings, which for
one reason or another is exempted from annotation.

The `sentences` and `tokens` columns are restricted to strings of a certain
length (see the schema for the exact value). The `sentences` columns are
intended for presentation text that is not part of the running text but indicate
some sort of fixed break that unambiguously separate sentences. An example would
be stage directions in drama.

The `tokens` columns, on the other hand, should contain presentation text that
intervenes in the running text. This is typically punctuation and interword
spacing.

Two sentences can be merged when there is presentation text intervening between
the sentences but only when this is represented in the relevant `tokens`
columns. If it is represented in the `sentences` columns, it is interpreted as a
fixed sentence boundary. Since sentences from different source divisions cannot
be merged, representation of presentation text in the `source_divisions` table
plays no role in merging sentences.


# General conventions

## Languages

Columns named `language_tag` contain an ISO-639-3 (three letter) language
tag. Valid tags are all tags defined in the most recent version of the
ISO-639-3 standard.





# Alignment

For all alignments the directionality of the alignment relations is from the
secondary source, i.e. the assumed translation, to the primary source, i.e. the
assumed original.

Sentence alignment
------------------

Column                                         Description
------                                         -----------
`source_divisions.aligned_source_division_id`  The source division this source division should be aligned to. This should be set on secondary sources only. The relation is used to determine the scope of automatic sentence alignment.
`sentences.unalignable`                        If true, the sentence is, for the purposes of sentence alignment, not to be considered as an independent unit, but rather as part of the previous sentence in the linear ordering of sentences. This is, in other words, an indication that the sentence has been 'black- listed' from sentence alignment.
`sentences.automatic_alignment`                If true, the sentence alignment indicated by `sentences.sentence_alignment_id` has been generated automatically and is therefore more likely to be wrong and thus more likely to be a candidate for deletion should alignment need to be adjusted at a later stage. The flag is set when automatic sentence alignment is committed and unset when it is uncommitted.
`sentences.sentence_alignment_id`              The sentence this sentence is aligned with. This sentence alignment has been provided manually unless `sentences.automatic_alignment` is set.

Token alignment
---------------

Column                               Description
------                               -----------
`tokens.token_alignment_id`          The token this token is aligned with for the purposes of token alignment. This token alignment has been provided manually unless `tokens.automatic_token_alignment` is set.
`tokens.automatic_token_alignment`   If true, the token alignment indicated by `tokens.token_alignment_id` has been generated automatically.

Dependency alignment
--------------------

Column                                        Description
------                                        -----------
`tokens.dependency_alignment_id`              The token that is the head of the dependency subgraph this token is aligned with for the purposes of dependency alignment.
`dependency_alignment_terminations.token_id`  The token whose dependency subgraph has a termination, i.e. which is not part of its heads dependency subgraph alignment.
`dependency_alignment_terminations.source_id` The target source for the termination in `dependency_alignment_terminations.token_id`. This is required since terminations can occur in both primary and secondary sources, and only for those from secondary sources can the relationship between the alignments be inferred automatically.

External data references
========================

Column                                        Description
------                                        -----------
`sentences.foreign_ids`                       A comma separated string of key-value pairs on the format key=value that can used to store identifiers or meta-data associated with the row. This is intended to be used typically as semi-permanent holding space for data that does not yet fit into the data model, but is likely to be useful for future extensions. Example: `source_segment_id=T567,witness=CA`
`tokens.foreign_ids`                          See `sentences.foreign_ids`
`lemmata.foreign_ids`                         See `sentences.foreign_ids`

Meta data
=========

Column
------
`languages.tag`                               ISO 639-3 code for a language. See [http://www.sil.org/iso639-3/codes.asp](ISO-639-3 code table) for valid codes.
`languages.name`                              ISO 639-3 name for a language. See [http://www.sil.org/iso639-3/codes.asp](ISO-639-3 code table) for valid names.
