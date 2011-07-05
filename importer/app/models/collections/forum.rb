#
# ABOUT: Forum class
# 
class Forum < Collection

  has_many :moderatorships, :foreign_key => "collection_id", :dependent => :destroy, :conditions => ['type = ?', Forum.to_s ]
  has_many :moderators, :foreign_key => "collection_id", :through => :moderatorships, :source => :user, :order => 'users.login'

  has_many :topics, :class_name =>"ForumTopic", :foreign_key => "parent_id", :order => 'sticky_flag desc, last_activity_at desc', :dependent => :destroy
  has_many :posts, :class_name =>"ForumPost", :through => :forum_topics, :order => 'posts.created_at desc'
  has_many :recent_topics, :class_name => 'ForumTopic', :foreign_key => "parent_id", :order => 'last_activity_at desc'

  validates_presence_of :user, :title, :description
  format_attribute :description

  def count_all_posts
    cnt=0
    self.topics.each { |t| cnt=cnt+t.posts.count }
    return cnt
  end

  def voice_count
    #broken!!! Forum.count(:all, :conditions => ["collection_id = ? and type = '?'", self.id, self.class.to_s], :select => "DISTINCT user_id")
    0
  end
end