#
# ABOUT: Forum Topic class
# USAGE: Use the "tags" accessor method for setting tags
#
class ForumTopic < Collection

  belongs_to :forum, :foreign_key => "parent_id", :counter_cache => :child_count
  belongs_to :activity_by_user, :foreign_key => "last_activity_by", :class_name => "User"
  has_many :posts, :class_name =>"ForumPost", :foreign_key => "collection_id", :order => 'posts.created_at', :dependent => :destroy

  validates_presence_of :forum, :user, :description
  alias_method  :base_editable_by?, :editable_by?
  before_create :set_default_last_activity_at_and_sticky
  before_save   :check_for_changing_forums

  #thinking sphinx
=begin
  define_index do
    indexes title, :sortable => true
    indexes posts(:content), :as => :posts
    indexes created_at, :sortable => true
    has deleted_at
    has posts(:user_id), :as => :post_user_ids, :source => query
    ##has tags_by_scrap_page(:tag_id), :as => :tag_ids, :source => :query
    set_property :delta => true
  end
=end
  def check_for_changing_forums
    return if new_record?
    old = ForumTopic.find(id)
    if old.parent_id != parent_id
      set_post_forum_id
    end
  end

  def voice_count
    ForumPost.count(:all, :conditions => ["collection_id = ? ", self.id], :select => "DISTINCT user_id")
  end
  
  def editable_by?(user)
    ( base_editable_by?(user) || user && user !=0 && (user.id == self.user_id || user.admin? || (self.forum and user.forum_moderator_of?(self.forum.id)) ))
  end

  def sticky?
    self.sticky_flag==1
  end

  def sticky=(var)
    self.sticky_flag=var
  end

  def answerable=(var)
    self.answerable_flag=var
  end

  def answerable?
    self.answerable_flag==1
  end
  
  def deleted?
    !self.deleted_at.nil?
  end

  def forum_id
    self.parent_id
  end

  def forum_id=(var)
    self[:parent_id] = var.to_i
  end

  protected
    def set_default_last_activity_at_and_sticky
      self.last_activity_at = Time.now.utc
      self.sticky   ||= 0
    end

    def set_post_forum_id
      ForumPost.update_all ['collection_id = ?', id]
    end
end