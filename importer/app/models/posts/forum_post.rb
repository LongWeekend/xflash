#
# ABOUT: All posts in forums are from this class
# 
class ForumPost < Post
	
  belongs_to :topic, :class_name => "ForumTopic", :foreign_key => "collection_id", :counter_cache => :child_count
  belongs_to :user, :counter_cache => :forum_posts_count
  has_many :votes, :foreign_key => "source_id", :conditions => { :source_type => "ForumPost" }

  # These might break!
  after_create  { |r| ForumTopic.update_all(['last_activity_at = ?, last_activity_by = ?, last_child_id = ?', r.created_at, r.user_id, r.id], ['id = ?', r.collection_id]) }
  after_destroy { |r| t = ForumTopic.find(r.collection_id); ForumTopic.update_all(['last_activity_at = ?, last_activity_by = ?, last_post_id = ?', t.posts.last.created_at, t.posts.last.user_id, t.posts.last.id], ['id = ?', t.id]) if t.posts.last }
  before_create  :set_first_post_flag

  validates_presence_of :user, :body, :topic
  alias_method :base_editable_by?, :editable_by?
  attr_readonly :first_post_flag

  def editable_by?(user)
    (base_editable_by?(user) || user && user !=0 && (user.forum_moderator_of?(topic.parent_id) || self.topic.answerable? and self.topic.user_id == user.id and self.first_post_flag != 1) )
  end

	def solution?
		self.topic.solution_post_id == self.id
	end
  
  def self.find_nested(collection_id, num, page)
    #ForumPosts attach to topics
    super('collection_id', collection_id, num, page)
  end
  
  protected
    def set_first_post_flag
      if self.topic.posts.count == 0
        self.first_post_flag = 1
      else
        self.first_post_flag = 0
      end
    end
end