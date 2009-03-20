class CreateInflections < ActiveRecord::Migration
  def self.up
    create_table :inflections, :options => 'DEFAULT CHARSET=UTF8' do |t|
      t.references :language, :null => false
      t.string :form, :null => false, :limit => 64
      t.string :morphtag, :null => false, :limit => 17
      t.string :lemma, :null => false, :limit => 64
      t.timestamps
    end

    add_index :inflections, [:language_id, :form]
    add_index :inflections, [:language_id, :form, :morphtag, :lemma], :unique => true

    # Load existing data
    [:la, :got].each do |iso_code|
      csv_file_name = "db/migrate/#{iso_code}-generated.csv"

      language = Language.find_by_iso_code(iso_code)

      File.open(csv_file_name) do |f|
        f.each_line do |l|
          language_code, lemma, variant, form, *morphtags = l.chomp.split(',')
          raise "invalid language code in rule file" unless iso_code.to_s == language_code

          morphtags = morphtags.map { |morphtag| PROIEL::MorphTag.new(morphtag) }
          raise "invalid morphtag for form #{form} in rule file" unless morphtags.all? { |m| m.is_valid?(iso_code) }

          morphtags.map(&:to_s).each do |morphtag|
            i = language.inflections.new(:morphtag => morphtag,
                                         :form => form,
                                         :lemma => variant.blank? ? lemma : "#{lemma}##{variant}")
            i.save_without_validation! # we may have different constraints obey by the time we migrate
          end
        end
      end
    end
  end

  def self.down
    drop_table :inflections
  end
end
