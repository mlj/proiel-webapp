#!/usr/bin/env ruby

require 'treetop'
require 'extensions'
require 'set'
require 'singleton'

module ClassBasedMorphology
  class Expression
    def self.prototype(*args)
      attr_reader *args

      args.each_with_index do |name, i|
        define_method name do
          @args[i]
        end
      end

      define_method :argument_count do
        args.length
      end
    end

    def initialize(*args)
      raise "Invalid number of arguments for function #{name}" unless argument_count == args.length if respond_to?(:argument_count)
      @args = args
    end

    def arity
      max = @args.map(&:arity).max
      raise "#{name}: Arity mismatch #{@args.map(&:arity).join(', ')}" unless @args.all? { |e| e.arity == 1 or e.arity == max }
      max
    end

    def type
      @args.each do |arg|
        raise "Invalid type #{arg.type} for expression #{arg}" unless arg.type == :string
      end
      :string
    end

    def optimise
      # No optimisation possible
      self
    end

    def name; self.class.to_s.downcase.sub(/^.*::/, '') end

    def to_s; "#{name}(#{@args.join(', ')})" end

    # Returns all expression objects contained by this expression object, including
    # itself.
    def expression_objects
      if @args
        [self] + @args.collect(&:expression_objects).flatten
      else
        [self]
      end
    end

    # Yields all expression objects in LR depth first evaluation order.
    def yield_objects(&block)
      @args.each { |arg| arg.yield_objects(&block) unless arg.respond_to?(:no_emit) and arg.no_emit } if @args
      yield self
    end
  end

  class EmptyLiteral
    include Singleton

    def +(o)
      if o.is_a?(String)
        o
      elsif o.is_a?(EmptyLiteral)
        self
      else
        raise "undefined method `+' for empty literal: #{self.inspect} + #{o.inspect}"
      end
    end

    def to_s
      ''
    end

    def to_str
      ''
    end
  end

  class Literal < Expression
    attr_reader :value
    attr_accessor :no_emit

    def initialize(args)
      @no_emit = false

      if args.is_a?(NilClass)
        @value = [EmptyLiteral.instance]
      elsif args.is_a?(String)
        @value = [args]
      elsif args.is_a?(Set)
        @value = [args]
      else
        if args.all? { |a| a.is_a?(String) or a.is_a?(NilClass) or a.is_a?(EmptyLiteral) }
          @value = args.map { |a| (a.nil? or a.is_a?(EmptyLiteral)) ? EmptyLiteral.instance : a }
        elsif args.all? { |a| a.is_a?(Set) }
          @value = args
        else
          raise "Invalid literal #{args.inspect}"
        end
      end
    end

    def set_valued?
      @value.all? { |a| a.is_a?(Set) }
    end

    def arity; @value.length end

    def type; :string end

    def to_s
      unless set_valued?
        "[#{@value.map { |e| e.is_a?(EmptyLiteral) ? 'nil' : "\"#{e}\"" }.join(', ')}]"
      else
        "[#{@value.map { |e| "{#{e.to_a.join(', ')}}" }.join(', ')}]"
      end
    end
  end

  class Chain < Expression
    prototype :left, :right

    def arity; left.arity + right.arity end

    def optimise
      l, r = left.optimise, right.optimise

      if l.class == Mapping and r.class == Mapping
        Mapping.new(Chain.new(l.upper_level, r.upper_level).optimise,
                    Chain.new(l.lower_level, r.lower_level).optimise).optimise
      else
        if l.class == Literal and r.class == Literal
          Literal.new(l.value + r.value)
        elsif l.class == Cons and r.class == Cons and l.left.to_s == r.left.to_s
          # Eliminate common sub-expression in cons
          Cons.new(l.left, Chain.new(l.right, r.right).optimise).optimise
        else
          Chain.new(l, r)
        end
      end
    end
  end

  class Cons < Expression
    prototype :left, :right

    #FIXME: check that both L and R are set valued or not (using types?)

    def optimise
      l, r = left.optimise, right.optimise

      if l.is_a?(Literal) and r.is_a?(Literal) 
        if l.arity == 1 and r.arity == 1
          Literal.new(l.value + r.value)
        elsif l.arity == 1
          Literal.new(r.value.map { |x| l.value.first + x })
        elsif r.arity == 1
          Literal.new(l.value.map { |x| x + r.value.first })
        elsif l.arity == r.arity
          Literal.new(l.value.zip(r.value).map { |x, y| x + y })
        else # give up
          Cons.new(l, r)
        end
      else
        Cons.new(l, r)
      end
    end
  end

  class Union < Expression
    prototype :left, :right

    def optimise
      Union.new(left.optimise, right.optimise)
    end
  end

  class Rule < Expression
    def type; :rule end
  end

  class Subst < Expression
    prototype :string, :from, :to

    def arity; string.arity end

    def type
      raise "Invalid type #{string.type} for expression #{string}" unless string.type == :string
      raise "Invalid type #{from.type} for expression #{rule}" unless from.type == :string
      raise "Invalid type #{to.type} for expression #{rule}" unless to.type == :string
      :string
    end
  end

  class Replacement < Expression
    prototype :string, :from, :to, :left_context, :right_context

    def arity; string.arity end

    def optimise; Replacement.new(string.optimise, from, to, left_context, right_context) end

    def type
      raise "Invalid type #{string.type} for expression #{string}" unless string.type == :string
#      raise "Invalid type #{rule.type} for expression #{rule}" unless rule.type == :string
      :string
    end
  end

  class Filter < Expression
    prototype :string, :rule

    def arity; string.arity end

    def optimise; Filter.new(string.optimise, rule) end

    def type
      rule.no_emit = true

      raise "Invalid type #{string.type} for expression #{string}" unless string.type == :string
#      raise "Invalid type #{rule.type} for expression #{rule}" unless rule.type == :string
      :string
    end
  end

  class RegularExpression < Expression
    prototype :expression

    def arity; 1 end

    def type; :string end
  end

  class Lexicon < Expression
    prototype

    def arity; 1 end
  end

  class Guess < Expression
    prototype

    def arity; 1 end
  end

  class Mapping < Expression
    prototype :upper_level, :lower_level

    def optimise; Mapping.new(upper_level.optimise, lower_level.optimise) end
  end

  class ClassExpression
    attr_reader :arity

    def initialize(expr)
      Treetop.load File.join(File.dirname(__FILE__), "morphology_description_grammar")

      parser = MorphologyDescriptionParser.new
      m = parser.parse(expr)
      if m
        ev = m.evaluate
        pre_optimisation_arity = ev.arity

        @ev = ev.optimise
        @arity = @ev.arity
        raise "Assertion failed: pre_optimisation_arity == @arity" unless pre_optimisation_arity == @arity

        raise "Type checking failed" unless @ev.type == :string
      else
        raise "Error parsing expression #{expr}"
      end
    end

    def to_s
      "#{@ev}^#{@ev.arity}"
    end

    def expression_objects; @ev.expression_objects end

    def yield_objects(&block); @ev.yield_objects(&block) end
  end
end

if $0 == __FILE__
  require 'test/unit'
  include ClassBasedMorphology

  class ClassExpressionTestCase < Test::Unit::TestCase
    EXPR1 = 'mapping(cons(["<NOM>", "<ACC>", "<DAT>"], "<NOUN>"), filter(cons(union(guess(), lexicon()), cons(["a", nil,"v"], "y")), "a"))'
    EXPR1_OPTIMISED_S = 'mapping(["<NOM><NOUN>", "<ACC><NOUN>", "<DAT><NOUN>"], filter(cons(union(guess(), lexicon()), ["ay", "y", "vy"]), ["a"]))^3'
    EXPR2 = 'chain(mapping(cons(["<NOM>", "<ACC>", "<DAT>"], "<NOUN>"), 
                           cons(union(guess(), lexicon()), 
                                ["a", nil,"v"])), 
                   mapping(cons(["<INS>", "<LOC>"], "<NOUN>"), 
                           cons(union(guess(), lexicon()), 
                                ["i", "y"])))'
    EXPR2_OPTIMISED_S = 'mapping(["<NOM><NOUN>", "<ACC><NOUN>", "<DAT><NOUN>", "<INS><NOUN>", "<LOC><NOUN>"], cons(union(guess(), lexicon()), ["a", nil, "v", "i", "y"]))^5'

    def test_parse
      m = ClassExpression.new(EXPR1)
    end

    def test_parses
      m = ClassExpression.new('mapping(cons(cons("VERB", ["1 SIN", "2 SIN", "3 SIN", "1 DUA", "2 DUA", "3 DUA", "1 PLU", "2 PLU", "3 PLU"]), "PRES"), cons(replacement(subst(union(guess(), lexicon()), "ǫti", nil), "", "", "", ""), cons([nil, "e", "e", "e", "e", "e", "e", "e", "ǫ"], ["ǫ", "ši", "tŭ", "vě", "ta", "te", "mŭ", "te", "tŭ"])))')
      m = ClassExpression.new('mapping(cons({VERB}, chain([{INFINITIVE}], cons({PRESENT, INDICATIVE},
                                                                       chain(cons({SIN}, [{1}, {2}, {3}]), 
                                                                             chain(cons({DUA}, [{1}, {2}, {3}]), 
                                                                                   cons({PLU}, [{1}, {2}, {3}])))))), chain(cons(replacement(subst(union(guess(), lexicon()), "nǫti", "n"), "", "j", "[#vowels#]", ""), "ti"), cons(replacement(subst(union(guess(), lexicon()), "nǫti", "n"), "", "j", "[#vowels#]", ""), cons([nil, "e", "e", "e", "e", "e", "e", "e", "ǫ"], ["ǫ", "ši", "tŭ", "vě", "ta", "te", "mŭ", "te", "tŭ"]))))')

      m = ClassExpression.new('mapping(cons({VERB}, chain(chain(chain(chain({PRESENT, INFINITIVE}, cons({PRESENT, INDICATIVE}, [{1, SIN}, {2, SIN}, {3, SIN},
                                                                  {1, DUA}, {2, DUA}, {3, DUA},
                                                                  {1, PLU}, {2, PLU}, {3, PLU}])), cons({IMPERFECT, INDICATIVE}, [{1, SIN}, {2, SIN}, {3, SIN}, 
                                                                  {1, DUA}, {2, DUA}, {3, DUA},
                                                                  {1, PLU}, {2, PLU}, {3, PLU}])), cons({AORIST, INDICATIVE}, [{1, SIN}, {2, SIN}, {3, SIN}, 
                                                                  {1, DUA}, {2, DUA}, {3, DUA},
                                                                  {1, PLU}, {2, PLU}, {3, PLU}])), cons({PRESENT, IMPERATIVE}, [{2, SIN}, {3, SIN}, 
                                                                  {1, DUA}, {2, DUA}, {3, DUA},
                                                                  {1, PLU}, {2, PLU}]))), chain(chain(chain(chain(cons(replacement(subst(union(guess(), lexicon()), "ati", nil), "", "j", "[#vowels#]", ""), "ati"), cons(replacement(subst(union(guess(), lexicon()), "ati", nil), "", "j", "[#vowels#]", ""), cons([nil, "e", "e", "e", "e", "e", "e", "e", "ǫ"], ["ǫ", "ši", "tŭ", "vě", "ta", "te", "mŭ", "te", "tŭ"]))), cons(replacement(subst(union(guess(), lexicon()), "ati", nil), "", "j", "[#vowels#]", ""), cons("ě", ["axŭ", "aše", "aše", "axově", "ašeta", "ašete", "axomŭ", "ašete", "axǫ"]))), cons(replacement(subst(union(guess(), lexicon()), "ati", nil), "", "j", "[#vowels#]", ""), cons(nil, ["xŭ", nil, nil, "xově", "sta", "ste", "xomŭ", "ste", "šę"]))), cons(replacement(subst(union(guess(), lexicon()), "ati", nil), "", "j", "[#vowels#]", ""), cons(["i", "i", "i", "i", "i", "i", "i"], [nil, nil, "vě", "ta", "te", "mŭ", "te"]))))')
    end

    def test_optimisation
      m = ClassExpression.new(EXPR1)
      assert_equal EXPR1_OPTIMISED_S, m.to_s
    end

    def test_expression_objects
      m = ClassExpression.new(EXPR1)
      assert_equal ["mapping", "literal", "filter", "cons", "union", "guess", "lexicon", "literal", "literal"],
        m.expression_objects.map(&:name)
    end

    def test_yield_objects
      m = ClassExpression.new(EXPR1)
      os = []
      m.yield_objects { |o| os << o }
      assert_equal ["literal", "guess", "lexicon", "union", "literal", "cons", "filter", "mapping"], os.map(&:name)
    end

    def test_chain
      m = ClassExpression.new(EXPR2)
      assert_equal EXPR2_OPTIMISED_S, m.to_s
    end
  end
end
