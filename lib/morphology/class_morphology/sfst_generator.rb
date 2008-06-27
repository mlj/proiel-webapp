class SFSTFile
  def initialize(base_name)
    @fst_file = File.open(base_name + '.fst', 'w')
    @symbol_file = File.open(base_name + '-symbols.fst', 'w')
    @fst_file.puts "% This file is automatically genereated. Do not edit!"
    @fst_file.puts "#include \"#{base_name + '-symbols.fst'}\"" 

    @identifier_count = 0
    @symbol_count = 0
    @disposable_symbols = []
    @replacement_rules = []
  end

  def put_epilogue(final_variable)
    self.put_symbol_definition_of_multichars("disposable_symbols", *@disposable_symbols)

    @fst_file.puts "% Remove all marker symbols from surface strings"
    @fst_file.puts "ALPHABET = [#letters#] [#classes#] [#features#] [#disposable_symbols#]:<>"
    @fst_file.puts "$surface-filter$ = .*"

    machines = [final_variable] + @replacement_rules + ["surface-filter"]
    @fst_file.puts machines.collect { |m| "$#{m}$" }.join(' || ')
  end

  def put_symbol_definition(name, *values)
    @symbol_file.puts "##{name}# = #{values.join}"
  end

  def put_symbol_definition_of_multichars(name, *values)
    self.put_symbol_definition(name, values.collect { |v| "<#{v}>" })
  end

  def put_variable_definition(name, *values)
    @fst_file.puts "$#{name}$ = #{values.join(' ')}"
  end

  def put_variable_definition_option_list(name, *options)
    self.put_variable_definition(name, "(" + options.join(" |\\\n") + ")\n")
  end

  def put_comment(msg)
    @fst_file.puts("% " + msg)
  end

  def print(s)
    @fst_file.print(s)
  end

  def puts(*s)
    @fst_file.puts(s)
  end

  def generate_identifier(replacement_rule = false)
    @identifier_count += 1
    id = "id#{@identifier_count}"

    @replacement_rules << id if replacement_rule

    id
  end

  def generate_symbol(disposable = false)
    @symbol_count += 1
    sym = "sym#{@symbol_count}"

    @disposable_symbols << sym if disposable

    sym
  end
end

class FeatureSet < Set
  def to_s
    to_a.sort.map { |c| "<#{c}>" }.join
  end
end

def produce_output(base_name, program, evaluations)
  f = SFSTFile.new(base_name)

  # Emit preamble
  f.print program.preamble

  # Emit computed constants
  f.puts
  f.puts "% Computed constants"

  f.puts "ALPHABET = [#letters#] [#classes#] [#features#] [#disposable_symbols#]"
 
  compilers = []
  evaluations.each_pair do |class_name, c|
    f.puts
    f.puts "% Class #{class_name}"
    lexicon_file_name = [base_name, class_name].join('-') + '.lex' 
    f.put_variable_definition "#{class_name}-dict", "\"#{lexicon_file_name}\""
    unless File.exists?(lexicon_file_name)
      File.open(lexicon_file_name, 'w') {}
    end
    compilers << Compiler.new(program, c, "#{class_name}-dict", "any-root", f, class_name)
  end

  all_class_names = compilers.inject(FeatureSet.new) { |s, x| s + Set.new(x.class_name) }
  all_features = compilers.inject(FeatureSet.new) { |s, x| s + x.feature_set }

  f.put_symbol_definition("classes", all_class_names.to_s)
  f.put_symbol_definition("features", all_features.to_s)

  f.puts "% Final transducer"
  f.put_variable_definition("forms", compilers.map(&:boot_symbol).map { |c| "$#{c}$" }.join(' | '))

  f.put_epilogue("forms")
end

