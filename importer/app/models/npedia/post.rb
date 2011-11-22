#
# ABOUT: Post is parent of ForumPost and grandparent of TalkPost.
# 
class Post < ActiveRecord::Base

  has_many :children, :class_name => "Post", :foreign_key => "parent_id", :order => "id"
  #TODO: vote associations need optimising some day!!
  has_many :votes_up, :class_name => "Vote", :finder_sql => 'SELECT * FROM votes WHERE source_id = #{self.id} AND source_type = \'#{self.class.to_s}\' AND vote_type=\'up\' '
  has_many :votes_down, :class_name => "Vote", :finder_sql => 'SELECT * FROM votes WHERE source_id = #{self.id} AND source_type = \'#{self.class.to_s}\' AND vote_type=\'down\' '

  belongs_to :user
  belongs_to :parent, :class_name => "Post", :foreign_key => "parent_id", :counter_cache => :child_count

  before_save :set_nesting_attributes
  validates_presence_of :user_id, :body, :only => 'create'

  def editable_by?(user)
    user && user != 0 && (user.id == user_id || user.admin?)
  end
  
  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :title_title << :forum_name
    super
  end

  def generate_body_html
    self.body_html = self.body.wikify
  end

  def is_nestable?
    true
  end

  def first_post?
    first_post_flag == 1
  end

  def first_post
     first_post?
  end
  
  def first_post=(value)
    self.first_post_flag = (value == "1" ? true : false )
  end

  protected
    def self.find_nested(parent_col='collection_id', parent_id=nil, maxrecs=25, page=1)
      sql = [ "SELECT posts.*, CONCAT(path, '/', LPAD(posts.id, 6, '0')) AS lineage, users.display_name, users.email, users.login, users.identity_url FROM posts INNER JOIN users ON users.id = posts.user_id WHERE (posts.#{parent_col} = ?) AND deleted_at IS NULL ORDER BY lineage ASC", parent_id ]
      self.paginate_by_sql(sql, :page => page, :per_page => per_page)
    end

    def set_nesting_attributes
      # Set post nesting params
      parent_post = Post.find_by_id(self.parent_id)
      if !parent_post.nil?
        #Padding zeros up to 6 digits supports 999,999 records safely
        parent_post.path = "" if parent_post.path.nil? #Path cannot be NULL, but can be blank
        self.path = parent_post.path + '/' + "%06d" % parent_post.id.to_s
        self.depth = parent_post.depth + 1
        self.parent_id = parent_post.id
      else
        self.path = ""
      end
      generate_body_html
    end
end