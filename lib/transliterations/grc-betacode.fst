%
% grc-betacode.fst - Betacode (non-deterministic) transliteration for Ancient Greek
%
% This transliteration follows the informal description of Betacode given in
% the English Wikipedia (http://en.wikipedia.org/wiki/Beta_code) with the
% following adjustments
%
%  - *S1 and *S2 are accepted for upper case sigma, for the sake of symmetry.
%  - Lunate sigma can only be produced using the (deprecated) S3 code.
%
% In addition, based on the German Wikipedia (http://de.wikipedia.org/wiki/Betacode),
% this transliterator supports the input of final sigma and upper case sigma
% using `j'.
%
% Finally, the modifiers have to be input in a specific sequence:
%   1. *
%   2. Base character
%   3. Diaeresis
%   4. Breathing
%   5. Accent
%   6. Iota subscript
%   7. Length
%
% This transliterator requires the upper level to be decomposed. The diacritic
% sequence is <base character, breathing, accent, diaeresis, length>.
%
% FIXME: the sequence here may not match canonical decomposition
%
% FIXME: The transliterator does not handle punctuation, hyphenation or spacing, except
% the ' which is part of some words, but 
% does handle medial/final disambiguation. This does not quite fit with the overall
% design of the other transliterators here.
%
% Written by Marius L. Jøhndal, 2008
%
$upper-case$ = ( \
  {Α}:{a} | \
  {Β}:{b} | \
  {Γ}:{g} | \
  {Δ}:{d} | \
  {Ε}:{e} | \
  {Ζ}:{z} | \
  {Η}:{h} | \
  {Θ}:{q} | \
  {Ι}:{i} | \
  {Κ}:{k} | \
  {Λ}:{l} | \
  {Μ}:{m} | \
  {Ν}:{n} | \
  {Ξ}:{c} | \
  {Ο}:{o} | \
  {Π}:{p} | \
  {Ρ}:{r} | \
  {Σ}:{s} | \
  {Σ}:{s1} | \
  {Σ}:{s2} | \
  {Ϲ}:{s3} | \
  {Σ}:{j} | \
  {Τ}:{t} | \
  {Υ}:{u} | \
  {Φ}:{f} | \
  {Χ}:{x} | \
  {Ψ}:{y} | \
  {Ω}:{w}   \
)

$lower-case$ = ( \
  {α}:{a} | \
  {β}:{b} | \
  {γ}:{g} | \
  {δ}:{d} | \
  {ε}:{e} | \
  {ζ}:{z} | \
  {η}:{h} | \
  {θ}:{q} | \
  {ι}:{i} | \
  {κ}:{k} | \
  {λ}:{l} | \
  {μ}:{m} | \
  {ν}:{n} | \
  {ξ}:{c} | \
  {ο}:{o} | \
  {π}:{p} | \
  {ρ}:{r} | \
  {σ}:{s1} | \
  {ς}:{s2} | \
  {ϲ}:{s3} | \
  {ς}:{j} | \
  {τ}:{t} | \
  {υ}:{u} | \
  {φ}:{f} | \
  {χ}:{x} | \
  {ψ}:{y} | \
  {ω}:{w}   \
)

$medial-lower-case$ = $lower-case$ | {σ}:{s}
$final-lower-case$  = $lower-case$ | {ς}:{s}

$medial-base-letters$ = ({}:{\*} $upper-case$) | $medial-lower-case$
$final-base-letters$  = ({}:{\*} $upper-case$) | $final-lower-case$

$breathings$ = {̓}:{\)} | {̔}:{\(}
$accents$    = {́}:{/}  | {̀}:{\\} | {͂}:{\=}
$iota-subscript$ = {ͅ}:{\|}
$diaeresis$  = {̈}:{\+}
$quantity$   = {̄}: {\%26} | {̆}: {\%27}
$diacritics$ = $diaeresis$? $breathings$? $accents$? $iota-subscript$? $quantity$?

$medials$ = $medial-base-letters$ $diacritics$
$finals$  = $final-base-letters$  $diacritics$

$all$ = $medials$* $finals$ ({'}:{'})?

ALPHABET = [abgdezhqiklmncoprsjtufxyw12367\*\)\(/\\\=\|\+\:;\?\%']
$ascii-to-lower$ = [abgdezhqiklmncoprsjtufxyw]:[ABGDEZHQIKLMNCOPRSJTUFXYW] | .*

$word$ = $all$ || $ascii-to-lower$+

$punctuation$ = [\.,:;†—\?!']
($punctuation$)* $word$ ($punctuation$)*
