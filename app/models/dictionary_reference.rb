class DictionaryReference < ActiveRecord::Base
  belongs_to :lemma
  belongs_to :dictionary_entry
end
