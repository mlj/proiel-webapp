Maintenance tasks
=================

`proiel:reassign:morphology`
----------------------------

This task is used to change all occurrences of a particular value of a morphological
field to another value. For example

    $ rake proiel:reassign:morphology FIELD=voice FROM=o TO=p
    Reassigning voice for token 102448: V--sapomn--- → V--sappmn---
    Reassigning voice for token 102522: V---pno----- → V---pnp-----
    Reassigning voice for token 103721: V--sapomn--- → V--sappmn---
    Reassigning voice for token 104544: V-3paio----- → V-3paip-----
    Reassigning voice for token 104849: V-3paio----- → V-3paip-----
    Reassigning voice for token 104884: V--sapomn--- → V--sappmn---
    Reassigning voice for token 105152: V--sapofn--- → V--sappfn---
    Reassigning voice for token 106066: V-3saio----- → V-3saip-----
    ...

will replace the value `p` with `o` in the `voice` field for all tokens in the database.
No further restrictions on the operation can be given, so the task is only useful for
keeping tag set and database synchronised.

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
