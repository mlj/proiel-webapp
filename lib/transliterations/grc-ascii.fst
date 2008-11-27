%
% grc-ascii.fst - Dumb ASCII (non-deterministic) transliteration for Ancient Greek
%
% This transliterator requires the upper level to be decomposed. The diacritic
% sequence is <base character, breathing, accent, diaeresis, length>.
%
% FIXME: the sequence here may not match canonical decomposition
%
% Written by Marius L. Jøhndal, 2008
%
#oxia# =  ́
#varia# =  ̀
#persipomeni# = ͂

$breathings$ =         [̓  ̔]
$short-accents$ =      [#oxia# #varia#              ]
$long-accents$ =       [#oxia#         #persipomeni#]
$short-long-accents$ = [#oxia# #varia# #persipomeni#]

$upper-case$ = ( \
  ({Α}:{A} $breathings$?) | \
  {Ἃ}:{A} | \
  {Ἄ}:{A} | \
  {Ἇ}:{A} | \
  {Ἆ}:{A} | \
  {Β}:{B} | \
  {Γ}:{G} | \
  {Δ}:{D} | \
  ({Ε}:{E} $breathings$?) | \
  {Ἓ}:{E} | \
  {Ἔ}:{E} | \
  {Ζ}:{Z} | \
  ({Η}:{E} $breathings$?) | \
  {Ἢ}:{E} | \
  {Ἤ}:{E} | \
  {Ἦ}:{E} | \
  {Ἧ}:{E} | \
  {Θ}:{Th} | \
  {Θ}:{TH} | \
  ({Ι}:{I} $breathings$?) | \
  {Ἴ}:{I} | \
  {Ἷ}:{I} | \
  {Κ}:{K} | \
  {Λ}:{L} | \
  {Μ}:{M} | \
  {Ν}:{N} | \
  {Ξ}:{Ks} | \
  {Ξ}:{KS} | \
  ({Ο}:{O} $breathings$?) | \
  {Ὃ}:{O} | \
  {Ὄ}:{O} | \
  {Π}:{P} | \
  {Ρ}:{R} | \
  {Ῥ}:{R} | \
  {Σ}:{S} | \
  {Τ}:{T} | \
  {Υ}:{U} | \
  {Ὑ}:{U} | \
  {Ὕ}:{U} | \
  {Ὗ}:{U} | \
  {Φ}:{F} | \
  {Χ}:{X} | \
  {Ψ}:{Ps} | \
  {Ψ}:{PS} | \
  ({Ω}:{O} $breathings$?) | \
  {Ὤ}:{O} | \
  {Ὧ}:{O} | \
  {Ὦ}:{O} \
)

$lower-case$ = ( \
  ({α}:{a} $breathings$? $short-long-accents$?) | \
  {β}:{b} | \
  {γ}:{g} | \
  {δ}:{d} | \
  ({ε}:{e} $breathings$? $short-accents$?) | \
  {ζ}:{z} | \
  ({η}:{e} $breathings$? $short-long-accents$?) | \
  {θ}:{th} | \
  ({ι}:{i} $breathings$? $short-long-accents$?) | \
  {κ}:{k} | \
  {λ}:{l} | \
  {μ}:{m} | \
  {ν}:{n} | \
  {ξ}:{ks} | \
  ({ο}:{o} $breathings$? $short-accents$?) | \
  {π}:{p} | \
  {ρ}:{r} | \
  {τ}:{t} | \
  ({υ}:{u} $breathings$? $short-long-accents$?) | \
  {φ}:{f} | \
  {χ}:{x} | \
  {ψ}:{ps} | \
  ({ω}:{o} $breathings$? $short-long-accents$?) | \
  ({ϊ}:{i} $short-accents$?) | \
  ({ϋ}:{u} $short-accents$?) | \
  ({ᾳ}:{a} $long-accents$?) | \
  ({ῃ}:{e} $long-accents$?) | \
  ({ῳ}:{o} $long-accents$?) | \
  {ᾄ}:{a} | \
  {ᾅ}:{a} | \
  {ᾐ}:{e} | \
  {ᾑ}:{e} | \
  {ᾔ}:{e} | \
  {ᾖ}:{e} | \
  {ᾗ}:{e} | \
  {ᾠ}:{o} | \
  {ᾧ}:{o} | \
  {ῤ}:{r}  \
)

$lower-case-medial$ = $lower-case$ | {σ}:{s}

$lower-case-final$ = $lower-case$ | {ς}:{s}

$punctuation$ = [\.,·]

($upper-case$ | $lower-case-medial$ | $lower-case-final$ | $punctuation$)+
