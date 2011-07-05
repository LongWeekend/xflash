require 'digest/sha1'
class User < ActiveRecord::Base

  has_many :moderatorships, :dependent => :destroy
  has_many :monitorships
  has_many :monitored_topics, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :order => 'collections.last_activity_at desc', :source => :forum_topic
  has_many :collections
  has_many :forums, :through => :moderatorships, :order => 'title'
  has_many :forum_topics
  has_many :scraps
  has_many :posts
  has_many :votes
  has_many :lists

	acts_as_tagger

  validates_presence_of :login, :email
  validates_length_of   :login, :minimum => 2
  
  with_options :if => :password_required? do |u|
    u.validates_presence_of     :password_hash
    u.validates_length_of       :password, :minimum => 5, :allow_nil => true
    u.validates_confirmation_of :password, :on => :create
    u.validates_confirmation_of :password, :on => :update, :allow_nil => true
  end

  # names that start with #s really upset me for some reason
  validates_format_of  :login, :with => /^[a-z]{2}(?:\w+)?$/i
  validates_format_of  :identity_url, :with => /^https?:\/\//i, :allow_nil => true
  validates_format_of  :display_name, :with => /^[a-z]{2}(?:[.'\-\w ]+)?$/i, :allow_nil => true
  validates_format_of  :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Please check the e-mail address is correct"[:msg_check_email_is_valid]
  validates_uniqueness_of  :login, :email, :case_sensitive => false
  validates_uniqueness_of  :display_name, :identity_url, :case_sensitive => false, :allow_nil => true

  before_validation { |u| u.identity_url = nil if u.identity_url.blank? }
  before_validation { |u| u.display_name = u.login if u.display_name.blank? }

  # Set defaults on create
  def before_create 
    # first user becomes admin automatically
    self.admin = self.activated = true if User.count == 0
		self.key = Digest::SHA1.hexdigest((object_id + rand(255)).to_s)
  end

  attr_reader :password
  attr_protected :admin, :posts_count, :login, :created_at, :updated_at, :last_login_at, :topics_count, :activated
  format_attribute :bio

  def self.currently_online
    User.find(:all, :conditions => ["last_seen_at > ?", Time.now.utc-5.minutes])
  end

  # We allow false to be passed in so a failed login can be checked
  # For an inactive account to show a different error
  def self.authenticate(login, password, activated=true)
    find_by_login_and_password_hash_and_activated(login, Digest::SHA1.hexdigest(password + PASSWORD_SALT), activated)
  end

  def self.search(query, options = {})
    with_scope :find => { :conditions => build_search_conditions(query) } do
      find :all, options
    end
  end

  def self.build_search_conditions(query)
    query && ['LOWER(display_name) LIKE :q OR LOWER(login) LIKE :q', {:q => "%#{query}%"}]
  end

  def password=(value)
    return if value.blank?
    write_attribute :password_hash, Digest::SHA1.hexdigest(value + PASSWORD_SALT)
    @password = value
  end
  
  def reset_login_key!
    self.login_key = Digest::SHA1.hexdigest(Time.now.to_s + password_hash.to_s + rand(123456789).to_s).to_s
    # this is not currently honored
    self.login_key_expires_at = Time.now.utc+1.year
    save!
    login_key
  end

	def public_hash_key!
		unless self.key?
  		self.key = Digest::SHA1.hexdigest((object_id + rand(255)).to_s)
			save!
		end
		key
	end

  def forum_moderator_of?(forum)
    moderatorships.count(:all, :conditions => ['collection_id = ? AND type = ?', (forum.is_a?(Forum) ? forum.id : forum), Forum.to_s]) == 1
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :email << :login_key << :login_key_expires_at << :password_hash << :identity_url
    super
  end
  
  def password_required?
    identity_url.nil?
  end
  
  def clean_website
    white_list(self.website.gsub("http://",""))
  end
end