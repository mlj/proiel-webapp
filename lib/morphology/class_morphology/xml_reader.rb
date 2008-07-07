#!/usr/bin/env ruby
#
# class_morphology.rb - Inheritance based paradigmatic morphology
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'hpricot'
require 'open-uri'

# TODO: automatically validate definition files

module Logos
  module ClassMorphology
    # An exception raised for invalid syntax in a definiton file.
    class DefinitionError < Exception; end

    FunctionCall = Struct.new(:name, :arguments)
    VariableReference = Struct.new(:name)
    LiteralValue = Struct.new(:value)

    # An abstract definition. The namespace for definitions is global
    # but distinct for variables, constants and classes.
    class Definition 
      def self.assert_unique_element(e, element_name, optional = false)
        l = (e/element_name.to_sym)
        raise DefinitionError, "Multiple '#{element_name}' elements" if l.length > 1
        raise DefinitionError, "Expected a single '#{element_name}' element" unless l.length == 1 or optional
        l.first ? l.first : nil
      end

      def self.assert_text_attribute(e, attribute_name, optional = false)
        value = e.attributes[attribute_name.to_s]
        raise DefinitionError, "Element without attribute '#{attribute_name}'" unless value or optional 
        case value
        when NilClass
          nil
        else
          value.to_s
        end
      end

      def self.assert_boolean_attribute(e, attribute_name, optional = false)
        value = e.attributes[attribute_name.to_s]
        raise DefinitionError, "Element without attribute '#{attribute_name}'" unless value or optional 
        case value
        when NilClass
          nil
        when true, "true"
          true
        when false, "false"
          false
        else
          raise DefinitionError, "Invalid value for boolean attribute '#{attribute_name}'"
        end
      end
    end

    VariableDefinition = Struct.new(:name, :body)
    ConstantDefinition = Struct.new(:name, :value)

    class ClassDefinition
      attr_reader :abstract

      def initialize(name, body)
        @name = name

        @variables = {}
        (body/:variable).each do |e| 
          name = Definition.assert_text_attribute(e, "name")
          @variables[name] = VariableDefinition.new(name, e.inner_html)
        end

        @superclass = body.attributes["inherits"]
        @abstract = Definition.assert_boolean_attribute(body, "abstract", true) || false
        @unproductive = Definition.assert_boolean_attribute(body, "unproductive", true) || false
      end

      def expand(variable, start_class, classes)
        if @variables[variable]
          s = @variables[variable].body

          macros = {}
          s.scan(/\!([a-z-]+)\!/).each do |id|
            id = id.first

            case id
            when 'input'
              macros[id] = input_expression
            when 'super'
              spr = superclass(classes)
              raise "#{@name}: Invalid use of !super! Class has no superclass" unless spr
              macros[id] = spr.expand(variable, start_class, classes)
            else
              macros[id] = start_class.expand(id, start_class, classes)
            end
          end

          macros.each_pair { |id, body| s = s.gsub("!" + id + "!", body) }

          s
        elsif s = superclass(classes)
          s.expand(variable, start_class, classes)
        else
          raise "#{@name}: Invalid variable #{variable.inspect}"
        end
      end

      def superclass(classes)
        if @superclass
          s = classes[@superclass]
          raise "Unknown superclass" unless s
          s
        else
          nil
        end
      end

      def input_expression
        if @unproductive
          'lexicon()'
        else
          'union(guess(), lexicon())'
        end
      end
    end

    # A wrapper around the entire "program" definition.
    class ProgramDefinition < Hash
      def initialize(file_name)
        doc = Hpricot.XML(open(file_name))
        body = Definition.assert_unique_element(doc, "morphology")

        @name = Definition.assert_text_attribute(body, "name")
        @forms = Definition.assert_text_attribute(body, "forms", true)
        @tags = Definition.assert_text_attribute(body, "tags", true)

        @constants = {}
        (body/:symbols/:symbol).each do |e| 
          name = Definition.assert_text_attribute(e, "name")
          @constants[name] = ConstantDefinition.new(name, e.inner_html)
        end

        @classes = {}
        (body/:classes/:class).each do |e| 
          name = Definition.assert_text_attribute(e, "name")
          @classes[name] = ClassDefinition.new(name, e)
        end

        # Compute the evaluations for each concrete class.
        @classes.each_pair do |n, d|
          next if d.abstract
          tags = d.expand(@tags, d, @classes)
          forms = d.expand(@forms, d, @classes)
          self.store(n, "mapping(#{tags}, #{forms})")
        end
      end

      def to_s
        s = ''
        each_pair { |n, d| s += "#{n} = #{d}\n" }
        s
      end
    end
  end
end
