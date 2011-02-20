Change log
==========

This is a list of major changes between the releases of the
application.

  * Dropped Dictionary, DictionaryReference and DictionaryEntry models
    (Marius)
  * Upgraded to Rails 2.3.11 (Marius)
  * More careful handling of exceptions in annotation-related controllers
    (Marius)
  * Refactored graph visualisation (Marius)
  * Upgraded to Rails 2.3.10 (Marius)

Release 20101016
----------------

  * Dropped SFST in favour of static YAML files for morphological tagset
    definition (Dag)
  * Upgraded to Rails 2.3.9 (Marius)
  * Redefined Language, Morphology and PartOfSpeech tables as aggregations
    with static tag sets (Marius)
  * Switched from customis versioning + userstamp to upstream
    acts_as_audited since this now automatically tracks user IDs (Marius)

Release 20100602
----------------

  * Switched to Formtastic and SASS (Marius)
  * Upgraded to Rails 2.3.8 (Marius)
  * Added HAML support (Marius)
  * Switched from resource_controller to inherited_resources (Marius)
  * Updated export functions (Dag)

Release 20100212
----------------

  * Changed to Devise for authentication (Marius)
  * Upgraded to Rails 2.3.5 (Marius)

Release 20090807
----------------

  * Integrated import from Perseus TEI sources (Marius)
  * Upgraded to Rails 2.3.2 (Marius)
  * Separate presentation XML on sentences and source divisions
  (Marius)
  * Token and lemma definitions altered to share part of speech
  (Marius)
  * Secondary edge interpretation changed to report actual relation
  tags (Dag and Marius)
  * Support for variable reference systems (Marius)
  * Generated inflections maintained in the database (Marius)
  * Information structure annotation (Anders)
  * Dependency alignment (Marius)
  * Licensing and attribution details (Marius)
  * Added a proper, simple search language to most index pages (Marius)
  * TEI headers for metadata (Marius)
  * Sentence alignment (Marius)

Release 20080911
----------------

  * Removed Latin locative
  * Removed Rails 2.1 blocker caused by hacked `acts_as_audited`
  * Made change sets revertible
  * Made imported sentence, token and lemma notes available + joined with `flag as bad sentence division`
  * Killed impersonal active and deponent tags
  * Updated USC text with new presentational features.
  * Re-enabled full validation
  * Implemented orphaned slash clean-up
  * Added SVG graphs, alternative visualisations and user preferences
  * Enabled editing of tokens and lemmata
  * Added writing of secondary edge labels to database
  * Added rudimentary sematic features
  * Differentiated empty dependency tokens in UI and added writing of empty dependency token sort to
    database.
  * Initial support for information structure annotation
