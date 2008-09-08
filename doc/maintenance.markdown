Maintenance tasks
=================

`proiel:morphology:reassign`
----------------------------

This task is used to change all occurrences of a particular value of a morphological
field to another value. For example

    $ rake proiel:morphology:reassign FIELD=voice FROM=o TO=p
    Reassigning voice of attribute morphtag for token 102448: V--sapomn--- → V--sappmn---
    Reassigning voice of attribute morphtag for token 102522: V---pno----- → V---pnp-----
    Reassigning voice of attribute morphtag for token 103721: V--sapomn--- → V--sappmn---
    Reassigning voice of attribute morphtag for token 104544: V-3paio----- → V-3paip-----
    Reassigning voice of attribute morphtag for token 104849: V-3paio----- → V-3paip-----
    Reassigning voice of attribute morphtag for token 104884: V--sapomn--- → V--sappmn---
    Reassigning voice of attribute morphtag for token 105152: V--sapofn--- → V--sappfn---
    Reassigning voice of attribute morphtag for token 106066: V-3saio----- → V-3saip-----
    ...

will replace the value `p` with `o` in the `voice` field for all tokens in the database.
No further restrictions on the operation can be given, so the task is only useful for
keeping tag set and database synchronised.

Note that this `rake` task also modifies the `source_morphtag` attribute of each token
in the same way it modifies the `morphtag` attribute.

`proiel:morphology:force_manual_tags`
-------------------------------------

This task will apply the morphology set out in manually crafted morpholgical rules
to all tokens that match the criteria in the rules for given sources. This can be
used to overwrite bad annotations once the manually crafted morphological rules are
deemed to be entirely correct.

    $ rake proiel:morphology:force_manual_tags SOURCES=perseus-vulgate-synth
     INFO manual-tagger: Working on source perseus-vulgate-synth...
    ERROR manual-tagger: Token 251733 (sentence 12871) 'in': Tagged with closed class morphology but not found in definition.
    ERROR manual-tagger: Token 251782 (sentence 12878) 'quia': Tagged with closed class morphology but not found in definition.

`proiel:history:prune:attribute`
--------------------------------

This task is used to completely remove all entries that refer to particular
attribute from the history. This is occasionally useful when changing the database
schema when columns are removed and the data lost by the change is of no future value.

Example:
    $ rake proiel:history:prune:attribute MODEL=Token ATTRIBUTE=morphtag_source
    Removing attribute Token.morphtag_source from audit 17695
    Removing attribute Token.morphtag_source from audit 17696
    Removing attribute Token.morphtag_source from audit 17698
    Removing attribute Token.morphtag_source from audit 17701
    Removing attribute Token.morphtag_source from audit 17702
    Removing attribute Token.morphtag_source from audit 17703
    ...

`proiel:validate`
-----------------

This task validates the entire database, first using model validations for each, then
using secondary constraints that have not been implemented in the models. Some of these
are designed to be auto-correcting, e.g. orphaned lemmata are cleaned up by this task.

The task is intended to be run whenever the annotation scheme is modified to ensure that
all annotation remains valid.

`proiel:semantic_tags:import` and `proiel:semantic_tags:export`
---------------------------------------------------------------

These tasks can be used for mass-import and -export of semantic tags. The data file is 
expected to be a comma-separated file with the following fields:

  * Taggable type (string, either `Token` or `Lemma`)
  * Taggable ID (integer)
  * Attribute tag (string)
  * Attribute value tag (string)

All attributes and attribute values must already have been defined; so must any
referred token or lemmma.

Example:

    $ rake proiel:semantic_tags:export FILE=tags.csv
    $ cat tags.csv
    Token,266690,animacy,-
    Lemma,2256,animacy,+
    ...
    $ rake proiel:semantic_tags:import FILE=tags.csv
