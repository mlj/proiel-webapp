#
# searchable.rb - Simple generic free-text searches for Active Record models
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'enumerator'

module Searchable
  module ClassMethods
    # Adds a named scope <tt>:search_on</tt> to the class it was invoked on.
    #
    # This named scope should be invoked with a query. The following should
    # illustrate the simple query language used.Given the following data set
    #
    #   "dog", "donkey", "cat", "horse", "sleepy dog"
    #
    # These queries will produce the result on the left
    #
    #   dog cat horse      → "dog", "cat", "horse"
    #   "sleepy dog" horse → "sleepy dog", "horse"
    #   do*                → "dog", "donkey"
    #   do? cat            → "dog", "cat"
    #   *do?               → "dog", "sleepy dog"
    #   "* dog"            → "sleepy dog"
    #
    def searchable_on(*fields)
      self.cattr_accessor :searchable_fields
      self.searchable_fields = fields
      self.named_scope :search_on, lambda { |keywords| { :conditions => self.build_searchable_conditions(keywords) } }
    end

    def parse_search_expression(expression)
      expression.scan(/"([^"]*)"|(\S+)/).flatten.compact
    end

    # Returns conditions for a search expression.
    def build_searchable_conditions(expression)
      if expression.blank?
        nil
      else
        search_terms = parse_search_expression(expression)

        terms = {}
        clauses = search_terms.enum_with_index.map do |search_term, index|
          term_name = "term_#{index}".to_sym
          if search_term[/[*?]/] # this is a LIKE-term
            terms[term_name] = search_term.gsub('*', '%').gsub('?', '_')
            build_like_conditions(term_name)
          else # this is an EQUAL-term
            terms[term_name] = search_term
            build_equal_conditions(term_name)
          end
        end.flatten.join(' OR ')

        [clauses, terms]
      end
    end

    # Returns LIKE conditions for each searchable field for the search term identified with
    # the term +term_name+.
    def build_like_conditions(term_name)
      map_searchable_field do |field_name|
        "#{field_name} LIKE :#{term_name}"
      end
    end

    # Returns EQUAL conditions for each searchable field for the search term identified with
    # the term +term_name+.
    def build_equal_conditions(term_name)
      map_searchable_field do |field_name|
        "#{field_name} = :#{term_name}"
      end
    end

    # Maps searchable field to a block invoked with the qualified field name.
    def map_searchable_field(&block)
      self.searchable_fields.map do |field|
        qualified_field_name = connection.quote_table_name(table_name) + "." + connection.quote_column_name(field)
        block.call(qualified_field_name)
      end
    end
  end
end

ActiveRecord::Base.send(:extend, Searchable::ClassMethods)
