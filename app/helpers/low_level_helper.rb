module LowLevelHelper
  def validation_stamp(object)
    if object.valid?
      ''
    else
      image_tag 'invalid.jpeg'
    end
  end

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
              when "presentation"
                td do
                  self << object.presentation_as_prettyprinted_code(:coloured => true)
                end
              when /language|relation|morphology|lemma/, /_(sort|at|by|key|ids|features|state|fields)$/
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
