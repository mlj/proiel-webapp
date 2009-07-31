module LowLevelHelper
  def low_level_data_table(object, *methods)
    markaby do
      table.low_level_data do
        thead do
          tr do
            th "Field"
            th "Value"
          end
        end

        tbody do
          methods.each do |method|
            value = object.send(method)

            case value
            when Hash
              value = value.inspect
            when ActiveRecord::Base
              value = "#{value.to_s} (#{value.id})"
            when NilClass
              value = ''
            else
              value = value.to_s
            end

            field = case method
                    when :id
                      'ID'
                    when :foreign_ids
                      'Foreign IDs'
                    when :morph_features
                      'Morph-features'
                    else
                      method.humanize.capitalize
                    end

            tr do
              td field + ':'

              case method.to_s
              when /language|presentation|relation|morphology|lemma/, /_(sort|at|by|key|ids|features|state|fields)$/
                td.tag value
              else
                td value
              end
            end
          end
        end
      end
    end
  end
end
