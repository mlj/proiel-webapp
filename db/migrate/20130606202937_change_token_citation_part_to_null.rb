class ChangeTokenCitationPartToNull < ActiveRecord::Migration
  def up
    change_column :tokens, :citation_part, :string, :limit => 64, :default => nil, :null => true

    Token.where(:citation_part => '').update_all(:citation_part => nil)
  end

  def down
    change_column :tokens, :citation_part, :string, :limit => 64, :default => '', :null => false
  end
end
