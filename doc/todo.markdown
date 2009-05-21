% TODO

New features
============

For next iteration
------------------

  * Fix visualization which is still based on interpretation

  * More UI stuff for semantic features [currently no online edititing of tags; create/edit/delete of 
    As and AVs must be done in SQL]

    This becomes much easier with forthcoming Rails 2.3.

  * Administrative token merging and divisions

    These functions are simple in principle, but have to be rethought
    with the new content/presentation distinction in mind. What should
    happen if a token already has presentation forms? What we need is
    actually a full-blown GUI for two-layer retokenisation. Alas!

    Kun enkle varianter: resten kan ordnes gjennom historien.

  * Skrive til TdH om multi-head-word lemmata

  * Sjekke ut advarsler fra gotisk-skript

  * Source meta-data and licensing

    The following are some bits and pieces that should go in:

    ~~~
    
    Our text builds on Ulrik Sandborg-Petersen's electronic edition which
    is intended to faithfully represent the printed text in Tischendorf's
    Editio Octava Critica Maior, Leipzig 1869-1872. But in the following
    places we have found it necessary to diverge from Tischendorf's text:

    - Tischendorf prints John 7.53-8.11 in two versions, one unaccented and
    one with accents. Our electronic text only has the accented version,
    pages 831, 833, 835 in Tischendorf vol. 1 and leaves out pages 830, 832
    and 834.

    - In Luke 15:16 prints ᾧν which we have corrected to ὧν

    ~~~

  * Subgraph alignment

    Semi-automated subgraph alignment with the option for manual, incremental
    refinement using secondary edges, potentially null-terminated to indicate
    blocked inheritance.

  * Token alignment

    The basic functions are completed, but some adjustments and experiments 
    necessary. We need to integrate the alignments in the system: should automatic 
    alignments be generated nightly? Or every time sentence annotation is changed?
    The underlying dictionary could also be generated nightly, but currently
    there is only a python script to create it.

  * Interpretive functions for subgraph alignment 

    Function set to interpret subgraphs alignment and inheritance of such.

  * Sentence 'chopping'

    We have a number of sentences that are annotated in a way that signals them to be
    multiple sentences. These can be 'chopped' automatically.

  * Optimistic locking

    Implement this/check that it works. One day it might become an issue and Rails
    should be able to handle this out of the box.

  * Error messages when merging lemmata

  * Import Armenian text and check that import functions work with the new model

  * Text presentation

    The current text presentation is rather confusing. Just a long list of all the chapters...

  * Show alignments of more than two languages

Perhaps/later/consider
----------------------

  * Implement support for schema-defined hierarchical overlapping sub-divisions.

  * Implement support for extra, non-searchable overlapping textual
  sub-divisions.

  * Gather all documentation in one location
    - include notes on text production
    - include morphology notes
    - include app doc

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
% Known bugs that

Bugs
====

Critical
--------

* Saving of very long sentences fails. One known issue with long sentences
is that the HTTP message buffer overflows. This generates messages like
this

