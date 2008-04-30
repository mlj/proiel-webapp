require 'proiel'

# Singleton objects
TAGGER = PROIEL::Tagger.new(:data_directory => File.expand_path(File.dirname(__FILE__)),
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


