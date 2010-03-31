% Data model
% Marius L. Jøhndal

Alignment
=========

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

Presentational data and tokenisation
====================================

All text columns are expected to be on Unicode Normalisation Form C.

Subset of TEI P4 used in presentation strings
---------------------------------------------

See the [http://www.tei-c.org/release/doc/tei-p4-doc/html/](TEI P4
documentation) for details.

Element      Attributes       TEI manual reference  Comment
-------      ----------       --------------------  -------
`num`        `value`          Section 6.4.3         Only for numbers that are not already on the correct natural-language form.
`expan`      `abbr`, `type`   Section 6.4.5         Only for actual abbreviations, i.e. not for host-clitic pairs, for example. `type` is `initial` if this is a proper name abbreviated.
`corr`       `sic`            Section 6.5.1
`reg`        `orig`           Section 6.5.2         Both for orthographic normalization and for removal of capitalization at the beginning of sentences.
`gap`                         Section 6.5.3
`add`                         Section 6.5.3
`del`                         Section 6.5.3
`unclear`                     Section 6.5.3
`milestone`  `n`, `unit`      Section 6.9
`speaker`                     Section 6.11
`w`                           Section 15.1          Indicates forced tokenization of material that would otherwise not be tokenized.
`segmented`  `orig`           Non-TEI               Semantically similar to `reg` except that this is not a normalization of orthography or capitalization but an expansion of a contraction. Will always contain two or more `w` elements with the proper segmentation of the expanded contraction.

The elements `expan`, `corr`, and `reg`, rather than `abbr`, `sic` and `orig`,
are used to allow permutations of these and the element `w` used for indicating
forced tokenization.

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
`languages.iso_code`                          ISO 639-3 code for a language. See [http://www.sil.org/iso639-3/codes.asp](ISO-639-3 code table) for valid codes.
`languages.name`                              ISO 639-3 name for a language. See [http://www.sil.org/iso639-3/codes.asp](ISO-639-3 code table) for valid names.
