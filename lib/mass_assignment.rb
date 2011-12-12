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

  # Changes the value of the +source_morphology_tag+ attribute from one
  # value to another for all tokens.  If +old_value+ is nil, all
  # values will be reassigned.
  def reassign_source_morphology!(field, old_value, new_value)
    Token.transaction do
      pattern = MorphFeatures.new(",,lat", nil)
      pattern.send("#{field}=", old_value)
      pattern = pattern.morphology_as_sql_pattern
      param = "#{attribute} LIKE '#{pattern}'"
      chunked_each(:conditions => param) do |t|
        m = t.source_morph_features
        n = m.dup
        n.send("#{field}=", new_value)
        unless m == n
          puts "Reassigning #{field} for token #{t.id}: #{m} → #{n}"
          t.source_morph_features = n
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
