class Language < ActiveRecord::Base
  has_many :lemmata
  has_many :sources
  has_many :inflections

  validates_presence_of :iso_code
  validates_length_of :iso_code, :is => 3
  validates_uniqueness_of :iso_code
  validates_presence_of :name
  validates_uniqueness_of :name

  # Returns inferred morphology for a word form in the language.
  #
  # ==== Options
  # <tt>:ignore_instances</tt> -- If set, ignores all instance matches.
  # <tt>:force_method</tt> -- If set, forces the tagger to use a specific tagging method,
  #                          e.g. <tt>:manual_rules</tt> for manual rules. All other
  #                          methods are disabled.
  def guess_morphology(form, existing_tags, options = {})
    TAGGER.tag_token(iso_code.to_sym, form, existing_tags)
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
