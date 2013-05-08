class AddCodeToSources < ActiveRecord::Migration
  def up
    add_column :sources, :code, :string, :limit => 32, :null => false

    Source.all.each do |s|
      if s.citation_part.blank?
        s.update_attributes! :code => s.id.to_s
      else
        s.update_attributes! :code => s.citation_part.downcase.gsub(/[^\w]+/, '-').sub(/-$/, '')
      end
    end
  end

  def down
    remove_column :sources, :code
  end
end
