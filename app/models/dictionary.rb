class Dictionary < ActiveRecord::Base
  has_many :entries, :class_name => 'DictionaryEntry'
end
