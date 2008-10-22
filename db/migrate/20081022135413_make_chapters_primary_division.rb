class MakeChaptersPrimaryDivision < ActiveRecord::Migration
  def self.up
    SourceDivision.all.each do |sd|
      sd.sentences.map(&:chapter).uniq.each do |chapter|
        new_sd = sd.source.source_divisions.create(:title => "#{sd.title} #{chapter}",
                                                   :abbreviated_title => "#{sd.abbreviated_title} #{chapter}",
                                                   :fields => "#{sd.fields},chapter=#{chapter}",
                                                   :position => sd.source.source_divisions.count + 1)

        execute("UPDATE sentences SET source_division_id = #{new_sd.id} WHERE source_division_id = #{sd.id} AND chapter = #{chapter}")
      end
    end

    SourceDivision.all.select { |sd| sd.sentences.empty? }.each { |sd| sd.destroy }

    remove_column :sentences, :chapter
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
