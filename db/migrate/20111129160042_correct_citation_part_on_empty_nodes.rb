class CorrectCitationPartOnEmptyNodes < ActiveRecord::Migration
  def up
    Token.where("empty_token_sort IS NOT NULL").find_each do |t|
      h = t.find_dependency_ancestor { |h| not h.is_empty? }
      execute("UPDATE tokens SET citation_part = '#{h.citation_part}' WHERE id = #{t.id}") if h
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
