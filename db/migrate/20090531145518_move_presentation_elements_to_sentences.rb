class Formatter
  def format_sentence(sentence)
    t = ''
    text_started = false
    skip_tokens = 0
    book = sentence.source_division.fields[/^book=(\w+),/]
    book.gsub!(/book=/, '')
    chapter = sentence.source_division.fields[/(\d|Incipit|Explicit)$/]

    sentence.tokens.each do |token|
      if skip_tokens > 0
        skip_tokens -= 1
        next
      end

      t_b = check_reference_update(:book, book)
      t_c = check_reference_update(:chapter, chapter)
      t_v = check_reference_update(:verse, token.verse)

      t += ' ' if !t.blank? and (!t_b.blank? or !t_c.blank? or !t_v.blank?)
      t += t_b
      t += t_c
      t += t_v

      case token.sort
      when :empty_dependency_token
      when :lacuna_start
        t.sub!(/\s+$/, '')
        t += '<gap/>'
      when :lacuna_end
        t.sub!(/\s+$/, '')
        t += '<gap/>'
      when :punctuation, :text
        if token.temp_presentation
          f = token.temp_presentation
          skip_tokens = token.presentation_span - 1
        else
          f = token.form
        end

        case token.nospacing
        when :after
          t += f
        when :before
          t.sub!(/\s+$/, '')
          t += f + ' '
        when NilClass
          if !text_started or t[/ $/]
            t += f + ''
          else
            t += ' ' + f + ' '
          end
        else
          raise "Invalid nospacing value"
        end

        text_started = true
      else
        raise "Invalid token type #{token.sort} for ID #{token.id}"
      end
    end

    t.sub(/\s+$/,'')
  end

  def check_reference_update(reference_type, reference)
    @state ||= {}

    if reference and @state[reference_type] != reference.to_s
      @state[reference_type] = reference.to_s
      "<milestone n='#{reference}' unit='#{reference_type}'/>"
    else
      ""
    end
  end
end

