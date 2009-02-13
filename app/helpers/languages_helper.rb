module LanguagesHelper
  # Creates a table view of a collection of languages.
  def languages_table(languages)
    render_tabular languages, [ 'ISO code', 'ISO name', '&nbsp;' ]
  end

  # Returns a link to a language.
  def link_to_language(language)
    link_to language.name, language
  end

  # Returns a link to an array of languages.
  def link_to_languages(languages)
    languages.map { |l| link_to_language(l) }.to_sentence
  end
end
