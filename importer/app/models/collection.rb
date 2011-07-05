#
# ABOUT: Collection class, this is the core object for Npedia
#        Collections are containers/groups for other objects inherited from Collection / Srap / Post
#
class Collection < ActiveRecord::Base
  include Sluggable
  include LinkMethods
  include BaseKlassMethods
  acts_as_taggable

  has_many :taggings, :dependent => :destroy, :foreign_key => "taggable_id", :conditions => ['taggable_type = ?', Collection.to_s ]
  has_many :moderatorships, :dependent => :destroy, :conditions => ['type = ?', Collection.to_s ]
  has_many :moderators, :through => :moderatorships, :source => :user, :order => 'users.login'
  has_many :monitors, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :source => :user, :order => 'users.login'
  has_many :children, :dependent => :destroy, :class_name => "Collection", :foreign_key => "parent_id", :order => "id"
  has_many :votes, :dependent => :destroy, :foreign_key => "source_id", :conditions => ['source_type = ?', Collection.to_s ]
  has_many :posts, :dependent => :destroy
  has_many :scraps, :dependent => :destroy

  has_many :post_votes_down, :class_name => "Vote", :finder_sql =>
      'SELECT v.* FROM votes v, posts p ' +
      'WHERE p.collection_id = #{self.id} AND p.id = v.source_id AND v.source_type = p.type AND v.vote_type=\'down\' '

  has_many :post_votes_up, :class_name => 'Vote', :finder_sql =>
      'SELECT v.* FROM votes v, posts p ' +
      'WHERE p.collection_id = #{self.id} AND p.id = v.source_id AND v.source_type = p.type AND v.vote_type=\'up\' '

  has_many :scrap_votes_down, :class_name => 'Vote', :finder_sql =>
      'SELECT v.* FROM votes v, scraps s ' +
      'WHERE s.collection_id = #{self.id} AND s.id = v.source_id AND v.source_type = s.type AND v.vote_type=\'down\' '

  has_many :scrap_votes_up, :class_name => 'Vote', :finder_sql =>
      'SELECT v.* FROM votes v, scraps s ' +
      'WHERE s.collection_id = #{self.id} AND s.id = v.source_id AND v.source_type = s.type AND v.vote_type=\'up\' '

  belongs_to :parent, :class_name => "Collection", :foreign_key => :parent_id
  belongs_to :user

  attr_accessible :title, :description, :suspended_at, :deleted_at
  attr_readonly :id, :type, :sub_type, :user_id, :parent_id, :created_at

  validates_presence_of :title
  validates_uniqueness_of :title, :scope => :parent_id

	def tags=(val)
    self.tag_list = val.gsub(/[,|\;]/, TagList.delimiter).gsub(/[ ]+/, TagList.delimiter)
    self.tag_cache = self.tag_list.to_s #Uses plugin to add tag associations
	end

  def tags
    self.tag_cache
  end

  def views
    hits
  end

  def hit!
    self.class.increment_counter :hits, id
  end

  def paged?
    child_count > 25
  end
  
  def last_page
    (child_count.to_f / 25.0).ceil.to_i
  end

	def deleted
		if self.deleted_at.nil?
			return false
		else
			return true
		end
	end

	def deleted=(val)
		if val == "1"
			self.deleted_at = Time.now.utc
		else
			self.deleted_at = nil
		end
	end

  def sticky?
    sticky_flag == 1
  end

  def sticky
     self.sticky?
  end
  
  def sticky=(val)
    self.sticky_flag = (val == "1" ? true : false )
  end

	def answerable?
		self.answerable_flag == 1
	end
  
	def answerable
    self.answerable?
  end

  def answerable=(val)
    self.answerable_flag =  (val == "1" ? true : false )
  end

	def suspended?
		not self.suspended_at.nil?
	end

	def suspended
  	self.suspended?
  end

	def suspended=(val)
		if val == "1"
			self.suspended_at = Time.now.utc
		else
			self.suspended_at = nil
		end
	end  

  def title=(str)
    self[:title] = str.strip
    self.slug = self[:title]
  end

  def editable_by?(user)
    user && user != 0 && user.admin?
  end 
end
