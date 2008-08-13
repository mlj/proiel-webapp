# Language support
# ================

# Supported languages in the application.
#
# This should be an array of ISO 639-3 (FIXME: this is a mix of old and new currently!) language 
# codes (as symbols) for each language that the application should handle.
SUPPORTED_LANGUAGES = [:cu, :got, :grc, :lat, :hy]

TRANSLITERATORS = {
  :cu  => 'cu-ascii',
  :got => 'got-ascii-word',
  :grc => 'grc-betacode',
}

# Unicode settings
# ================

# Unicode normalization form for normalised text columns. Choices are :kc, :c, :kd, :d
# (see http://unicode.org/reports/tr15/ for details). The default choice is :c, and it is
# recommended that you stick with that unless you have good reasons not to. If you do change
# it, remeber to take into consideration how your database engine deals with queries that
# contain sequences of potentially decomposed characters.
UNICODE_NORMALIZATION_FORM = :c
