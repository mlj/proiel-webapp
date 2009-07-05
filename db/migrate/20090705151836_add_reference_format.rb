class AddReferenceFormat < ActiveRecord::Migration
  def self.up
    add_column :sources, :reference_format, :string, :limit => 256, :null => false

    Source.find_each do |s|
      s.reference_format = { :source => '#title#', :source_division => '#title#, #book#', :sentence => '#title#, #book# #chapter#' }
      s.save_without_validation!
    end
  end

  def self.down
    remove_column :sources, :reference_format
  end
end
