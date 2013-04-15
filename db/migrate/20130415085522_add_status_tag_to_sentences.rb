class AddStatusTagToSentences < ActiveRecord::Migration
  def up
    add_column :sentences, :status_tag, :string, :limit => 12, :null => false

    execute("UPDATE sentences SET status_tag = 'reviewed' WHERE reviewed_by is NOT NULL OR reviewed_at is NOT NULL")
    execute("UPDATE sentences SET status_tag = 'annotated' WHERE (status_tag is NULL OR status_tag = '') AND (annotated_by is NOT NULL OR annotated_at is NOT NULL)")
    execute("UPDATE sentences SET status_tag = 'unannotated' WHERE status_tag is NULL OR status_tag = ''")

    add_index :sentences, ["status_tag"], :name => "index_tokens_on_status_tag"
  end

  def down
    remove_column :sentences, :status_tag
  end
end