~~~
   A RuntimeError occurred in dependencies#update:
   
     Incomplete dependency graph
     [RAILS_ROOT]/app/models/sentence.rb:129:in `syntactic_annotation='
   
   -------------------------------
   Request:
   -------------------------------
   
     * URL       :
     http://foni.uio.no:3000/annotations/43236/dependencies?wizard%5Blevel%5D=annotation&wizard%5Bskip%5D=true
     * IP address: 77.18.9.58
     * Parameters: {"annotation_id"=>"43236", "commit"=>"Save",
     "authenticity_token"=>"4cb8f3077a67ecc940921d4efcfd22d063ecf505",
     "_method"=>"put", "wizard"=>{"level"=>"annotation", "skip"=>"true"},
     "action"=>"update", "output"=>"{\"625754\": {\"relation\": \"pred\",
     \"dependents\": {\"625755\": {\"relation\": \"pred\", \"dependents\":
     {\"625756\": {\"relation\": \"obl\", \"empty\": false}}, \"empty\":
     false}, \"625745\": {\"relation\": \"pred\", \"dependents\":
     {\"625746\": {\"relation\": \"obj\", \"empty\": false}, \"625736\":
     {\"relation\": \"aux\", \"empty\": false}, \"625737\": {\"relation\":
     \"xadv\", \"empty\": false, \"slashes\": [\"625745\"]}, \"625750\":
     {\"relation\": \"xadv\", \"dependents\": {\"625747\": {\"relation\":
     \"xadv\", \"dependents\": {\"625748\": {\"relation\": \"obl\",
     \"dependents\": {\"625749\": {\"relation\": \"obl\", \"empty\":
     false}}, \"empty\": false}}, \"empty\": false}, \"625753\":
     {\"relation\": \"xadv\", \"dependents\": {\"625751\": {\"relation\":
     \"obl\", \"dependents\": {\"625752\": {\"relation\": \"obl\",
     \"empty\": false}}, \"empty\": false}}, \"empty\": false}}, \"empty\":
     false, \"slashes\": [\"625746\"]}, \"625741\": {\"relation\":
     \"nonsub\", \"dependents\": {\"625739\": {\"relation\": \"nonsub\",
     \"dependents\": {}, \"empty\": false}, \"625742\": {\"relation\":
     \"nonsub\", \"dependents\": {\"625743\": {\"relation\": \"nonsub\",
     \"dependents\": {\"625744\": {\"relation\": \"nonsub\", \"empty\":
     false}}, \"empty\": false}}, \"empty\": false}}, \"empty\": false}},
     \"empty\": false}}, \"empty\": false}}", "controller"=>"dependencies"}
     * Rails root: /hf/foni/tekstlab/home/mariuslj/live/production
   
   -------------------------------
   Session:
   -------------------------------
   
     * session id:
     "BAh7CToOcmV0dXJuX3RvMDoMY3NyZl9pZCIlNGVmMTUwMmRjMmU0YjVlNmI4\nN2NlNTkzYjMwNTY4YjgiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZs\nYXNoOjpGbGFzaEhhc2h7BjoKZXJyb3IwBjoKQHVzZWR7BjsIVDoMdXNlcl9p\nZGlB--353f6ad9b246906846f9f655639be9042caa7f96"
     * data: {:return_to=>nil,
        :csrf_id=>"4ef1502dc2e4b5e6b87ce593b30568b8",
        "flash"=>{},
        :user_id=>60}
   
   -------------------------------
   Environment:
   -------------------------------
   
     * CONTENT_LENGTH      : 1972
     * CONTENT_TYPE        : application/x-www-form-urlencoded
     * GATEWAY_INTERFACE   : CGI/1.2
     * HTTP_ACCEPT         :
     text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
     * HTTP_ACCEPT_CHARSET : ISO-8859-1,utf-8;q=0.7,*;q=0.7
     * HTTP_ACCEPT_ENCODING: gzip,deflate
     * HTTP_ACCEPT_LANGUAGE: nb,no;q=0.8,nn;q=0.6,en-us;q=0.4,en;q=0.2
     * HTTP_CONNECTION     : keep-alive
     * HTTP_CONTENT_LENGTH : 1972
     * HTTP_CONTENT_TYPE   : application/x-www-form-urlencoded
     * HTTP_COOKIE         :
     _proiel_session_id=BAh7CToOcmV0dXJuX3RvMDoMY3NyZl9pZCIlNGVmMTUwMmRjMmU0YjVlNmI4%0AN2NlNTkzYjMwNTY4YjgiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZs%0AYXNoOjpGbGFzaEhhc2h7BjoKZXJyb3IwBjoKQHVzZWR7BjsIVDoMdXNlcl9p%0AZGlB--353f6ad9b246906846f9f655639be9042caa7f96
     * HTTP_HOST           : foni.uio.no:3000
     * HTTP_KEEP_ALIVE     : 300
     * HTTP_REFERER        :
     http://foni.uio.no:3000/annotations/43236/dependencies/edit?output=%7B%22625754%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625755%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625756%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%2C+%22625745%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625746%22%3A+%7B%22relation%22%3A+%22obj%22%2C+%22empty%22%3A+false%7D%2C+%22625736%22%3A+%7B%22relation%22%3A+%22aux%22%2C+%22empty%22%3A+false%7D%2C+%22625737%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22empty%22%3A+false%2C+%22slashes%22%3A+%5B%22625745%22%5D%7D%2C+%22625750%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625747%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625748%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22dependents%22%3A+%7B%22625749%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%2C+%22625753%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625751%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22dependents%22%3A+%7B%22625752%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%2C+%22slashes%22%3A+%5B%22625746%22%5D%7D%2C+%22625741%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625742%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625743%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625744%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%2C+%22625739%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625738%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22empty%22%3A+false%7D%2C+%22625740%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D&wizard%5Blevel%5D=annotation&wizard%5Bskip%5D=true
     * HTTP_USER_AGENT     : Mozilla/5.0 (Windows; U; Windows NT 6.0; nb-NO;
     rv:1.9.0.6) Gecko/2009011913 Firefox/3.0.6
     * HTTP_VERSION        : HTTP/1.1
     * PATH_INFO           : /annotations/43236/dependencies
     * QUERY_STRING        :
     wizard%5Blevel%5D=annotation&wizard%5Bskip%5D=true
     * RAW_POST_DATA       :
     _method=put&authenticity_token=4cb8f3077a67ecc940921d4efcfd22d063ecf505&output=%7B%22625754%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625755%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625756%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%2C+%22625745%22%3A+%7B%22relation%22%3A+%22pred%22%2C+%22dependents%22%3A+%7B%22625746%22%3A+%7B%22relation%22%3A+%22obj%22%2C+%22empty%22%3A+false%7D%2C+%22625736%22%3A+%7B%22relation%22%3A+%22aux%22%2C+%22empty%22%3A+false%7D%2C+%22625737%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22empty%22%3A+false%2C+%22slashes%22%3A+%5B%22625745%22%5D%7D%2C+%22625750%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625747%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625748%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22dependents%22%3A+%7B%22625749%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%2C+%22625753%22%3A+%7B%22relation%22%3A+%22xadv%22%2C+%22dependents%22%3A+%7B%22625751%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22dependents%22%3A+%7B%22625752%22%3A+%7B%22relation%22%3A+%22obl%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%2C+%22slashes%22%3A+%5B%22625746%22%5D%7D%2C+%22625741%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625739%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%7D%2C+%22empty%22%3A+false%7D%2C+%22625742%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625743%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22dependents%22%3A+%7B%22625744%22%3A+%7B%22relation%22%3A+%22nonsub%22%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D%2C+%22empty%22%3A+false%7D%7D&commit=Save
     * REMOTE_ADDR         : 77.18.9.58
     * REQUEST_METHOD      : POST
     * REQUEST_PATH        : /annotations/43236/dependencies
     * REQUEST_URI         :
     /annotations/43236/dependencies?wizard%5Blevel%5D=annotation&wizard%5Bskip%5D=true
     * SCRIPT_NAME         : /
     * SERVER_NAME         : foni.uio.no
     * SERVER_PORT         : 3000
     * SERVER_PROTOCOL     : HTTP/1.1
     * SERVER_SOFTWARE     : Mongrel 1.1.5
     
     * Process: 17171
     * Server : foni
   
   -------------------------------
   Backtrace:
   -------------------------------
   
     [RAILS_ROOT]/app/models/sentence.rb:129:in `syntactic_annotation='

