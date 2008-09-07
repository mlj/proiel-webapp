class Language < ActiveRecord::Base
  has_many :lemmata
  has_many :sources

  validates_presence_of :iso_code
  validates_length_of :iso_code, :within => 2..3
  validates_uniqueness_of :iso_code
  validates_presence_of :name
  validates_uniqueness_of :name

  # Returns inferred morphology for a word form in the language.
  def guess_morphology(form, existing_tags)
    TAGGER.tag_token(iso_code, form, existing_tags)
  rescue Exception => e
    logger.error { "Tagger failed: #{e}" }
    [:failed, nil]
  end

  protected

  def self.search(query, options)
    options[:conditions] ||= ["name LIKE ?", "%#{query}%"]
    options[:order] ||= "name ASC"

    paginate options
  end
end
