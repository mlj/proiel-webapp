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

  def chunked_each(options = {}, &block)
    total = @klass.count(options)
    (total / CHUNK_SIZE + 1).times do |i|
      options.merge!({ :offset => i * CHUNK_SIZE, :limit => CHUNK_SIZE })
      @klass.find(:all, options).each(&block)
    end
  end
end

class MassTokenAssignment < MassAssignment
  def initialize
    super(Token)
  end

  # Changes the value of one morphological field from one value to another for all tokens.
  # The operation is transactional.
  def reassign_morphology!(field, old_value, new_value)
    Token.transaction do
      pattern = PROIEL::MorphTag.new({ field => old_value }).to_sql_pattern

      chunked_each(:conditions => ["morphtag LIKE ?", pattern]) do |t|
        m = PROIEL::MorphTag.new(t.morphtag)
        n = m.dup
        n[field] = new_value

        puts "Reassigning #{field} for token #{t.id}: #{m} → #{n}"

        t.morphtag = n.to_s
        t.save!
      end
    end
  end
end
