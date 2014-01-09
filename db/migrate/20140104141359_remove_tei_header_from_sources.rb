class RemoveTeiHeaderFromSources < ActiveRecord::Migration
  def up
    unless ENV['I_HAVE_SAVED_MY_DATA']
      puts "This migration deletes all TEI headers from the database. Set the"
      puts "environment variable I_HAVE_SAVED_MY_DATA and run the migration again."
      raise
    end

    remove_column :sources, :tei_header
  end

  def down
    add_column :sources, :tei_header, :text, :null => false
  end
end
