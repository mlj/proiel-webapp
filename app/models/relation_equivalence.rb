# Relation equivalences are subsumption relationships between
# relations. The superrelation is more general than the subrelation
# and should be used whenever it is unclear which of the subrelations
# is the correct one.

class RelationEquivalence < ActiveRecord::Base
  has_and_belongs_to_many :subrelation, :class_name => 'Relation', :foreign_key => 'subrelation_id'
  has_and_belongs_to_many :superrelation, :class_name => 'Relation', :foreign_key => 'superrelation_id'
end
