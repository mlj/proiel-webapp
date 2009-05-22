class AddRulesToInflections < ActiveRecord::Migration
  def self.up
  #  add_column :inflections, :manual_rule, :boolean, :default => false, :null => false

    %W{lat got grc chu}.each do |language_code|
      language = Language.find_by_iso_code(language_code)

      File.open("db/migrate/#{language_code}-rules.csv") do |f|
        f.each_line do |l|
          l.chomp!
          dummy_language_code, base_form, variant, form, morphtag = l.split(',')
          lemma = variant.blank? ? base_form : [base_form, variant].join('#')
          morphtag = morphtag.ljust(13, '-')

          if o = language.inflections.find_by_form_and_morphtag_and_lemma(form, morphtag, lemma)
            STDERR.puts "Upgrading an existing inflection to a manual rule" unless o.manual_rule
            o.manual_rule = true
            o.save_without_validation!
          else
            i = language.inflections.new :form => form, :morphtag => morphtag, :lemma => lemma,
              :manual_rule => true
            i.save_without_validation!
          end
        end
      end
    end
  end

  def self.down
    remove_column :inflections, :manual_rule
  end
end
