class User < ActiveRecord::Base
  model_stamper

  belongs_to :role
  has_many :assigned_sentences, :class_name => 'Sentence', :foreign_key => 'assigned_to'
  has_many :audits
  has_many :notes, :as => :originator

  validates_presence_of :login, :message => 'cannot be blank.'
  validates_uniqueness_of :login, :case_sensitive => false, :message => 'already exists. Please choose a different login.'
  validates_length_of :login, :within => 3..40
  validates_presence_of :first_name, :message => 'cannot be blank.'
  validates_presence_of :last_name, :message => 'cannot be blank.'

  serialize :preferences

  devise :authenticatable, :confirmable, :recoverable, :rememberable,
    :trackable, :validatable, :registerable

  attr_accessible :login, :first_name, :last_name, :email, :password, :password_confirmation

  # Returns the user's full name.
  def full_name
    "#{first_name} #{last_name}"
  end

  # Role management
  def has_role?(r)
    case r
    when :reader
      role.code.to_sym == :reader || has_role?(:annotator)
    when :annotator
      role.code.to_sym == :annotator || has_role?(:reviewer)
    when :reviewer
      role.code.to_sym == :reviewer || has_role?(:administrator)
    when :administrator
      role.code.to_sym == :administrator
    end
  end

  def first_assigned_sentence
    assigned_sentences.first
  end

  def shift_assigned_sentence!
    returning(assigned_sentences.first) do |s|
      s.assigned_to = nil
      s.save!
    end
  end

  def to_s
    login
  end

  protected

  def self.search(query, options = {})
    options[:conditions] = ["login LIKE ?", "%#{query}%"] unless query.blank?
    options[:order] = 'login ASC'

    paginate options
  end
end
