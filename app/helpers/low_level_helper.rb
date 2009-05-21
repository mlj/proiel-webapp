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
            value = value.to_s if value

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

              case method
              when :morph_features, :sort_key, :foreign_ids, :language
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
