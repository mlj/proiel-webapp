module Analysis
  class Node
    def initialize(graph, node_index)
      @graph = graph
      @node_index = node_index
    end

    def parents(label_axis = nil, label_tag = nil)
      @graph.parents(@node_index, label_axis, label_tag).map do |n|
        Node.new(@graph, n)
      end
    end
  end

  class Graph
    def initialize(sentence)
      @ids = []
      @nodes = []
      @edges = []

      sentence.tokens.each do |t|
        add_node t.id, form: t.form, part_of_speech_tag: t.part_of_speech_tag
      end

      sentence.tokens.each do |t|
        add_edge t.id, t.head.id, :relation, t.relation_tag if t.head
        add_edge t.id, t.binder.id, :antecedent if t.antecedent and t.antecedent.sentence == sentence
      end
    end

    def find(id)
      index = @ids.index(id)

      raise ArgumentError, 'no such ID' if index.nil?

      Node.new(self, index)
    end

    def parents(index, label_axis = nil, label_tag = nil)
      raise ArgumentError, 'no such index' if index >= @ids.length

      if label_axis and label_tag
        label_filter = make_label(label_axis, label_tag)

        @edges[index].select do |(_, label)|
          label == label_filter
        end
      elsif label_axis
        @edges[index].select do |(_, label)|
          label[/^#{label_axis}:/]
        end
      else
        @edges[index]
      end
    end

    private

    def add_node(id, attributes = {})
      raise ArgumentError, 'duplicate ID' if @ids.include?(id)

      @ids.push(id)
      @nodes.push(attributes.dup)
      @edges[@ids.index(id)] ||= []
    end

    def add_edge(from_id, to_id, label_axis, label_tag = nil)
      from_index = @ids.index(from_id)
      to_index = @ids.index(to_id)
      label = make_label(label_axis, label_tag)

      raise ArgumentError, 'from node undefined' if from_index.nil?
      raise ArgumentError, 'to node undefined' if to_index.nil?

      @edges[from_index].push([to_index, label])
    end

    def make_label(label_axis, label_tag = nil)
      [label_axis, label_tag].compact.join(':')
    end
  end

  class Domain
    def initialize(options = {})
      @pred = []
      @pred << { 'sources.code' => options[:source_code] }
    end

    def tokens
      Token.
        joins(lemma: [], sentence: [source_division: [:source]]).
        where(@pred.first)
    end
  end

  class MyDomain < Domain
    def initialize
      codes = %w(
        pl-am pl-as pl-aul pl-bac pl-capt pl-cas pl-cist pl-curc pl-epid pl-men
        pl-merc pl-mil pl-mos pl-per pl-poen pl-ps pl-rud pl-st pl-trin pl-truc
        per-aeth
        petr
        pal-agr
      )

      super(source_code: codes)
    end

    def corpus_size
      tokens.group(:code).count
    end

    def corpus_size_to_tsv_file(file_name)
      File.open(file_name, 'w') do |f|
        f.puts %w(TEXT N_TOKENS).join("\t")

        corpus_size.each do |code, n|
          f.puts [code, n].join("\t")
        end
      end
    end

    def queue_probable_gerundials!
      queue!(probable_gerundials)
    end

    def queue_probable_reflexives!
      queue!(probable_reflexives)
    end

    def queue_probable_reflexives_without_binders!
      queue!(probable_reflexives_without_binders)
    end

    def queue!(ts)
      ts.each do |t|
        t.sentence.update_attributes! assigned_to: 2
      end
    end

    def gerundials
      tokens.where("morphology_tag LIKE '___g%' OR morphology_tag LIKE '___d%'")
    end

    def probable_gerundials
      not_pred = %w(vnde unde inde deinde proinde quando blande
        offendi offendas
        prehendi
        responde
        ascendam
        quendam).map do |word|
        "form != '#{word}'"
      end.join(' AND ')

      pred = %w(u us e i o um a ae am orum is os arum as).map do |suffix|
          "nd#{suffix}"
        end.map do |suffix|
          ['', 'que', 've', 'ne', 'n'].map { |clitic| "#{suffix}#{clitic}" }
        end.flatten.map do |suffix|
          ["form LIKE '%#{suffix}'"]
        end.join(' OR ')

      tokens.where(pred).where(not_pred)
    end

    def probable_reflexives
      forms =
        %w(se semet seque sese sesemet seseque sibi sibimet sibique sui suimet suique)
      tokens.where(form: forms).where('lemmata.part_of_speech_tag is NULL OR
                                      lemmata.part_of_speech_tag != "Pt"')
    end

    def reflexives
      tokens.includes(:lemma).where('lemmata.part_of_speech_tag' => 'Pk').order(:source_division_id, :sentence_number)
    end

    def reflexives_with_binders
      reflexives.where('binder_id is not null')
    end

    def reflexives_without_binders
      reflexives.where('binder_id is null or binder_id = 0')
    end

    def probable_reflexives_without_binders
      probable_reflexives.where('binder_id is null or binder_id = 0')
    end

    def probable_reflexives_without_binders_to_tsv_file(filename)
      File.open(filename, 'w') do |f|
        f.puts [
          'Work',
          'Citation',
          'Treebank ID',
          'Form',
        ].join("\t")

        probable_reflexives_without_binders.each do |x|
          f.puts [
            x.sentence.source_division.source.citation_part,
            x.citation_part,
            sanitise_treebank_id(x),
            x.form,
          ].join("\t")
        end
      end
    end

    def tam_features(t)
      return '' if t.nil?

      case t.part_of_speech_tag
      when 'V-'
        case t.mood
        when 'p'
          # Check for an accusative subject dependent
          if t.dependents.any? { |d| d.relation_tag == 'sub' and d.case == 'a' }
            'PART-AcI'
          elsif t.dependents.any? { |d| d.relation_tag == 'aux' and d.form == 'est' }
            'PART-MAIN'
          elsif t.case == 'b' and t.dependents.any? { |d| d.relation_tag == 'sub' and (d.case == 'b' or d.conjunction?) }
            'PART-ABS'
          elsif t.relation_tag == 'xobj'
            'PART-CTRL'
          elsif t.relation_tag == 'xadv'
            'PART-ADJ'
          else
            'PART'
          end
        when 'n'
          # Check for an accusative subject dependent
          if t.dependents.any? { |d| d.relation_tag == 'sub' and d.case == 'a' }
            'INF-AcI'
          elsif t.relation_tag == 'comp'
            'INF-AcI'
          elsif t.relation_tag == 'xobj'
            'INF-CTRL'
          else
            'INF'
          end
        when 's'
          'SUBJ'
        when 'i'
          'IND'
        when 'm'
          'IMP'
        when 'g'
          'GDV'
        when 'd'
          'GER'
        when 's'
          'SUP'
        end
      when 'A-'
        'ADJ'
      when 'Nb'
        'NOUN'
      when 'Pt'
        '(possessive reflexive)'
      when 'Df'
        '(adverb)'
      when 'C-'
        'conjunction???'
      when NilClass
        ''
      else
        raise "Unknown part of speech #{t.part_of_speech_tag}"
      end
    end

    def clausal_predicate(t)
      if t.relation_tag == 'xobj' or t.relation_tag == 'adv' or t.relation_tag == 'xadv'
        t.find_dependency_ancestor { |y| !y.conjunction? }
      else
        if t.part_of_speech_tag == 'V-' or t.empty_token_sort == 'V'
          t
        else
          t.find_dependency_ancestor do |y|
            y.part_of_speech_tag == 'V-' or t.empty_token_sort == 'V'
          end
        end
      end
    end

    def clausal_mood(t)
      hd = clausal_predicate(t)

      if hd
        tp =
          if hd.relation_tag == 'pred'
            hd.find_dependency_ancestor do |y|
              !y.conjunction?
            end
          else
            hd
          end

        type =
          case tp.try(:relation_tag)
          when NilClass
            'main'
          when 'adv', 'comp'
            tp.relation_tag
          when 'apos', 'atr'
            'rel'
          when 'sub', 'obj'
            'rel' # headless relative
          else
            STDERR.puts ["http://localhost:3000/sentences/#{t.sentence_id}", t.citation_part, t.form, tp.relation_tag].join(' ')
            '?'
          end

        mood =
          case hd.mood
          when 'p'
            if hd.relation_tag == 'comp'
              'AcI'
            elsif hd.dependents.any? { |d| d.relation_tag == 'sub' and d.case == 'a' }
              'AcI'
            elsif hd.dependents.any? { |d| d.relation_tag == 'aux' and d.form == 'est' }
              'IND'
            else
              'PART'
            end
          when 'n'
            if hd.relation_tag == 'comp'
              'AcI'
            elsif hd.dependents.any? { |d| d.relation_tag == 'sub' and d.case == 'a' }
              'AcI'
            else
              'INF'
            end
          when 's'
            'SUBJ'
          when 'i'
            'IND'
          when 'g'
            '(GDV)'
          when 'd'
            '(GER)'
          when 's'
            '(SUP)'
          when 'm'
            'IMP'
          else
            # Check for null V with an accusative subject dependent
            if hd.empty_token_sort == 'V' and hd.dependents.any? { |d| d.relation_tag == 'sub' and d.case == 'a' }
              'AcI'
            else
              '?'
            end
          end

        [mood, type].join('-')
      else
        STDERR.puts [t.citation_part, t.form, t.relation_tag, 'no head'].join(':')
        "?"
      end
    end

    def sanitise_treebank_id(t)
      case t.sentence.source_division.source.code
      when 'per-aeth'
        "proiel:#{t.sentence_id}"
      else
        "mlj:#{t.sentence_id}"
      end
    end

    def reflexives_and_context
      reflexives.map do |x|
        work = x.sentence.source_division.source.citation_part
        citation = x.citation_part

        text = x.sentence.to_s(highlight_tokens: x.id).strip
        text.sub!(/\u2028$/, '')
        text.gsub!(/\u2028/, ' / ')
        text.sub!(/^\s*’\s*\/?\s*/, '') # bug in Pl.
        text.sub!(/^‘\s+/, '‘') # id.

        t = analyse_reflexive(x)

        analysis =
          case t.dependency
          when 'local:arg'
            if t.ant_category == 'NP' or t.ant_category == 'complex'
              "#{t.dependency}: #{t.ant_form} #{t.form} #{t.predicate}"
            else
              "#{t.dependency}: #{t.form} #{t.predicate}"
            end
          else
            t.dependency
          end

        comment = ''
        comment = " [#{x.old}]" unless x.old.blank?

        "#{work} #{citation}: #{text} (#{analysis})#{comment}"
      end
    end

    def reflexives_by_binder_type
      reflexives.map do |x|
        analyse_reflexive(x)
      end
    end

    def analyse_reflexive(x)
      OpenStruct.new.tap do |type|
        type.work = x.sentence.source_division.source.citation_part
        type.citation = x.citation_part

        type.treebank_id = sanitise_treebank_id(x)

        type.form = x.form # TODO: clitics

        type.note = x.old.try(:strip)

        type.case =
          case x.case
          when 'n'
            'NOM'
          when 'g'
            'GEN'
          when 'a'
            'ACC'
          when 'b'
            'ABL'
          when 'd'
            'DAT'
          else
            nil
          end

        type.complexity = 'bare'
        type.gf = x.relation_tag.try(:upcase)
        hd =
          x.find_dependency_ancestor do |y|
            if y.conjunction?
              # TODO: determine type of coordination
              type.complexity = 'coordinated'
              false
            elsif y.preposition?
              prep = y.lemma.to_s.tr('#', '').sub(',R-', '')
              type.gf = "#{y.relation_tag.upcase}(#{prep})"
              false
            else
              true
            end
          end

        type.predicate = hd.try(:lemma).try(:export_form)

        type.predicate_tam = tam_features(hd)

        type.clausal_mood = clausal_mood(hd) if hd.try(:relation_tag)

        unless x.binder.nil?
          if x.binder.part_of_speech_tag == 'V-' and %w(atr apos pred xobj xadv comp).include?(x.binder.relation_tag)
            type.ant_gf = 'SUB'
            type.ant_form = nil
            type.ant_category = 'pro'
            binder_head = x.binder
          else
            if x.binder.empty_token_sort == 'V'
              type.ant_gf = nil
              type.ant_category = 'discourse'
              type.ant_form = nil
              binder_head = nil
            elsif x.binder.empty_token_sort == 'P'
              type.ant_gf = x.binder.relation_tag.upcase # TODO: prep heading and coord?
              type.ant_category = 'pro'
              type.ant_form = nil
              binder_head = x.binder.head
            elsif x.binder.part_of_speech_tag == 'C-'
              type.ant_gf = x.binder.relation_tag.upcase # TODO: prep heading and coord?
              type.ant_category = 'complex' #TODO
              type.ant_form = ([x.binder] + x.binder.dependents).sort_by { |z| z.token_number }.map(&:form).join(' ')
              binder_head = x.binder.head
            else
              type.ant_gf = x.binder.relation_tag.upcase # TODO: prep heading and coord?
              type.ant_category = 'NP' #TODO
              type.ant_form = x.binder.form #([x.binder] + x.binder.dependents).sort_by { |z| z.token_number }.map(&:form).join(' ')
              binder_head = x.binder.head
            end
          end

          type.ant_predicate = binder_head.try(:lemma).try(:export_form)

          type.ant_predicate_tam = tam_features(binder_head)

          type.ant_category = 'PRO' if type.ant_category == 'pro' and type.ant_predicate_tam == 'INF-CTRL'
          type.ant_category = 'PRO' if type.ant_category == 'pro' and type.ant_predicate_tam == 'PART-CTRL'
          type.ant_category = 'PRO' if type.ant_category == 'pro' and type.ant_predicate_tam == 'PART-ADJ'

          if type.predicate_tam == '(possessive reflexive)'
            # Special case: a possessive reflexive pleonasm
            type.dependency = 'intensifier'
            type.ant_predicate_tam = nil
            type.ant_predicate = nil
          elsif x.binder == x
            # Special case: a logocentre is inferred somehow
            type.dependency = 'discourse:inferred'
            type.ant_gf = nil
            type.ant_category = nil
            type.ant_form = nil
            type.ant_predicate_tam = nil
            type.ant_predicate = nil
          elsif binder_head == hd
            if type.gf == 'OBJ' or type.gf == 'OBL'
              type.dependency = 'local:arg'
            else
              type.dependency = 'local'
            end
          elsif x.find_dependency_ancestor { |y| y == binder_head }
            if !x.binder.logocentre.blank?
              type.dependency = 'non-local:log'
            else
              type.dependency = 'non-local'
            end
          else
            if !x.binder.logocentre.blank?
              type.dependency = 'discourse:log'
            else
              type.dependency = 'discourse'
            end
          end

          type.logocentre = x.binder.logocentre
        end
      end
    end

    def csv_line(*d)
      d.map do |c|
        if c and c[/[\s"]+/]
          "\"#{c}\""
        else
          c
        end
      end.join(',')
    end

    def export_se_ipsum(filename)
      se_lemma_ids = Lemma.where(language_tag: 'lat').where(lemma: 'se').pluck(:id)
      ipse_lemma_ids = Lemma.where(language_tag: 'lat').where(lemma: 'ipse').pluck(:id)

      se_sentences = tokens.where(lemma_id: se_lemma_ids).pluck(:sentence_id)
      ipse_sentences = tokens.where(lemma_id: ipse_lemma_ids).pluck(:sentence_id)
      both_sentences = se_sentences & ipse_sentences

      File.open(filename, 'w') do |f|
        both_sentences.map do |s_id|
          s = Sentence.find(s_id)
          se = s.tokens.where(lemma_id: se_lemma_ids).pluck(:id)
          ipse = s.tokens.where(lemma_id: ipse_lemma_ids).pluck(:id)

          text = s.to_s(highlight_tokens: se + ipse).strip
          text.sub!(/\u2028$/, '')
          text.gsub!(/\u2028/, ' / ')
          text.sub!(/^\s*’\s*\/?\s*/, '') # bug in Pl.
          text.sub!(/^‘\s+/, '‘') # id.
          text.gsub!(/(.{1,78})(\s+|$)/, "\\1\n")
          text.strip!

          "#{text} (#{s.citation})"
        end.each do |text|
          f.puts text
          f.puts
        end
      end
    end

    def export_se_quisque(filename)
      se_lemma_ids = Lemma.where(language_tag: 'lat').where(lemma: 'se').pluck(:id)
      ipse_lemma_ids = Lemma.where(language_tag: 'lat').where(lemma: 'quisque').pluck(:id)

      se_sentences = tokens.where(lemma_id: se_lemma_ids).pluck(:sentence_id)
      ipse_sentences = tokens.where(lemma_id: ipse_lemma_ids).pluck(:sentence_id)
      both_sentences = se_sentences & ipse_sentences

      File.open(filename, 'w') do |f|
        both_sentences.map do |s_id|
          s = Sentence.find(s_id)
          se = s.tokens.where(lemma_id: se_lemma_ids).pluck(:id)
          ipse = s.tokens.where(lemma_id: ipse_lemma_ids).pluck(:id)

          text = s.to_s(highlight_tokens: se + ipse).strip
          text.sub!(/\u2028$/, '')
          text.gsub!(/\u2028/, ' / ')
          text.sub!(/^\s*’\s*\/?\s*/, '') # bug in Pl.
          text.sub!(/^‘\s+/, '‘') # id.
          text.gsub!(/(.{1,78})(\s+|$)/, "\\1\n")
          text.strip!

          "#{text} (#{s.citation})"
        end.each do |text|
          f.puts text
          f.puts
        end
      end
    end

    def export_text(filename)
      File.open(filename, 'w') do |f|
        reflexives_and_context.each do |l|
          l.gsub!(/(.{1,78})(\s+|$)/, "\\1\n")
          l.strip!

          f.puts l
          f.puts
        end
      end
    end

    def export_reflexives(file_name)
      File.open(file_name, 'w') do |f|
        f.puts(csv_line(
          'Work',
          'Citation',
          'Treebank ID',
          'Form',
          'Case',
          'GF',
          'Complexity',
          'Predicate',
          'Predicate TAM',
          'Clausal mood',

          'Ant. GF',
          'Ant. category',
          'Ant. form',
          'Ant. predicate',
          'Ant. predicate TAM',

          'Dependency',
          'Logocentre',

          'Note',
        ))

        reflexives_by_binder_type.each do |x|
          f.puts(csv_line(
            x.work,
            x.citation,
            x.treebank_id,
            x.form,
            x.case,
            x.gf,
            x.complexity,
            x.predicate,
            x.predicate_tam,
            x.clausal_mood,

            x.ant_gf,
            x.ant_category,
            x.ant_form,
            x.ant_predicate,
            x.ant_predicate_tam,

            x.dependency,
            x.logocentre,

            x.note
          ))
        end
      end
      nil
    end
  end
end

if $0 == __FILE__
  require_relative '../config/environment'
  @domain = Analysis::MyDomain.new
  @domain.export_text('/home/mlj/src-cleared/postdoc-corpus/dataset-exports/reflexives.txt')
  @domain.export_reflexives('/home/mlj/src-cleared/postdoc-corpus/dataset-exports/reflexives.csv')
  @domain.export_se_ipsum('/home/mlj/src-cleared/postdoc-corpus/dataset-exports/se-ipsum.txt')
  @domain.export_se_quisque('/home/mlj/src-cleared/postdoc-corpus/dataset-exports/se-quisque.txt')
end
