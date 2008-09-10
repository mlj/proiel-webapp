require 'digest/sha1'
class User < ActiveRecord::Base
  model_stamper

  belongs_to :role
  has_many :bookmarks
  has_many :audits
  has_many :notes, :as => :originator
  has_many :annotated_sentences, :class_name => 'Sentence', :foreign_key => :annotated_by
  has_many :reviewed_sentences, :class_name => 'Sentence', :foreign_key => :reviewed_by
  # More efficient alternative to 
  #   annotated_sentences.to_a.sum { |sentence| sentence.dependency_tokens.count } %
  has_many :annotated_tokens, :class_name => 'Token', :counter_sql => 'SELECT count(*) FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id WHERE annotated_by = #{id} AND sort != "punctuation"' 
  # More efficient alternative to 
  #   reviewed_sentences.to_a.sum { |sentence| sentence.dependency_tokens.count } %
  has_many :reviewed_tokens, :class_name => 'Token', :counter_sql => 'SELECT count(*) FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id WHERE reviewed_by = #{id} AND sort != "punctuation"' 

  serialize :preferences

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :message => 'cannot be blank.'
  validates_presence_of     :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :case_sensitive => false, :message => 'already exists. Please choose a different login.'
  validates_presence_of     :first_name, :message => 'cannot be blank.'
  validates_presence_of     :last_name, :message => 'cannot be blank.'
  before_save :encrypt_password

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :first_name, :last_name

  # Returns the user's full name
  def full_name
    "#{first_name} #{last_name}"
  end

  acts_as_state_machine :initial => :pending
  state :passive
  state :pending, :enter => :make_activation_code
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete

  event :register do
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end
  
  event :activate do
    transitions :from => :pending, :to => :active 
  end

  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end

  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end

    def make_activation_code
      self.deleted_at = nil
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def do_delete
      self.deleted_at = Time.now.utc
    end

    def do_activate
      @activated = true
      self.activated_at = Time.now.utc
      self.deleted_at = self.activation_code = nil
    end

  protected
    def self.search(query, options = {})
      options[:conditions] = ["login LIKE ?", "%#{query}%"] unless query.blank?
      options[:order] = 'login ASC'

      paginate options
    end

  public
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
end
