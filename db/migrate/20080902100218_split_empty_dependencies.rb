class SplitEmptyDependencies < ActiveRecord::Migration
  def self.up
    add_column :tokens, :empty_token_sort, :string, :limit => 1, :default => nil, :null => true

    Token.reset_column_information

    Token.find(:all, :conditions => ["sort = 'empty_dependency_token'"]).each do |t|
      if t.dependents.select { |d| d.relation == t.relation }.length >= 2
        t.empty_token_sort = 'C'
      else
        t.empty_token_sort = 'V'
      end
      t.without_auditing { t.save! }
    end

    # Verify that this worked
    Token.find(:all, :conditions => ["sort = 'empty_dependency_token'"]).collect(&:sentence).uniq.each do |s|
      s.dependency_graph.nodes.each do |node|
        if node.is_empty?
          interpretation = if node.identifier == :root
                             nil
                           elsif node.dependents.select { |d| d.relation == node.relation }.size >= 2
                             'C'
                           else
                             'V'
                           end
          
          if interpretation
            raise "Mismatch #{interpretation} != #{Token.find(node.identifier).empty_token_sort}" unless Token.find(node.identifier).empty_token_sort == interpretation
          end
        end
      end
    end
  end

  def self.down
    remove_column :tokens, :empty_token_sort
  end
end
