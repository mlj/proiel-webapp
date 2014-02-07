class AddPartOfSpeechTagToInflections < ActiveRecord::Migration
  def up
    add_column :inflections, :part_of_speech_tag, :string, limit: 2, null: false

    remove_index :inflections, name: :idx_inflections_lfml

    Inflection.all.each do |i|
      lemma, part_of_speech_tag = i.lemma.split(',')
      i.update_attributes! lemma: lemma, part_of_speech_tag: part_of_speech_tag
    end

    add_index :inflections, %w(language_tag form morphology_tag lemma part_of_speech_tag), name: :idx_infl_unique, unique: true
  end

  def down
    remove_index :inflections, :idx_infl_unique

    Inflection.all.each do |i|
      i.update_attributes! lemma: [i.lemma, i.part_of_speech_tag].join(',')
    end

    add_index :inflections, %w(language_tag form morphology_tag lemma), name: :idx_inflections_lfml, unique: true

    remove_column :inflections, :part_of_speech_tag
  end
end
