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

            if value
              case method
              when :reference_fields
                value = value.inspect
              else
                value = value.to_s
              end
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
              when "language", "presentation", /_(at|by|key|ids|features|state|fields)$/
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
