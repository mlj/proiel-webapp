# Language support
# ================

# Supported languages in the application.
#
# This should be an array of ISO 639-3 language
# codes (as symbols) for each language that the application should handle.
SUPPORTED_LANGUAGES = [:chu, :got, :grc, :lat, :xcl, :orv]

TRANSLITERATORS = {
  :chu => 'chu-ascii',
  :got => 'got-ascii-word',
  :grc => 'grc-betacode',
  :orv => 'orv-ascii',
}
