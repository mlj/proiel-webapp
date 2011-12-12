class CorrectAuditEncoding < ActiveRecord::Migration
  def up
    Audit.find_each do |a|
      if a.audited_changes
        %w(form lemma short_gloss full_gloss contents presentation presentation_before presentation_after).select do |k|
          a.audited_changes.has_key?(k)
        end.each do |k|
          case a.audited_changes[k]
          when NilClass
            a.audited_changes.delete(k)
          when String
            a.audited_changes[k].force_encoding("UTF-8")
          when Array
            x, y = a.audited_changes[k]

            x.force_encoding("UTF-8") unless x.nil? or x.to_s.nil?
            y.force_encoding("UTF-8") unless y.nil? or y.to_s.nil?

            if x == y
              a.audited_changes.delete(k)
            else
              a.audited_changes[k] = [x, y]
            end
          end

          a.save
        end
      end
    end
  end

  def down
  end
end