class MovePresentationElementsToSentences < ActiveRecord::Migration
  def self.up
    add_column :tokens, :temp_presentation, :text

    # XML escaping
    raise "tokens.form contains characters that must be escaped" if Token.exists?(['form LIKE "%%\'%%"'])
    raise "tokens.form contains characters that must be escaped" if Token.exists?(['form LIKE "%%&%%"'])
    raise "tokens.form contains characters that must be escaped" if Token.exists?(['form LIKE "%%<%%"'])
    raise "tokens.form contains characters that must be escaped" if Token.exists?(['form LIKE "%%>%%"'])
    raise "tokens.presentation_form contains characters that must be escaped" if Token.exists?(['presentation_form LIKE "%%\'%%"'])
    raise "tokens.presentation_form contains characters that must be escaped" if Token.exists?(['presentation_form LIKE "%%&%%"'])

    # tokens.abbreviation
    raise "tokens table contains unhandled abbreviation" if Token.exists?(['abbreviation = 1'])
    remove_column :tokens, :abbreviation
    Token.reset_column_information

    # tokens.contraction
    Token.all(:conditions => ["contraction = 1 and presentation_span = 2"]).each do |m|
      n = m.next_token
      raise "No next token for token #{m.id}" unless n
      raise "invalid presentation settings" if n.presentation_form or n.presentation_span

      if m.form + n.form == m.presentation_form
        m.temp_presentation = "<w>#{m.form}</w><w>-#{n.form}</w>"
      elsif m.form + '-' + n.form == m.presentation_form
        m.temp_presentation = "<reg orig='#{m.presentation_form}'><w>#{m.form}</w><w>-#{n.form}</w></reg>"
      elsif m.form + n.form == m.presentation_form.downcase
        m.temp_presentation = "<reg orig='#{m.presentation_form}'><w>#{m.form}</w><w>-#{n.form}</w></reg>"
      else
        case m.presentation_form
        when 'с҃нбсе', 'с҃нбе', 'с҃мъ', 'н҃бсе', 'н҃нбсе' 'н҃нбсхъ', 'в҃лмъ', 'ч҃лвѣкотъ', 'н҃кстѣ', 'с҃пстѧ', 'в҃ли', 'вⷧ҇мъ', 'ньⷩ҇', 'н҃нбсхъ', 'н҃нбо', 'н҃нбсе', 'н҃нбхъ'
          m.temp_presentation = "<expan abbr='#{m.presentation_form}'>#{m.form} #{n.form}</expan>"
        when 'осѫдѧтꙑи', 'единого-тъ', 'бечьсти', 'домотъ', 'ежестъ', 'народось', 'родось', 'ичрѣва'
          m.temp_presentation = "<reg orig='#{m.presentation_form}'>#{m.form} #{n.form}</reg>"
        when 'Niþ-þan'
          m.temp_presentation = "<reg orig='#{m.presentation_form}'><w>#{m.form}</w><w>-#{n.form}</w></reg>"
        when 'κἀγὼ', 'κἀγώ', 'Κἀγὼ', 'κἀκεῖ', 'κἀκεῖνος', 'κἀκεῖθεν', 'κἀκείνους', 'κἀκεῖνον', 'διατί', 'κἀκεῖνοι', 'τοὐναντίον', 'κἀκεῖνα', 'Κἀκεῖθεν', 'κἂν', 'κἀκεῖνός', 'κἀμοὶ', 'τοὔνομα', 'κἀμὲ', 'Κἀκεῖ', 'Κἀγώ', 'κἀμοί', 'þû', 'uzuhhof', 'uzuhiddja'
          m.temp_presentation = "<segmented orig='#{m.presentation_form}'><w>#{m.form}</w> <w>#{n.form}</w></segmented>"
        when 'ƕileiku<h>'
          m.temp_presentation = "<corr sic='#{m.presentation_form}'><w>#{m.form}</w><w>-u<add>h</add></w></corr>"
          m.emendation = false
        else
          raise "unhandled contraction"
        end
      end
      m.without_auditing { m.save! }
    end

    Token.all(:conditions => ["contraction = 1 and presentation_span = 3"]).each do |m|
      n = m.next_token
      raise "No next token for token #{m.id}" unless n
      raise "invalid presentation settings" if n.presentation_form or n.presentation_span
      o = n.next_token
      raise "No next token for token #{o.id}" unless o
      raise "invalid presentation settings" if o.presentation_form or o.presentation_span

      m.temp_presentation = "<reg orig='#{m.presentation_form}'><w>#{m.form}</w><w>-#{n.form}</w><w>-#{o.form}</w></reg>"
      m.without_auditing { m.save! }
    end

    Token.all(:conditions => ["contraction = 1 and presentation_span = 4"]).each do |m|
      case m.presentation_form
      when 'gah-þan-miþ-[ga]sandidedum'
        m.temp_presentation = "<segmentation orig='gah-þan-miþ-'></segmentation><del>ga</del><segmentation orig='sandidedum'><w>ga-sandidedum</w><w>-h</w><w>-þan</w><w>-miþ</w></segmentation>"
        m.emendation = false
      else
        raise "Unknown case"
      end

      m.without_auditing { m.save! }
    end

    raise "tokens table contains unhandled contraction" if Token.exists?(['contraction = 1 and temp_presentation is null'])
    remove_column :tokens, :contraction
    Token.reset_column_information

    # tokens.emendation: we ignore most of these since they are
    # useless. For Gothic they are predictable from parentheses or
    # angle brackets in the presentation_form.
    # <> = additions, [] = deletions, () = unclear
    wulfila = Source.find_by_code('wulfila-gothicnt')
    if wulfila
    wulfila.source_divisions.each do |sd|
      sd.sentences.find(:all, :conditions => ["tokens.emendation = 1"], :include => :tokens).map(&:tokens).flatten.select(&:emendation).each do |t|
        predicated_form = nil
        actual_form = nil
        capitalised = false

        chr = /[A-ZÞa-zþƕï]+/
        br_chr = /[\(\[<]?#{chr}[>\)\]]?/

        case t.presentation_form.gsub('&lt;', '<').gsub('&gt;', '>')
        when '(·a·)'
          t.temp_presentation = "<unclear>·a·</unclear>"
          t.presentation_span = 1
          t.sort = :punctuation
        when '(ga)qiu_'
          t.temp_presentation = "<unclear>ga</unlear>qiu"
          t.form = "gaqiu"
        when 'A(ipist)a(ule)'
          t.temp_presentation = '<reg orig="A">a</reg><unclear>ipist</unclear>a<unclear>ule</unclear>'
        when 'D(u)'
          t.temp_presentation = '<reg orig="D">d</reg><unclear>u</unclear>'
        when '(Galeik)'
          t.temp_presentation = '<unclear><reg orig="G">g</reg>aleik</unclear>'
        when /^\[(#{chr})\]$/, '[freij(hals)]', '[uf(kun)nands]', '[arma(hai)rtein]', '[(j)ah]', '[(qairrus)]'
          # These are wrongly tokenized as tokens, but should be in
          # the database.
          t.temp_presentation = t.presentation_form.gsub('(', '<unclear>').gsub(')', '</unclear>').gsub('[', '<del>').gsub(']', '</del>')
          predicted_form = t.presentation_form.gsub(/[\(\)\[\]]/, '')
        when /^(#{br_chr})(#{br_chr})?(#{br_chr})?(#{br_chr})?(#{br_chr})?(#{br_chr})?(#{br_chr})?(#{br_chr})?$/
          m = $~.to_a
          m.shift

          predicted_form = m.map do |x|
            case x
            when NilClass, /^\[(#{chr})\]$/: nil
            when /^\((#{chr})\)$/, /^<(#{chr})>$/, /^(#{chr})$/: $1
            else
              raise "Unknown characters"
            end
          end.join

          raise "Form prediction mismatch" unless predicted_form == t.form

          t.temp_presentation = m.map do |x|
            case x
            when NilClass: nil
            when /^\((#{chr})\)$/: "<unclear>#{$1}</unclear>"
            when /^\[(#{chr})\]$/: "<del>#{$1}</del>"
            when /^<(#{chr})>$/: "<add>#{$1}</add>"
            when /^(#{chr})$/: $1
            else
              raise "Unknown characters"
            end
          end.join
        else
          raise "Unknown emendation type in wulfila-gothicnt: #{t.presentation_form}"
        end

        t.without_auditing { t.save! }
      end
    end
    end

    raise "tokens table contains unhandled emendation" if Token.exists?(['emendation = 1 and temp_presentation is null'])
    remove_column :tokens, :emendation
    Token.reset_column_information

    # tokens.capitalisation
    execute("update tokens set temp_presentation = concat('<reg orig=\"', presentation_form, '\">', form, '</reg>') where capitalisation = 1 and presentation_span = 1 and ucase(presentation_form) = ucase(form);")

    raise "tokens table contains unhandled capitalisation" if Token.exists?(['capitalisation = 1 and temp_presentation is null'])
    remove_column :tokens, :capitalisation
    Token.reset_column_information

    raise "tokens table contains unhandled presentation_form" if Token.exists?(['presentation_form and temp_presentation is null'])
    raise "tokens table contains unhandled presentation_span" if Token.exists?(['presentation_span and temp_presentation is null'])

    add_column :sentences, :presentation, :text, :null => false

    Sentence.reset_column_information

    SourceDivision.find(:all).each do |div|
      f = Formatter.new # recreate each time to reset all reference states
      div.sentences.find(:all).each do |s|
        s.presentation = f.format_sentence(s)
        s.without_auditing { s.save_without_validation! }
      end
    end

    # Kill off all unannotatable tokens that we no longer care about.
    ['lacuna_start', 'lacuna_end', 'punctuation'].each do |sort|
      execute("DELETE FROM tokens WHERE sort = '#{sort}';")
    end

    remove_column :tokens, :sort
    remove_column :tokens, :presentation_span
    remove_column :tokens, :presentation_form
    remove_column :tokens, :nospacing
    remove_column :tokens, :temp_presentation

    # Deal with fluid reference systems
    remove_column :source_divisions, :fields
    add_column :sources, :tracked_references, :string, :limit => 128, :null => true

    add_column :sources, :reference_fields, :string, :limit => 128, :null => false, :default => ''
    add_column :source_divisions, :reference_fields, :string, :limit => 128, :null => false, :default => ''
    add_column :sentences, :reference_fields, :string, :limit => 128, :null => false, :default => ''
    add_column :tokens, :reference_fields, :string, :limit => 128, :null => false, :default => ''

    Source.reset_column_information
    Sentence.reset_column_information

    Source.find_each do |s|
      s.tracked_references = {"token"=>["verse"], "source_division"=>["book", "chapter"]}
      s.save_without_validation!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
