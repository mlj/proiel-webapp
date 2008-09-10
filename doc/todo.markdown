For next iteration
------------------

  * Generalised `indeclinable` field [complete, but too unstable]

  * Refactoring of morphtag and lemma + part of speech [complete, but too unstable]

  * Export slash edge labels; fix visualization which is still based on interpretation

  * More UI stuff for semantic features [currently no online edititing of tags; create/edit/delete of 
    As and AVs must be done in SQL]

  * Export of empty dependency token sorts

  * Non-numeric chapter number support

    Texts can have non-numeric chapter numbers. These have been set to 0 and 255
    now, creating the illusion of 0..255 chapters in some books.

  * Administrative token merging and divisions

    These functions are simple in principle, but have to be rethought
    with the new content/presentation distinction in mind. What should
    happen if a token already has presentation forms? What we need is
    actually a full-blown GUI for two-layer retokenisation. Alas!

    Kun enkle varianter: resten kan ordnes gjennom historien.

  * Skrive til TdH om multi-head-word lemmata → TODO-dokument

  * Sjekke ut advarsler fra gotisk-skript → TODO-dokument

  * Source meta-data and licensing → TODO-dokument

  * Gather all documentation in one location
    - include notes on text production
    - include morphology notes
    - include app doc

  * Full sentence alignment 

    Full support for automated sentence alignment with manual adjustment of 
    sentence alignment by insertion of anchors.

  * Subgraph alignment

    Semi-automated subgraph alignment with the option for manual, incremental
    refinement using secondary edges, potentially null-terminated to indicate
    blocked inheritance.

  * Interpretive functions for subgraph alignment 

    Function set to interpret subgraphs alignment and inheritance of such.

  * Sentence 'chopping'

    We have a number of sentences that are annotated in a way that signals them to be
    multiple sentences. These can be 'chopped' automatically.

  * Optimistic locking

    Implement this/check that it works. One day it might become an issue and Rails
    should be able to handle this out of the box.

Perhaps/later/consider
----------------------

  * Class morphology

    The class morphology system is still broken for OCS. The compiler
    is broken in essentially two places: the coordination of upper
    and lower levels fails (this is a design flaw and can only be
    hacked together), and the synchronisation symbols used to order
    sound changes are not removed. In addition, the whole system
    lacks glue code after the latest attempt at fixing the system.

  * Fix editorial symbols in existing text.

    We need to distinguish editorial symbols that stem from our sources and those
    that originate with use. They have to be styled as in the source, but interpretable.
    Our changes should probably be layered on top of any existing data.

  * Allow coordination of ADV and XADV

  * Add local editorial tools

    We need to be able to change the text occasionally, e.g.

      tvo tvorite → tvorite in SID 36702
      ????? (deletion) in SID 36930

    Primarily, we are talking about excluding tokens from annotation, but it might be
    styled as parallel to editorial deletions (with overstriking).

  * Fix broken editorial tokenisation in OCS

    Editorial symbols are tokenised badly in OCS (and probably in general), e.g.

      "{x}yz" → "{", "x}yz"