[...]
~~~

It may also be related to this problem.

~~~
> Det kan jo vanskelig være hennes datamaskin som lager problemene...mon
> tro hva som skjer? Er det bare foni som er for treig? Ingrid på gotisk
> har rapportert om liknende problemer.
> Dag
> 
> 
> -------- Forwarded Message --------
> > From: eirik.welo@ifikk.uio.no
> > To: Dagmar S Wodtko <dagmar.s.wodtko@mail.uni-freiburg.de>
> > Cc: d.t.t.haug@ifikk.uio.no
> > Subject: Computer problems
> > Date: Fri, 26 Sep 2008 09:16:20 +0200 (CEST)
> > 
> > Dear Dagmar,
> > 
> > I absolutely agree about the computer problem: it is meaningless to
> > wait
> > for hours just to save the sentences. I have looked through the
> > sentences
> > annotated in Ephesians so far and things seem generally ok, only in
> > 3:14-19 and 3:1-7 the syntactic analysis has not been recorded, only
> > morphology.
> > 
> > Is the problem with your own computer? Anyway, skip the longer
> > sentences
> > for now and Dag and I will try and come up with a solution.
> > 
> > Yours,
> > Eirik
> > 
> > > Dear Eirik,
> > > thank you for the Ephesians. The computer took more than
> > > two hours yesterday and the day before to process the long
> > > sentences at the beginning of the text, and when I tried to
> > > save there was no response. The sentences are marked red
> > > (as if unannotated) now, but something has been saved,
> > > there is a dependency tree. Still, I think I should skip
> > > sentences over 100 words from now on. If the computer is
> > > not able to process them properly, then there seems to be
> > > little use in spending hours on it.
> > > Sory about that,
> > > Dagmar
~~~
