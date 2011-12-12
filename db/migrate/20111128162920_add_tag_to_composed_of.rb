class AddTagToComposedOf < ActiveRecord::Migration
  def change
    change_table :inflections do |t|
      t.rename :morphology, :morphology_tag
      t.rename :language, :language_tag
    end

    change_table :sources do |t|
      t.rename :language, :language_tag
    end

    change_table :tokens do |t|
      t.rename :morphology, :morphology_tag
    end

    change_table :lemmata do |t|
      t.rename :part_of_speech, :part_of_speech_tag
      t.rename :language, :language_tag
    end
  end
end
