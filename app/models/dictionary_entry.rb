class DictionaryEntry < ActiveRecord::Base
  belongs_to :dictionary
  has_many :dictionary_references
end
