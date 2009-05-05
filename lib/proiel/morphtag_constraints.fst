#languages#      = <CHU><LAT><XCL><GRC><GOT>

#major#          = PMNVASDRCGFI\-
#minor#          = psktrdcixagobejhfnqu\-
#person#         = 123\-
#number#         = sdp\-
#tense#          = pilafrtsu\-
#mood#           = ismonpdgu\-
#voice#          = aemp\-
#gender#         = opqrmfn\-
#case#           = nvagdbilc\-
#degree#         = pcs\-
#animacy#        = ia\-
#strength#       = wst\-
#inflection#     = in\-

ALPHABET = [#major#] [#minor#] [#person#] [#number#] [#tense#] [#mood#] [#voice#] [#gender#] [#case#] [#degree#] [#animacy#] [#strength#] [#inflection#]
$any$    = [#major#] [#minor#] [#person#] [#number#] [#tense#] [#mood#] [#voice#] [#gender#] [#case#] [#degree#] [#animacy#] [#strength#] [#inflection#]

$n$ = [^\-]
$e$ = \-

% Mapping between positional tags and feature sets
% ================================================

$feature_mapping$ = \
  (<PRONOUN>:P | <NUMERAL>:M | <NOUN>:N | <VERB>:V | <ADJECTIVE>:A | <ARTICLE>:S | <ADVERB>:D | <PREPOSITION>:R | <CONJUNCTION>:C | <SUBJUNCTION>:G | <FOREIGNWORD>:F | <INTERJECTION>:I | <>:\-) \
  (<PERSONAL>:p | <POSSESSIVE>:s | <PERSONALREFLEXIVE>:k | <POSSESSIVEREFLEXIVE>:t | <RELATIVE>:r | <DEMONSTRATIVE>:d | <RECIPROCAL>:c | <INTERROGATIVE>:i | <INDEFINITE>:x | <CARDINAL>:a | <CARDINALINDECL>:g | <ORDINAL>:o | <COMMON>:b | <PROPER>:e | <COMMONINDECL>:h | <PROPERINDECL>:j | <COMPARABLE>:f | <NONCOMPARABLE>:n | <RELATIVE>:q | <INTERROGATIVE>:u | <>:\-) \
  (<1>:1 | <2>:2 | <3>:3 | <>:\-) \
  (<SIN>:s | <DUA>:d | <PLU>:p | <>:\-) \
  (<PRESENT>:p | <IMPERFECT>:i | <PLUPERFECT>:l | <AORIST>:a | <FUTURE>:f | <PERFECT>:r | <FUTUREPERFECT>:t | <RESULTATIVE>:s | <PAST>:u | <>:\-) \
  (<INDICATIVE>:i | <SUBJUNCTIVE>:s | <IMPERATIVE>:m | <OPTATIVE>:o | <INFINITIVE>:n | <PARTICIPLE>:p | <GERUND>:d | <GERUNDIVE>:g | <SUPINE>:u | <>:\-) \
  (<ACTIVE>:a | <MIDDLEPASSIVE>:e | <MIDDLE>:m | <PASSIVE>:p | <>:\-) \
  (<MASCULINENEUTER>:o | <MASCULINEFEMININE>:p | <MASCULINEFEMININENEUTER>:q | <FEMININENEUTER>:r | <MASCULINE>:m | <FEMININE>:f | <NEUTER>:n | <>:\-) \
  (<NOM>:n | <VOC>:v | <ACC>:a | <GEN>:g | <DAT>:d | <ABL>:b | <INS>:i | <LOC>:l | <GEN/DAT>:c | <>:\-) \
  (<POSITIVE>:p | <COMPARATIVE>:c | <SUPERLATIVE>:s | <>:\-) \
  (<INANIMATE>:i | <ANIMATE>:a | <>:\-) \
  (<WEAK>:w | <STRONG>:s | <WEAK/STRONG>:t | <>:\-) \
  (<INFLECTING>:i | <NONINFLECTING>:n | <>:\-)

% Positional tag space
% ====================

%                               Person  Number  Tense   Mood   Voice  Gender  Case  Deg Ani Str Inf
$personal_pronominal$ =         $n$     $n$     $e$     $e$    $e$    $n$     $n$   $e$ $n$ $e$ i
$nominal$ =                     $e$     $n$     $e$     $e$    $e$    $n$     $n$   $e$ $n$ $e$ i
$adjective$ =                   $e$     $n$     $e$     $e$    $e$    $n$     $n$   $n$ $n$ $n$ i
$comparable_adverb$ =           $e$     $e$     $e$     $e$    $e$    $e$     $e$   $n$ $e$ $e$ i
$indeclinable$ =                $e$     $e$     $e$     $e$    $e$    $e$     $e$   $e$ $e$ $e$ n

% Verbs are complex and need more detailed attention
$verb$ = ( \
  % Person  Number  Tense    Mood   Voice  Gender  Case  Degree  Animacy  Strength  Inflection
  $e$       $e$     [praf]   n      $n$    $e$     $e$   $e$     $e$      $e$       i | \ % ininitive
  $e$       $n$     [prafsu] p      $n$    $n$     $n$   $e$     $n$      $n$       i | \ % participle
  $e$       $e$     $e$      [du]   $e$    $e$     $n$   $e$     $e$      $e$       i | \ % gerund & supine
  $e$       $n$     $e$      g      $e$    $n$     $n$   $e$     $n$      $n$       i | \ % gerundive
  $n$       $n$     [pafr]   m      $n$    $e$     $e$   $e$     $e$      $e$       i | \ % imperative
  $n$       $n$     $n$      [iso]  $n$    $e$     $e$   $e$     $e$      $e$       i   \ % other finite forms
)

$legal_tags$ = ( \
  P [pskt]  $personal_pronominal$ | \
  P [pskt]  $indeclinable$        | \
  P [rdcix] $nominal$             | \
  P [rdcix] $indeclinable$        | \
  M [ao]    $nominal$             | \
  M [ao]    $indeclinable$        | \
  N [be]    $nominal$             | \
  N [be]    $indeclinable$        | \
  V \-      $verb$                | \
  V \-      $indeclinable$        | \
  A \-      $adjective$           | \
  A \-      $indeclinable$        | \
  S \-      $nominal$             | \
  S \-      $indeclinable$        | \
  D f       $comparable_adverb$   | \
  D [fqu]   $indeclinable$        | \
  [RCGFI] \- $indeclinable$         \
)

$tags$ = $any$ & $legal_tags$

% Language-specific removal of entire categories
% ==============================================

$xcl_category_removals$ = (.   .   .   .   .   .   .   \-:[#gender#] .    \-:[#degree#]   \-:[#animacy#] \-:[#strength#] .)
$lat_category_removals$ = (.   .   .   .   .   .   .   .             .    .   \-:[#animacy#] \-:[#strength#] .)
$grc_category_removals$ = (.   .   .   .   .   .   .   .             .    .   \-:[#animacy#] \-:[#strength#] .)
$got_category_removals$ = (.   .   .   .   .   .   .   .             .    .   \-:[#animacy#] .               .)
$chu_category_removals$ = (.   .   .   .   .   .   .   .             .    .   .              .               .)

% Language-specific removal of specific category *values*
% =======================================================

% Global or language-specific restrictions on category value combinations
% =======================================================================

% (Some of these restrictions are properly language-specific, but currently flagged
% as global as they (coincidentally) apply to all our current languages.)

                       % Maj Min Per Num          Ten             Moo  Voi          Gender           Case       Deg Ani             Str Inf
$c$                   = (.   .   .   .            .               .    .            m                .          .   .               .   .) | \
                        (.   .   .   .            .               .    .            [^m]             .          .   \-:[#animacy#]  .   .)
$d$                   = (.   .   .   .            .               .    .            .                a          .   .               .   .) | \
                        (.   .   .   .            .               .    .            .                [^a]       .   \-:[#animacy#]  .   .)

$g$                   = (.   .   .   .            \-:[#tense#]    [np]  \-:[#voice#] .             .          .   .               .   .) | \
			(.   .   .   .            .               [^np] .            .               .          .   .               .   .)
$h$                   = (.   .   .   \-:[#number#] .               g     .            \-:[#gender#]    \-:[#case#]	.   .               . ) | \
			(.   .   .   .            .               [^g]	.            .               .          .   .               .  .)

$restricted_tags$ = (\
  (<XCL>  ($h$ || $g$ || $xcl_category_removals$  || $tags$)) | \
  (<LAT> ($lat_category_removals$ || $tags$)) | \
  (<GRC> ($grc_category_removals$ || $tags$)) | \
  (<GOT> ($got_category_removals$ || $tags$)) | \
  (<CHU> ($c$ || $d$ || $chu_category_removals$  || $tags$))   \
)
$restricted_tag_space$ = _$restricted_tags$

([#languages#] $feature_mapping$) || $restricted_tag_space$
