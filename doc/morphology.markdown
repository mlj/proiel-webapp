% Morphology

Part of speech vs. morphology
=============================

_Part of speech_ consists of the +morphtag+ fields +major+ and
+minor+. The remaining morphtag fields form part of the _morphology_.
As for the +inflection+ field there are arguments in favour of
treating this both as part of the part of speech and as part of the
morphology. In keeping with the philosophy that each unique (_lemma_,
_part of speech_) pair should be a unique lemma, it may make sense to
assign inflecting and non-inflecting forms to different lemmata as
well when these behave differently, but there are also legitimate
cases where forms of a lemma for no apparent reason remain uninflected
in certain situations. By treating the +inflection+ field as part of
part of speech, we would force unique lemmata for each combination,
but by treating it as part of the morphology, both options remain
open.

Remarks on individual languages
===============================

Latin
-----

### Future imperative

For lack of a more appropriate label, we employ the traditional label _future imperative_ for forms
such as _estote_ and _scitote_.

### Locative

The locative is not a legal value for the case attribute in Latin. Instances traditionally classified
as locatives should instead be annotated as genitives or ablatives. Petrified locatives such as
_ruri_ should be treated as adverbs.

Old Church Slavonic
-------------------

### Marginal tenses

The forms _bǫdǫ_, _bǫdeši_, … are annotated as futures; _bimъ_, _bi_, … as subjunctives.
