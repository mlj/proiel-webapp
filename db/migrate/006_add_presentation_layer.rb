class AddPresentationLayer < ActiveRecord::Migration
  def self.up
    add_column :tokens, :contraction, :boolean, :null => false, :default => false
    add_column :tokens, :nospacing, :enum, :null => true, :limit => [:before, :after, :both]
    add_column :tokens, :presentation_form, :string, :null => true, :limit => 128
    add_column :tokens, :presentation_span, :integer, :null => true
    add_column :tokens, :emendation, :boolean, :null => false, :default => false
    add_column :tokens, :abbreviation, :boolean, :null => false, :default => false
    add_column :tokens, :capitalisation, :boolean, :null => false, :default => false
    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end, :word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation, :spacing_punctuation, :left_bracketing_punctuation, :right_bracketing_punctuation], :default     => :word, :null => false

    swap_tokens = []

    # Do this directly using SQL otherwise it will take forever.
    ActiveRecord::Base.connection.execute('UPDATE tokens SET sort = "text" WHERE sort = "word"')
    ActiveRecord::Base.connection.execute('UPDATE tokens SET sort = "empty_dependency_token" WHERE sort = "empty"')
    ActiveRecord::Base.connection.execute('UPDATE tokens SET nospacing = "before" WHERE sort = "nonspacing_punctuation"')
    ActiveRecord::Base.connection.execute('UPDATE tokens SET nospacing = "before" WHERE sort = "right_bracketing_punctuation"')
    ActiveRecord::Base.connection.execute('UPDATE tokens SET nospacing = "after" WHERE sort = "left_bracketing_punctuation"')
    ActiveRecord::Base.connection.execute('UPDATE tokens SET sort = "punctuation" WHERE sort IN ("nonspacing_punctuation", "right_bracketing_punctuation", "spacing_punctuation", "left_bracketing_punctuation")')

    Token.transaction do
      Token.find(:all, :order => "sentence_id, token_number",
                       :conditions => ["sort in ('fused_morpheme', 'enclitic')"]).each do |t|
        case t.sort
        when :fused_morpheme
          previous = t.previous_token
          unless previous
            STDERR.puts "I'm confused: #{t.id}: fused_morpheme has no previous_token!"
            next
          end

          previous.presentation_form = t.composed_form
          previous.presentation_span = 2
          previous.contraction = true
          previous.without_auditing { previous.save_with_validation(false) }

          t.sort = :text
          t.without_auditing { t.save_with_validation(false) }

        when :enclitic
          nxt = t.next_token
          unless nxt
            STDERR.puts "I'm confused: #{t.id}: enclitic has no next_token!"
            next
          end

          nxt.presentation_form = nxt.form + t.form
          swap_tokens << t.id
          nxt.presentation_span = 2
          nxt.contraction = true
          nxt.without_auditing { nxt.save_with_validation(false) }

          t.sort = :text
          t.without_auditing { t.save_with_validation(false) }
        end
      end

      swap_tokens.each do |token_id|
        t = Token.find(token_id)
        nxt = t.next_token

        # This silly twist avoids duplicate keys
        nxt.token_number, original_t_token_number, t.token_number = 99999999, t.token_number, nxt.token_number
        nxt.without_auditing { nxt.save_with_validation(false) }
        t.without_auditing { t.save_with_validation(false) }

        nxt.token_number = original_t_token_number
        nxt.without_auditing { nxt.save_with_validation(false) }
      end
    end

    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end], :default     => :text, :null => false
    remove_column :tokens, :composed_form
  end

  def self.down
    change_column :tokens, :sort, :enum, :limit => [:word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation, :spacing_punctuation, :left_bracketing_punctuation, :right_bracketing_punctuation], :default     => :word, :null => false
    remove_column :tokens, :enclisis
    remove_column :tokens, :contraction
    remove_column :tokens, :emendation
    remove_column :tokens, :abbreviation
    remove_column :tokens, :capitalisation
    remove_column :tokens, :nospacing
    remove_column :tokens, :presentation_form
    remove_column :tokens, :presentation_span
  end
end
