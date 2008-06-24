#major#          = PMNVASDRCGFI\-
#minor#          = psktrdcixagobejhfnqu\-
#person#         = 123\-
#number#         = sdp\-
#tense#          = pilafrtsu\-
#mood#           = ismonpdgu\-
#voice#          = aempndoq\-
#gender#         = opqrmfn\-
#case#           = nvagdbil\-
#degree#         = pcs\-
#animacy#        = ia\-
#strength#       = ws\-

$n$ = [^\-]
$e$ = \-

ALPHABET = [#major#] [#minor#] [#person#] [#number#] [#tense#] [#mood#] [#voice#] [#gender#] [#case#] [#degree#] [#animacy#] [#strength#]
$any$    = [#major#] [#minor#] [#person#] [#number#] [#tense#] [#mood#] [#voice#] [#gender#] [#case#] [#degree#] [#animacy#] [#strength#]
$feature_mapping$ = \
  (<PRONOUN>:P | <NUMERAL>:M | <NOUN>:N | <VERB>:V | <ADJECTIVE>:A | <ARTICLE>:S | <ADVERB>:D | <PREPOSITION>:R | <CONJUNCTION>:C | <SUBJUNCTION>:G | <FOREIGNWORD>:F | <INTERJECTION>:I | <>:\-) \
  (<PERSONAL>:p | <POSSESSIVE>:s | <PERSONALREFLEXIVE>:k | <POSSESSIVEREFLEXIVE>:t | <RELATIVE>:r | <DEMONSTRATIVE>:d | <RECIPROCAL>:c | <INTERROGATIVE>:i | <INDEFINITE>:x | <CARDINAL>:a | <CARDINALINDECL>:g | <ORDINAL>:o | <COMMON>:b | <PROPER>:e | <COMMONINDECL>:h | <PROPERINDECL>:j | <COMPARABLE>:f | <NONCOMPARABLE>:n | <RELATIVE>:q | <INTERROGATIVE>:u | <>:\-) \
  (<1>:1 | <2>:2 | <3>:3 | <>:\-) \
  (<SIN>:s | <DUA>:d | <PLU>:p | <>:\-) \
  (<PRESENT>:p | <IMPERFECT>:i | <PLUPERFECT>:l | <AORIST>:a | <FUTURE>:f | <PERFECT>:r | <FUTUREPERFECT>:t | <RESULTATIVE>:s | <PAST>:u | <>:\-) \
  (<INDICATIVE>:i | <SUBJUNCTIVE>:s | <IMPERATIVE>:m | <OPTATIVE>:o | <INFINITIVE>:n | <PARTICIPLE>:p | <GERUND>:d | <GERUNDIVE>:g | <SUPINE>:u | <>:\-) \
  (<ACTIVE>:a | <MIDDLEPASSIVE>:e | <MIDDLE>:m | <PASSIVE>:p | <MIDDLEPASSIVEDEPONENT>:n | <MIDDLEDEPONENT>:d | <PASSIVEDEPONENT>:o | <IMPERSONALACTIVE>:q | <>:\-) \
  (<MASCULINENEUTER>:o | <MASCULINEFEMININE>:p | <MASCULINEFEMININENEUTER>:q | <FEMININENEUTER>:r | <MASCULINE>:m | <FEMININE>:f | <NEUTER>:n | <>:\-) \
  (<NOM>:n | <VOC>:v | <ACC>:a | <GEN>:g | <DAT>:d | <ABL>:b | <INS>:i | <LOC>:l | <>:\-) \
  (<POSITIVE>:p | <COMPARATIVE>:c | <SUPERLATIVE>:s | <>:\-) \
  (<INANIMATE>:i | <ANIMATE>:a | <>:\-) \
  (<WEAK>:w | <STRONG>:s | <>:\-)

%                               Person  Number  Tense   Mood   Voice  Gender  Case  Degree  Animacy  Strength
$personal_pronominal$ =         $n$     $n$     $e$     $e$    $e$    $n$     $n$   $e$     $e$      $e$
$nominal$ =                     $e$     $n$     $e$     $e$    $e$    $n$     $n$   $e$     $e$      $e$
$adjective$ =                   $e$     $n$     $e$     $e$    $e$    $n$     $n$   $n$     $e$      $e$
$comparable_adverb$ =           $e$     $e$     $e$     $e$    $e$    $e$     $e$   $n$     $e$      $e$
$indeclinable$ =                $e$     $e$     $e$     $e$    $e$    $e$     $e$   $e$     $e$      $e$

% Verbs are complex and need more detailed attention
$verb$ = ( \
  % Person  Number  Tense   Mood   Voice  Gender  Case  Degree  Animacy  Indefiniteness
  $e$       $e$     $n$     n      $n$    $e$     $e$   $e$     $e$      $e$ | \ % ininitive
  $e$       $n$     $n$     p      $n$    $n$     $n$   $e$     $e$      $e$ | \ % participle
  $e$       $e$     $e$     [du]   $e$    $e$     $n$   $e$     $e$      $e$ | \ % gerund & supine
  $e$       $n$     $e$     g      $e$    $n$     $n$   $e$     $e$      $e$ | \ % gerundive
  $n$       $n$     $n$     [ismo] $n$    $e$     $e$   $e$     $e$      $e$   \ % finite forms
)

$tags$ = ( \
  P [pskt]  $personal_pronominal$ | \
  P [rdcix] $nominal$             | \
  M [ao]    $nominal$             | \
  M g       $indeclinable$        | \
  N [be]    $nominal$             | \
  N [jh]    $indeclinable$        | \
  V \-      $verb$                | \
  A \-      $adjective$           | \
  S \-      $nominal$             | \
  D f       $comparable_adverb$   | \
  D [nqu]   $indeclinable$        | \
  [RCGFI] \- $indeclinable$         \
)

$feature_mapping$ || $any$ || $tags$
