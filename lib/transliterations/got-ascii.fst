%
% got-ascii.fst - Dumb ASCII (non-deterministic) transliteration for Gothic
%
% This transliteration maps all characters in the standard transliteration of
% Gothic to themselves, but also adds mappings between ASCII sequences and 
% the non-ASCII characters used, e.g. þ → þ and th → th, þ.
%
% Written by Marius L. Jøhndal, 2008
%
$upper_case$ = ( \
  [ABGDEQZHÞIÏKLMNJUPRSTWFXǶO] | \
  {Þ}:{TH} | \
  {Þ}:{Th} | \
  {Ï}:{I}  | \
  {Ƕ}:{HW} | \
  {Ƕ}:{Hw} | \
  {Ū}:{U}    \     % phil.
)

$lower_case$ = ( \
  [abgdeqzhþiïklmnjuprstwfxƕo] | \
  {þ}:{th} | \
  {ï}:{i}  | \
  {ƕ}:{hw} | \
  {ū}:{u}    \     % phil.
)

$punctuation$ = ( \
  [\-,:;\.\?\!]   \
)

($upper_case$ | $lower_case$ | $punctuation$)+
