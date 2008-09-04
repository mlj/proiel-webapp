module LanguagesHelper
  # Returns a link to a language.
  def link_to_language(language)
    link_to language.name, language
  end

  # Returns a link to an array of languages.
  def link_to_languages(languages)
    languages.map { |l| link_to_language(l) }.to_sentence
  end
end
