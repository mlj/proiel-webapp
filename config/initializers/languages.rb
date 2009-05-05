# Language support
# ================

# Supported languages in the application.
#
# This should be an array of ISO 639-3 (FIXME: this is a mix of old and new currently!) language 
# codes (as symbols) for each language that the application should handle.
SUPPORTED_LANGUAGES = [:cu, :got, :grc, :lat, :xcl]

TRANSLITERATORS = {
  :cu  => 'cu-ascii',
  :got => 'got-ascii-word',
  :grc => 'grc-betacode',
}
