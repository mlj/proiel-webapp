%
% grc-simple.fst - Simple linguistic transliteration for Ancient Greek
%
% This transliterator requires the upper level to be decomposed. The diacritic
% sequence is <base character, breathing, accent, diaeresis, length>.
%
% FIXME: the sequence here may not match canonical decomposition
%
% Written by Marius Jøhndal 2008, Dag Haug 2011
%
#oxia# =  ́
#varia# =  ̀
#persipomeni# = ͂

$breathings$ =        (̓:<> | \ 
	     	      ̔:h \
		      )
$short-accents$ =      [#oxia# #varia#              ]:<>
$long-accents$ =       [#oxia#         #persipomeni#]:<>
$short-long-accents$ = [#oxia# #varia# #persipomeni#]:<>

$iota-subscript$ = {ͅ}:i

$upper-case$ = ( \
  ({Α}:{A} $breathings$?) | \
  {Ἃ}:{Ha} | \
  {Ἄ}:{A} | \
  {Ἇ}:{Ha} | \
  {Ἆ}:{\^A} | \
  {Β}:{B} | \
  {Γ}:{G} | \
  {Δ}:{D} | \
  ({Ε}:{E} $breathings$?) | \
  {Ἓ}:{E} | \
  {Ἔ}:{E} | \
  {Ζ}:{Z} | \
  ({Η}:{\^E} $breathings$?) | \
  {Ἢ}:{E} | \
  {Ἤ}:{H\^e} | \
  {Ἦ}:{E} | \
  {Ἧ}:{H\^e} | \
  {Θ}:{Th} | \
  {Θ}:{TH} | \
  ({Ι}:{I} $breathings$?) | \
  {Ἴ}:{I} | \
  {Ἷ}:{Hi} | \
  {Κ}:{K} | \
  {Λ}:{L} | \
  {Μ}:{M} | \
  {Ν}:{N} | \
  {Ξ}:{Ks} | \
  {Ξ}:{KS} | \
  ({Ο}:{O} $breathings$?) | \
  {Ὃ}:{O} | \
  {Ὄ}:{Ho} | \
  {Π}:{P} | \
  {Ρ}:{R} | \
  {Ῥ}:{R} | \
  {Σ}:{S} | \
  {Τ}:{T} | \
  {Υ}:{U} | \
  {Ὑ}:{Hu} | \
  {Ὕ}:{u} | \
  {Ὗ}:{H} | \
  {Φ}:{F} | \
  {Χ}:{X} | \
  {Ψ}:{Ps} | \
  {Ψ}:{PS} | \
  ({Ω}:{\^o} $breathings$?) | \
  {Ὤ}:{H\^o} | \
  {Ὧ}:{H\^o} | \
  {Ὦ}:{O} \
)

$lower-case$ = ( \
  ({α}:{a} $breathings$? $short-long-accents$? $iota-subscript$?) | \
  {β}:{b} | \
  {γ}:{g} | \
  {δ}:{d} | \
  ({ε}:{e} $breathings$? $short-accents$?) | \
  {ζ}:{z} | \
  ({η}:{\^e} $breathings$? $short-long-accents$? $iota-subscript$?) | \
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
  {φ}:{ph} | \
  {χ}:{kh} | \
  {ψ}:{ps} | \
  ({ω}:{\^o} $breathings$? $short-long-accents$? $iota-subscript$?) | \
  ({ϊ}:{i} $short-accents$?) | \
  ({ϋ}:{u} $short-accents$?) | \
  {ᾄ}:{\^ai} | \
  {ᾅ}:{h\^ai} | \
  {ᾐ}:{\^ei} | \
  {ᾑ}:{h\^ei} | \
  {ᾔ}:{\^ei} | \
  {ᾖ}:{\^ei} | \
  {ᾗ}:{h\^ei} | \
  {ᾠ}:{\^oi} | \
  {ᾧ}:{h\^oi} | \
  {ῤ}:{r}  \
)


$lower-case-medial$ = $lower-case$ | {σ}:{s}

$lower-case-final$ = $lower-case$ | {ς}:{s}

$punctuation$ = [\.,·]

($upper-case$ | $lower-case-medial$ | $lower-case-final$ | $punctuation$)+ 
