module ActiveRecord
  module Validations
    module ClassMethods
      # Validates that the value of the specified attribute is on a particular Unicode Normalization
      # Form.
      #
      #   class Book < ActiveRecord::Base
      #     validates_unicode_normalization_of :author
      #     validates_unicode_normalization_of :editor, :form => :c
      #     validates_unicode_normalization_of :title, :message => 'Title is not on Unicode Normalization Form KC'
      #   end
      # 
      # Configuration options:
      # * <tt>:form</tt> - Specifies the normalization form to use. Valid normalization forms are <tt>:c</tt>, <tt>:d</tt>,
      #   <tt>:kc</tt>, and </tt>:kd</tt>.
      # * <tt>:message</tt> - Specifies a custom error message (default is: "is not on Unicode Normalization form %s").
      def validates_unicode_normalization_of(*attr_names)
        configuration = {
          :form      => :kc,
          :message   => 'is not on Unicode Normalization form %s',
        }
        configuration.update(attr_names.extract_options!)

        raise(ArgumentError, "Invalid normalization form") unless [:c, :kc, :d, :kd].include?(configuration[:form])

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message] % configuration[:form].to_s.upcase) unless value.nil? or value.mb_chars == value.mb_chars.normalize(configuration[:form])
        end
      end
    end
  end
end
