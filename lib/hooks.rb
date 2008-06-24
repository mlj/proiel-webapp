# Set up the tagger
TAGGER_CONFIG_FILE = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'proiel', 'tagger.yml')
TAGGER_DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'morphology')

TAGGER = PROIEL::Tagger::Tagger.new(TAGGER_CONFIG_FILE,
                            :data_directory => TAGGER_DATA_PATH,
                            :logger => RAILS_DEFAULT_LOGGER, 
                            :statistics_retriever => lambda { |language, form|
  source = Source.find_by_language(language)
  result = Token.connection.select_all("SELECT morphtag, lemmata.lemma, lemmata.variant, count(*) AS frequency FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id LEFT JOIN lemmata ON lemma_id = lemmata.id WHERE form = \"#{form}\" AND source_id = #{source.id} AND reviewed_by IS NOT NULL GROUP BY morphtag, lemma_id", 'Token')
  result.collect! do |e|
    [e["morphtag"],
     e["lemma"] ? (e["variant"] ? [e["lemma"], e["variant"]].join('#') : e["lemma"]) : nil,
     e["frequency"].to_i]
  end

  result
})