class Compiler
  attr_reader :boot_symbol, :feature_set, :class_name

  def initialize(expression_tree, class_node, lexicon_symbol, guesser_symbol, f,
                class_name)
    @expression_tree = expression_tree
    @class_node = class_node
    @boot_symbol = "#{class_name}-boot"
    @lexicon_symbol = lexicon_symbol
    @guesser_symbol = guesser_symbol
    @f = f
    @class_name = class_name

    @expression_object_ids = {}
    @feature_set = Set.new

    arity = class_node.arity
    @arity_identifiers = (0...arity).to_a.collect { |i| "-" + i.to_s }

    produce_output_r
  end

  private

  def update_expression_object_id(expression_object, id)
    @expression_object_ids[expression_object] = id
  end

  def get_expression_object_ids(*expression_objects)
    expression_objects.map { |e| @expression_object_ids[e] }
  end

  def put_multi_arity_definition(i, expression_object, *args)
    @f.put_comment(expression_object.to_s)

    update_expression_object_id(expression_object, i)
    resolved_args = get_expression_object_ids(*args)

    if expression_object.arity == 1
      @f.put_variable_definition(i, yield(*resolved_args.map { |x| "$#{x}$" }))
    else
      @arity_identifiers.each do |a|
        arg_ids = args.map do |arg|
          if arg.arity == 1
            @expression_object_ids[arg]
          else
            @expression_object_ids[arg] + a
          end
        end
        @f.put_variable_definition(i + a, yield(*arg_ids.map { |x| "$#{x}$" }))
      end
    end
  end

  def produce_output_r
    arity = @class_node.arity
    arity_identifiers = (0...arity).to_a.collect { |i| "-" + i.to_s }

    @class_node.yield_objects do |expression_object|
      i = @f.generate_identifier

      case expression_object
      when ClassBasedMorphology::Literal 
        @f.put_comment(expression_object.to_s)

        unless expression_object.set_valued?
          if expression_object.arity == 1
            @f.put_variable_definition(i, "{}:{#{expression_object.value.first}}")
          else
            arity_identifiers.zip(expression_object.value).each do |a, v|
              @f.put_variable_definition(i + a, "{}:{#{v}}")
            end
          end
        else
          if expression_object.arity == 1
            #FIXME
            @f.put_variable_definition(i, "{#{expression_object.value.first}}:{}")
          else
            arity_identifiers.zip(expression_object.value).each do |a, v|
              @f.put_variable_definition(i + a, "{#{v.sort.map { |e| "<#{e}>" }.join}}:{}")
            end
          end
          @feature_set += expression_object.value.inject { |s, x| s + x }
        end
        update_expression_object_id(expression_object, i)

      when ClassBasedMorphology::Union
        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.left,
                                   expression_object.right) do |x, y|
          [x, y].join(' | ')
        end

      when ClassBasedMorphology::Cons
        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.left,
                                   expression_object.right) do |x, y|
          [x, y].join(' ')
        end

      when ClassBasedMorphology::Guess
        update_expression_object_id(expression_object, @guesser_symbol)

      when ClassBasedMorphology::Lexicon
        update_expression_object_id(expression_object, @lexicon_symbol)

      when ClassBasedMorphology::Filter
        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.string) do |string|
          [string, "(" + expression_object.rule.value.to_s + ")"].join(' & ')
        end
        update_expression_object_id(expression_object, i)

      when ClassBasedMorphology::Mapping
        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.upper_level,
                                   expression_object.lower_level) do |x, y|
          [x, y].join(' ')
        end

        #FIXME: check for only one mapping
        @f.put_variable_definition_option_list(@boot_symbol, @arity_identifiers.map { |a| '$' + i + a + '$' })

      when ClassBasedMorphology::Subst
        #FIXME: must be unary literals
        from, to = expression_object.from.value, expression_object.to.value

        disposable_symbol = @f.generate_symbol(true)

        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.string) do |x|
          "#{x} <>:<#{disposable_symbol}>"
        end

        replacement_rule_identifier = @f.generate_identifier(true)
        @f.put_variable_definition(replacement_rule_identifier, "{#{from}}:{#{to}} ^-> (__ <#{disposable_symbol}>)")

      when ClassBasedMorphology::Replacement
        #FIXME: must be unary literals
        from, to, left_context, right_context = expression_object.from.value,
          expression_object.to.value,
          expression_object.left_context.value,
          expression_object.right_context.value,
      
        disposable_symbol = @f.generate_symbol(true)

        put_multi_arity_definition(i,
                                   expression_object,
                                   expression_object.string) do |x|
          "#{x} <>:<#{disposable_symbol}>"
        end

        from.zip(to).each do |from_string, to_string|
          replacement_rule_identifier = @f.generate_identifier(true)
          @f.put_variable_definition(replacement_rule_identifier, "{#{from_string}}:{#{to_string}} ^-> (#{left_context} __ <#{disposable_symbol}> #{right_context})")
        end
        i
      else
        STDERR.puts expression_object.class
      end
    end
  end
end
