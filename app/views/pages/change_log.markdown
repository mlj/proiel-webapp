Change log
==========

This is a list of major changes between the releases of the
application.

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

