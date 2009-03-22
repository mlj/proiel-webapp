class FixNonNumericChapterReferences < ActiveRecord::Migration
  def self.up
    ['fields'].each do |field|
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, '=0', '=Incipit') WHERE source_divisions.#{field} LIKE '%=0'");
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, '=255', '=Explicit') WHERE source_divisions.#{field} LIKE '%=255'");
    end
    ['title', 'abbreviated_title'].each do |field|
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, ' 0', ' Incipit') WHERE source_divisions.#{field} LIKE '% 0'");
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, ' 255', ' Explicit') WHERE source_divisions.#{field} LIKE '% 255'");
    end
  end

  def self.down
    ['fields'].each do |field|
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, '=Incipit', '=0') WHERE source_divisions.#{field} LIKE '%=Incipit'");
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, '=Explicit', '=255') WHERE source_divisions.#{field} LIKE '%=Explicit'");
    end
    ['title', 'abbreviated_title'].each do |field|
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, ' Incipit', ' 0') WHERE source_divisions.#{field} LIKE '% Incipit'");
      execute("UPDATE source_divisions SET source_divisions.#{field} = replace(source_divisions.#{field}, ' Explicit', ' 255') WHERE source_divisions.#{field} LIKE '% Explicit'");
    end
  end
end
