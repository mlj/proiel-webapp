class CreateMorphologies < ActiveRecord::Migration
  MORPHOLOGY_SUMMARIES = {
    :person => {
      '1' => "first person",
      '2' => "second person",
      '3' => "third person",
    },
    :number => {
      's' => 'singular',
      'd' => 'dual',
      'p' => 'plural',
    },
    :tense => {
      'p' => 'present',
      'i' => 'imperfect',
      'l' => 'pluperfect',
      'a' => 'aorist',
      'f' => 'future',
      'r' => 'perfect',
      't' => 'future perfect',
      's' => 'resultative',
      'u' => 'past',
    },
    :mood => {
      'i' => 'indicative',
      's' => 'subjunctive',
      'm' => 'imperative',
      'o' => 'optative',

      'n' => 'infinitive',
      'p' => 'participle',
      'd' => 'gerund',
      'g' => 'gerundive',
      'u' => 'supine',
    },
    :voice => {
      'a' => 'active',
      'e' => 'middle or passive',
      'm' => 'middle',
      'p' => 'passive',
    },
    :gender => {
      'o' => 'masculine or neuter',
      'p' => 'masculine or feminine',
      'q' => 'masculine, feminine or neuter',
      'r' => 'feminine or neuter',

      'm' => 'masculine',
      'f' => 'feminine',
      'n' => 'neuter',
    },
    :case => {
      'n' => 'nominative',
      'v' => 'vocative',
      'a' => 'accusative',
      'g' => 'genitive',
      'd' => 'dative',
      'b' => 'ablative',
      'i' => 'instrumental',
      'l' => 'locative',

      'c' => 'genitive or dative',
    },
    :degree => {
      'p' => 'positive',
      'c' => 'comparative',
      's' => 'superlative',
    },
    :animacy => {
      'i' => 'inanimate',
      'a' => 'animate',
    },
    :strength => {
      'w' => 'weak',
      's' => 'strong',
      't' => 'weak or strong',
    },
    :inflection => {
      'i' => 'inflecting',
      'n' => 'non-inflecting',
    }
  }

  MORPHOLOGY_ABBREVIATED_SUMMARIES = {
    :person => {
      '1' => "1st p.",
      '2' => "2nd p.",
      '3' => "3rd p.",
    },
    :number => {
      's' => 'sg.',
      'd' => 'du.',
      'p' => 'pl.',
    },
    :tense => {
      'p' => 'pres.',
      'i' => 'imperf.',
      'l' => 'ppf.',
      'a' => 'aor.',
      'f' => 'fut.',
      'r' => 'perf.',
      't' => 'fut. perf.',
      's' => 'result.',
      'u' => 'past',
    },
    :mood => {
      'i' => 'ind.',
      's' => 'subj.',
      'm' => 'imp.',
      'o' => 'opt.',

      'n' => 'inf.',
      'p' => 'part.',
      'd' => 'gerund',
      'g' => 'gerundive',
      'u' => 'sup.',
    },
    :voice => {
      'a' => 'act.',
      'e' => 'mid./pass.',
      'm' => 'mid.',
      'p' => 'pass.',
    },
    :gender => {
      'o' => 'm./n.',
      'p' => 'm./f.',
      'q' => 'm./f./n.',
      'r' => 'f./n.',

      'm' => 'm.',
      'f' => 'f.',
      'n' => 'n.',
    },
    :case => {
      'n' => 'nom.',
      'v' => 'voc.',
      'a' => 'acc.',
      'g' => 'gen.',
      'd' => 'dat.',
      'b' => 'abl.',
      'i' => 'ins.',
      'l' => 'loc.',

      'c' => 'gen./dat.',
    },
    :degree => {
      'p' => 'pos.',
      'c' => 'comp.',
      's' => 'sup.',
    },
    :animacy => {
      'i' => 'inanim.',
      'a' => 'anim.',
    },
    :strength => {
      'w' => 'weak',
      's' => 'strong',
      't' => 'weak/strong',
    },
    :inflection => {
      'i' => 'infl.',
      'n' => 'non-infl.',
    }
  }

  def self.morphology_summary(tag)
    h = Hash[*MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.zip(tag.split('')).flatten]

    MorphFeatures::MORPHOLOGY_PRESENTATION_SEQUENCE.map do |field|
      next if field == :inflection and h[field] == 'i'
      h[field] == '-' ? nil : MORPHOLOGY_SUMMARIES[field][h[field]]
    end.compact.join(', ')
  end

  def self.morphology_abbreviated_summary(tag)
    h = Hash[*MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.zip(tag.split('')).flatten]

    MorphFeatures::MORPHOLOGY_PRESENTATION_SEQUENCE.map do |field|
      next if field == :inflection and h[field] == 'i'
      h[field] == '-' ? nil : MORPHOLOGY_ABBREVIATED_SUMMARIES[field][h[field]]
    end.compact.join(', ')
  end

  def self.up
    create_table :morphologies do |t|
      t.string "tag", :limit => 11, :null => false
      t.string "summary", :limit => 128, :null => false
      t.string "abbreviated_summary", :limit => 64, :null => false
    end

    rename_column :tokens, :morphology, :old_morphology
    rename_column :inflections, :morphology, :old_morphology

    add_column :tokens, :morphology_id, :integer
    add_column :inflections, :morphology_id, :integer, :null => false

    add_index "inflections", ["old_morphology"]

    add_index "inflections", ["morphology_id"]
    add_index "tokens", ["morphology_id"]

    Token.reset_column_information
    Inflection.reset_column_information
    Morphology.reset_column_information

    Token.disable_auditing

    Language.all.map { |language| MorphFeatures.pos_and_morphology_tag_space(language.iso_code).values }.flatten.sort.uniq.each do |tag|
      # FIXME: WTF?
      next if tag == '----------i'
      Morphology.create! :tag => tag, :summary => self.morphology_summary(tag), :abbreviated_summary => self.morphology_abbreviated_summary(tag)
    end

    Morphology.find_each do |m|
      execute("UPDATE tokens SET morphology_id = '#{m.id}' WHERE old_morphology = '#{m.tag}'")
      execute("UPDATE inflections SET morphology_id = '#{m.id}' WHERE old_morphology = '#{m.tag}'")
    end

    n = Token.count(:conditions => ["old_morphology is not null and morphology_id is null"])
    raise "#{n} tokens with invalid/unknown morphology" unless n.zero?

    n = Inflection.count(:conditions => ["morphology_id is null"])
    raise "#{n} inflections with invalid/unknown morphology" unless n.zero?

    remove_column :tokens, :old_morphology
    remove_index "inflections", :name => "index_inflections_on_language_id_and_form_and_morphtag_and_lemma"
    remove_column :inflections, :old_morphology

    add_index :morphologies, ["tag"], :unique => true
    add_index "inflections", ["language_id", "form", "morphology_id", "lemma"], :name => "index_inflections_on_language_and_form_and_morphology_and_lemma", :unique => true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
