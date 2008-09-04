class Language < ActiveRecord::Base
  has_many :lemmata
  has_many :sources

  validates_presence_of :iso_code
  validates_length_of :iso_code, :within => 2..3
  validates_uniqueness_of :iso_code
  validates_presence_of :name
  validates_uniqueness_of :name

  protected

  def self.search(query, options)
    options[:conditions] ||= ["name LIKE ?", "%#{query}%"]
    options[:order] ||= "name ASC"

    paginate options
  end
end
