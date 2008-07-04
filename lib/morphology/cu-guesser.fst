%
% cu-guesser.fst - Stem guesser for Old Church Slavonic
%
% Written by Marius L. Jøhndal, 2008.
%

#consonants1# = sšzž
#consonants2# = ptkcčxbdgZ
#consonants3# = vmn
#consonants4# = lr
#consonants5# = j

#unvoiced# = sšptkcčxfT
#voiced#   = zžbdgZvmnlrjG

#velars#   = kgx

#front#    = iĭeęě
% FIXME: where does ü belong?
#back#     = aouŭyǫü

% FIXME: what about GfT?
#consonants# = #consonants1# #consonants2# #consonants3# #consonants4# #consonants5# GfT
#vowels# = #front# #back#

#letters# = #vowels# #consonants#

ALPHABET = [#consonants# #vowels#]

% Voiced goes with voiced for the first two
$voicing-filter$ = [#unvoiced#] [#unvoiced#] | [#voiced#] [#voiced#]

$initial-consonants$ = [#consonants1#] | [#consonants2#] | [#consonants1#] [#consonants2#] & $voicing-filter$

% `j' can only follow `l', `r' or `n' (or be alone).
$lrn-j-filter$ = (.* [lrn] j | j | (.* [^j]))?

$consonant-cluster$ = ($initial-consonants$? [#consonants3#]? [#consonants4#]? [#consonants5#]?) & $lrn-j-filter$

% s, z do not occur if there is a j in the cluster
$sz-j-removal$ = [sz] .* j [#vowels#]

% Front vowels do not occur after velars
$velar-V-removal$ = .* [#velars#] [#front#]

% y and jers do not occur initially
$initial-V-removal$ = [ĭŭy] .*

% o, y, ě and ŭ do not occur after š, ž, č, št, žd, j
$softC-V-removal$ = .* ([šžčj] | št | žd) [oyěŭ]

% o, y, ŭ do not occur after c, Z
$softC2-V-removal$ = .* [cZ] [oyŭ]

$syllable-pattern$ = ($consonant-cluster$ [#vowels#]) \
  - $sz-j-removal$ - $velar-V-removal$ - $initial-V-removal$ - $softC-V-removal$ - $softC2-V-removal$

% There is one exception: the adverbial suffix `-gda'
$any-syllable$ = $syllable-pattern$ | gda

% y and jers do not occur after another vowel
$sequence-V-removal$ = .* [#vowels#] [ĭŭy] .*

% Repeat ad nauseam
$any-root$ = ($any-syllable$+) - $sequence-V-removal$

$any-root$