Wishlist
--------

  * Searching

  * Clean up failed Gothic lemma import

    Some Gothic lemmata were originally imported with `pos.length == 0`
    or `pos.length == 1`. This has lead to massive (~ 100) duplication 
    which has to be cleaned out manually by merging lemmata. The lemma
    to be kept will have `foreign_ids` set. Multiple complications
    exits: sometimes the POS will be different since PROIEL annotation
    != wulfila.be annotation, and so the wulfila.be lemma needs to
    have its POS changed before merging. For others, the variant
    number will be different: Streitberg may have a sub-lemma/sub-headword
    where we do not use a variant number and vice versa (this is of course
    a general problem too which should spawn its own item in this list).

  * Lemma base form mismatches (Streitberg != wulfila.be) in Gothic 

    For a number of Gothic lemmata the imported wulfila.be data includes
    corrections that make the lemma different from the headword in
    Streitberg's dictionary. Most of these have been corrected (documented
    in doc/texts.markdown), but two classes remain unresolved.

    Class 1: the entries have been corrected in various ways

      * aurkje, &lt;multi&gt;aurkjus oder aurkeis* Mia
      * bistugq, bistug(g)q
      * faus, fawai
      * af-giban, af-giban sik
      * hnasqus, hnasqjaim
      * seins, *seins [includes marker for non-existing form]
      * dis-sigqan,dis-sig(g)qan
      * ga-stigqan,ga-stiggqan
      * usbloteins, us-bloteins
      * war, warai
      * and-weihan, and-waihan*

    Class 2: the XML dictionary contains multiple headwords in the
    form-element and so cannot be correctly cross-referenced. 

      * Antiaukia, Antiaukia*, Antiokia*
      * Ater, Ater*, Ateir*
      * Iaireiko, Iaireiko*, Iairiko*
      * is, is M, si F, ita N
      * nibai,  nibai, niba

    This seems to actually extend beyond the subset identified by
    Lemmata.Lemma != Lemmata.WSLemma -- and thus the list above, but I am
    not sure how that has come about.

  * Gothic MS variants 

    The Gothic text includes text from multiple witnesses. Our current
    version includes all witnesses with markup identifying their provenance,
    but we do not have any way of dealing with such texts. We need to figure
    out if this is something we want to do, e.g. by flagging sentences from
    one witness as 'unannotatable', or if we just include a subset of
    witnesses in our base text.

  * Modularisation of the `proiel` tree

    The system would benefit greatly from a three module architecture: 
    proiel-webapp, proiel-lib and proiel-data. This is not difficult, but
    has to be done at a point in time when the number of diverging branches
    is minimal, i.e. when the next unstable version is promoted to stable.
    This task must be completed before source code can be exported to
    other projects.

  * Promote tags to first-order data objects

    The choice between enum-like tags with static interpretation (e.g.
    `tokens.sort`), enum-like tags defined by external schema (e.g. current
    `tokens.relation`) and full blown associations is hard to make and
    convoluted, but it seems that the second type should be sacrificed in
    favour of the third, as the database more and more assumes primacy as
    the authoritative data model at the expense of the XML model.

    The consequences are: promote tag fields to full blown tables and export
    XML definitions from these, rather than the quirky way we do it now. This
    requires a substantial expansion of the data model with plenty of supporting
    code. Fortunately, this is what Rails is good at, so this does not necessarily
    have to be much work. The pay-off is full search options and dynamic changing
    of tag sets. Complications: it becomes a lot harder to do MySQL-based searching
    since most operations will require twice the number of joins.

  * Perseus links

    Linking code to Perseus exists, but it has no home. This should be 
    reintroduced in the Lemma#show view alongside references to other
    dictionaries.

  * Dictionary links

    We have links to Streitberg in Gothic lemmata, links to Strong can 
    easily be deduces for Greek, and, with some detective work, we can 
    reconstruct links to Lewis and Short for Latin. We have electronic 
    versions of Streitberg, Strong, the abridged Lewis, the abridged 
    Liddell and Scott and a scanned version of Cejtlin. Much can be 
    done to make use of these resources.

  * Class morphology for OCS

    The test suite for OCS fails in about half a dozen places, does
    not include participles and lacks support for root aorists and
    primary sigmatic aorists.

  * Administrative sentence division

    Sentence division is tricky only so far as to find a way GUI-wise to 
    do it reliably. Does it belong in the `SentencesController`? As
    a `create` method? Where then does the `token_id` come from?

  * Translation of wulfila.be's class morphology

  * Class morphology in the web interface

  * `to_xml` and PROIEL xml 

    If this can be done without breaking anything, it would be a lot more consistent
    if PROIEL XML could be emitted from `to_xml` on models. This would clean up the
    representation considerably and make the XML output useful.

  * Feed text changes back to sources

    Export all text and compare it to the originals. Make diffs to send to our
    sources, and check the contents of the diffs for any deviations that might have been
    introduced unintentionally during the development process.

    For USC in particular, I inadvertently introduced a couple of 'unnecessary' changes
    in `corrections.patch` that belong in `proiel.patch`. These are all concerned with
    punctuation.

  * Make validation error messages more comprehensible 

    Most of the validation error messages that are concerned with dependency relations
    border on the incomprehensible. This is mostly becuase the validation code could
    need some refactoring, so a look at this would help in both respects.

  * reconstructed, conjectures etc.

    There are flags on lemmata for reconstructed forms, conjectures &c. These should be
    employed and displayed properly and somehow worked into the system of asterisks
    employed by Gothic annotators now.

    The complete list:

    * `conjecture`
    * `unclear`
    * `reconstructed`
    * `nonexistent`
    * `inflected`

    Also, those lemmata that secondarily reference others have been imported, but
    these should, by policy, not be available and have to be purged.

  * Synchronise XML import, export and database data model

    These are probably out of sync by now in multiple minor respects. Check and fix!
    Also add IDs to all objects, e.g. sentence IDs.

  * Constrain lemma tuples and redefine `morphtag` as the tuple `(POS, morphology, lemma)`

    Lemma tuples are supposed to be unique

         (base_form, POS, variant)

    and

         exists (base_form, POS, nil) → !exists (base_form, POS, non-nil)
         exists (base_form, POS, non-nil) → !exists (base_form, POS, nil)

    but this is not the case. This is blocked by a bunch of lemmata that need manual
    consideration and slight adjustments to the lemma choice algorithms.

  * Verify that manual rules for closed parts of speech match annotation for Latin, 
    Gothic and OCS

  * Wiki

  * Revise statistics functions

  * Re-write silly `bookmark` system as a true assignment system.

    Blocked by lack of first-order text division objects in the data model.

  * Promote `books` to first-order text division object and make it hierarchical

  * User-configurable transliteration functions

  * Add transliteration to search boxes

  * Change lemma sort order to use sort key

    To fix 'bad' sort order in Gothic, the imported sort key has to be respected.

  * Grid based CSS

    The current CSS used for text presentation is a hodge-podge of tweaks. It does not
    really look like a 'text'; imposing a grid based layout should easily bring balance
    back to it.

  * Fix broken MaltXML

  * Update morphology and dependency editors to work in IE

    This broke at some point. Should be trivial to fix.

  * Tree folding in annotation UI

  * Annotation work reports

  * Adapt the interpretation function to synthesise an interpretation label for slash edges.

  * Teach the tagger how to deal with tokens that do not match the normalisation.

  * Dependency UI: ensure that the ROOT relation is immutable during editing.
