class FixNonNumericChapterReferences < ActiveRecord::Migration
  def self.up
    ['fields'].each do |field|
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, '=0', '=Incipit') WHERE #{field} LIKE '%=0'");
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, '=255', '=Explicit') WHERE #{field} LIKE '%=255'");
    end
    ['title', 'abbreviated_title'].each do |field|
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, ' 0', ' Incipit') WHERE #{field} LIKE '% 0'");
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, ' 255', ' Explicit') WHERE #{field} LIKE '% 255'");
    end
  end

  def self.down
    ['fields'].each do |field|
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, '=Incipit', '=0') WHERE #{field} LIKE '%=Incipit'");
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, '=Explicit', '=255') WHERE #{field} LIKE '%=Explicit'");
    end
    ['title', 'abbreviated_title'].each do |field|
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, ' Incipit', ' 0') WHERE #{field} LIKE '% Incipit'");
      execute("UPDATE source_divisions SET #{field} = replace(#{field}, ' Explicit', ' 255') WHERE #{field} LIKE '% Explicit'");
    end
  end
end
