class ImportSource < ActiveRecord::Base
  has_many :notes, :as => :notable

  def to_s
    tag
  end
end
