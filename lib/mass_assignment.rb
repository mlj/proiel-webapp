#!/usr/bin/env ruby
#
# mass_assignment.rb - Low-level mass assignment functions intended for occasional maintenance
#
# Written by Marius L. Jøhndal, 2008.
#
require 'config/environment'

class MassAssignment
  # Number of objects to process per database request.
  CHUNK_SIZE = 500

  def initialize(klass)
    raise ArgumentError, "not a subclass of ActiveRecord::Base" unless klass < ActiveRecord::Base

    @klass = klass
  end

  protected

  # Iterates all objects in chunks. The function handles modification of the data during
  # iteration by constantly checking for the total number of matching rows.
  def chunked_each(options = {}, &block)
    total = @klass.count(options)
    n = total / CHUNK_SIZE + 1 # go +1 rounds to grab the fractional part as well
    n.times do |i|
      @klass.find(:all, options.merge({ :offset => i * CHUNK_SIZE, :limit => CHUNK_SIZE })).each(&block)

      # The data set may have changed. If so, start over from scratch.
      chunked_each(options, &block) if @klass.count(options) != total
    end
  end
end

class MassTokenAssignment < MassAssignment
  def initialize
    super(Token)
  end

  # Changes the value of one morphological field from one value to another for all tokens.
  # The operation is transactional. The operation can be applied to any morphological
  # attribute in the Token model by overriding the +attribute+ argument. If +old_value+
  # is nil, all values will be reassigned.
  def reassign_morphology!(field, old_value, new_value, attribute = "morphtag", lemma_id = nil)
    raise ArgumentError, "attribute must be one of 'morphtag' or 'source_morphtag'" unless attribute == 'morphtag' or attribute == 'source_morphtag'

    Token.transaction do
      pattern = PROIEL::MorphTag.new({ field => old_value }).to_sql_pattern
      param = "#{attribute} LIKE '#{pattern}'"
      param += " AND lemma_id = #{lemma_id}" if lemma_id
      chunked_each(:conditions => param) do |t|
        m = PROIEL::MorphTag.new(t.send(attribute))
        n = m.dup
        n[field] = new_value
        unless m.to_s == n.to_s
          puts "Reassigning #{field} of attribute #{attribute} for token #{t.id}: #{m} → #{n}"
          t.send("#{attribute}=", n.to_s)
          begin
            t.save!
          rescue Exception => e
            raise "Token #{t.id}: #{e}"
          end
        end
      end
    end
  end
end

class MassAuditAssignment < MassAssignment
  def initialize
    super(Audit)
  end

  # Removes all entries that pertain to changes to a specific attribute of a particular model. The
  # operation is transactional.
  def remove_attribute!(model, attribute)
    Audit.transaction do
      chunked_each do |change|
        if change.auditable_type == model and change.action != 'destroy' and change.changes[attribute]
          puts "Removing attribute #{model}.#{attribute} from audit #{change.id}"
          change.changes.delete(attribute)
          change.save!
        end
      end
    end
  end
end
