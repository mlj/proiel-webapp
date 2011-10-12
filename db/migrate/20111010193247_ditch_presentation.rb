class DitchPresentation < ActiveRecord::Migration
    # Does not aim at completeness, but the migration will issue a warning for punctuation not mentioned here
  LEFT_ATTACHING_PUNCTUATION = ['(', '-', '“', '‘' ]
  RIGHT_ATTACHING_PUNCTUATION = [',', ';', ':', '.', '·', ')', '?', '!', '—',
                                 '⁘',
                                 'кⷰ҇',
                                 'коⷰ҇',
                                 'зⷱ҇',
                                 '჻',
                                 ' ⁘ ',
                                 '  ⁘ ⁘ ',
                                 '჻',
                                 'кц',
                                 '⁘кⷰ҇⁘',
                                 'заⷱ҇',
                                 '⁓',
                                 ':.',
                                 ':.:.',
                                 ':.:.:.',
                                 '”'

                                ]

  TAG_NAME_TO_SEMTAG_MAP = {
    'add' => 'added',
    'unclear' => 'unclear',
    'segmented' => 'segmented',
    'expan' => 'expansion',
    'corr' => 'corrected',
  }

  # saves the current token and resets the variables
  def self.save_token!
    raise "No token in #{@tokens.map(&:sentence_id).compact.uniq}" unless @tokens[@idx]
    execute("UPDATE tokens SET presentation_before = '#{@presentation_before.gsub("'") { |m| "\\'" } }',
               presentation_after = '#{@presentation_after.gsub("'") { |m| "\\'" } }' WHERE id = '#{@tokens[@idx].id}'")
    @presentation_before = ''
    @presentation_after  = ''
    @after_token = false
    @idx += 1
  end

  def self.parse_children(mother, tag = nil)
    mother.children.each do |child|
      case child.name
      when "presentation", "milestone", "del"
        # Do nothing
      when "w"
        # map any <w>-internal editorial tags to a semtag 'corrected'
        child.children.reject(&:text?).map do |e|
          case e.name
          when 'add', 'expan', 'corr', 'del'
            'corrected'
          when 'unclear'
            'unclear'
          else
            STDERR.puts "Unknown tag #{e.name} inside token #{@tokens[@idx].id}"
          end
        end.compact.uniq.each do |tag|
          SemanticTag.create!(:taggable_id => @tokens[@idx].id, :taggable_type => 'Token', :semantic_attribute_value_id => SemanticAttributeValue.find_by_tag(tag).id )
        end
        save_token! if @after_token
        unless tag.nil?
          if tag != 'endoclitic'
            SemanticTag.create!(:taggable_id => @tokens[@idx].id, :taggable_type => 'Token', :semantic_attribute_value_id => SemanticAttributeValue.find_by_tag(tag).id )
          else
            if @tokens[@idx].form.match(/\w\-\w/)
              SemanticTag.create!(:taggable_id => @tokens[@idx].id, :taggable_type => 'Token', :semantic_attribute_value_id => SemanticAttributeValue.find_by_tag('host').id )
            elsif @presentation_before.include?('-')
              SemanticTag.create!(:taggable_id => @tokens[@idx].id, :taggable_type => 'Token', :semantic_attribute_value_id => SemanticAttributeValue.find_by_tag('clitic').id )
            else
              STDERR.puts "Hell: what's with token #{@tokens[@idx].id}"
            end
          end
        end
        @after_token = true
      when "reg"
        new_word = (child/"w").map(&:inner_text).join('')
        old_word = child['orig']
        # If nothing happens inside the reg tag, we don't care
        if new_word == old_word
          parse_children(child)
        elsif  new_word.capitalize == old_word or new_word.gsub(/^þ/,'Þ') == old_word
          STDERR.puts "More than one word in a capitalization in #{@tokens[@idx].sentence_id}!" unless (child/"w").size == 1
          STDERR.puts "Something's wrong in a capitalization in #{@tokens[@idx].sentence_id}: the token has the form #{@tokens[@idx].form} while the presentation has #{new_word}" unless @tokens[@idx].form.capitalize == (child/"w").first.inner_text.capitalize
          @tokens[@idx].form = (child/"w").first.inner_text.capitalize
          @tokens[@idx].save!
          parse_children(child)
        elsif new_word.gsub('-', '') == old_word.gsub('-', '')
          parse_children(Nokogiri::XML(child.to_s.gsub(/<w>-/, '<pc>-</pc><w>')).at("reg"))
        elsif new_word.capitalize.gsub('-', '') == old_word.gsub('-', '') or new_word.gsub(/^þ/,'Þ').gsub('-', '') == old_word.gsub('-', '')
          STDERR.puts "More than one word in a capitalization in #{@tokens[@idx].sentence_id}!" unless (child/"w").size == 1
          STDERR.puts "Something's wrong in a capitalization in #{@tokens[@idx].sentence_id}: the token has the form #{@tokens[@idx].form} while the presentation has #{new_word}" unless @tokens[@idx].form.capitalize == (child/"w").first.inner_text.capitalize
          @tokens[@idx].form = (child/"w").first.inner_text.capitalize
          @tokens[@idx].save!
          parse_children(Nokogiri::XML(child.to_s.gsub(/<w>-/, '<pc>-</pc><w>')).at("reg"))
        elsif new_word.include?('-')
          hosts = (child/"w").map(&:inner_text).select { |h| h.match(/\w\-\w/) }
          STDERR.puts "More or less than one host in #{@tokens[@idx].sentence_id}!" unless hosts.size == 1
          parse_children(Nokogiri::XML(child.to_s.gsub(/<w>-/, '<pc>-</pc><w>')).at("reg"), 'endoclitic')
        else
          parse_children(child, 'corrected')
        end
      when "add", "unclear", "segmented", "reg", "expan", "corr"
        STDERR.puts "Word inside del" if child.name == 'del' and (child/"w").any?
        save_token! if @after_token
        parse_children(child, TAG_NAME_TO_SEMTAG_MAP[child.name])
      when "pc"
        pc = child.inner_text.to_s
        if LEFT_ATTACHING_PUNCTUATION.include?(pc)
          save_token! if @after_token
          @presentation_before += pc
        elsif RIGHT_ATTACHING_PUNCTUATION.include?(pc)
          @presentation_after += pc
        else
          STDERR.puts "Unknown punctuation '#{pc}', assumed to be right-attaching"
          @presentation_after += pc
        end
      when "s"
        if @after_token
          @presentation_after += child.inner_text
        else
          @presentation_before += child.inner_text
        end
      when "gap"
        if @after_token
          @presentation_after += "..."
        else
          @presentation_before += "..."
        end
      when "text"
        STDERR.puts "Loose text '#{child}' in #{@tokens[@idx].sentence_id}" unless child.to_s.match(/\s+/)
      else
        STDERR.puts "Unknown element #{child.name}: #{child}"
      end
    end
  end

  def self.up
    Sentence.find_each do |s|
      raise "Illformed presentation in #{s.id}" unless s.presentation_well_formed?
    end

    sa = SemanticAttribute.create!(:tag => "EDITORIAL_STATUS")
    (TAG_NAME_TO_SEMTAG_MAP.values.compact.uniq + ['deleted']).each do |semtag|
      execute("INSERT INTO semantic_attribute_values(tag, semantic_attribute_id, created_at, updated_at) VALUES ('#{semtag}', #{sa.id}, now(), now());")
    end

    sa = SemanticAttribute.create!(:tag => "ENDOCLICITY")
    ['host', 'clitic'].each do |semtag|
      execute("INSERT INTO semantic_attribute_values(tag, semantic_attribute_id, created_at, updated_at) VALUES ('#{semtag}', #{sa.id}, now(), now());")
    end

    [:presentation_before, :presentation_after].each do |column|
      add_column "source_divisions", column, :text
      add_column "sentences", column, :string, :limit => 64
      add_column "tokens", column, :string, :limit => 32
    end

    Sentence.find_each do |s|
      x = Nokogiri::XML('<presentation>' + s.presentation + '</presentation>')

      # Check if the whole sentence is inside a <del>-tag:
      if x.at("del") and x.at("del")/"w" == x/"w"
        SemanticTag.create!(:taggable_id => s.id, :taggable_type => 'Sentence', :semantic_attribute_value_id => SemanticAttributeValue.find_by_tag('deleted').id )
        x = x.at("del")
      else
        x = x.root
        unless s.tokenization_valid?
          # TODO: raise error
          STDERR.puts "Invalid tokenization in #{s.id}"
          next
        end
      end

      @tokens = s.tokens
      @idx = 0
      @presentation_before = ''
      @presentation_after  = ''
      @after_token = false
      @tag = nil

      parse_children(x)
      if @tokens[@idx]
        save_token!
      else
        STDERR.puts "No token to take presentation_before: '#{@presentation_before}' in #{@tokens.map(&:sentence_id).compact.uniq}"
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
