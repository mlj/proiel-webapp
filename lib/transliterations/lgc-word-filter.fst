%
% lgc-word-filter.fst - A filter that constrains transliterations to intraword mappings only
%
% This filter filters transliterations to intraword mappings only using
% a strict interpretation of what constitutes a valid word: uppercase
% letter do not occur except as the first letter or if all letters
% are uppercased, and only dashes are allowed from the punctuation
% repertoire. It is intended to work with all LGC scripts
%
% Written by Marius L. Jøhndal, 2008
%
$upper_case$ = (                   \
  [ABCDEFGHIÏJKLMNOPQRSTUŪVWXYZÞǶ] \
)

$lower_case$ = (                   \
  [abcdefghiïjklmnopqrstuūvwxyzþƕ] \
)

$punctuation$ = ( \
  [\-]            \
)

($lower_case$ (($lower_case$ | $punctuation$)* $lower_case$)?) | \
($upper_case$ (($lower_case$ | $punctuation$)* $lower_case$)?) | \
($upper_case$ (($upper_case$ | $punctuation$)* $upper_case$)?)
