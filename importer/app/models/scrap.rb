#
# ABOUT: Scrap object base class, all core assets are scraps
# USAGE: Use the "tags" accessor method for setting tags
#        save! method requires current_user object to ba passed in
# 
class Scrap < ActiveRecord::Base

  include Sluggable
  include HTMLDiff
  include SimpleDiff
  include LinkMethods
  include BaseKlassMethods
  include Yamlable
  acts_as_taggable_on :association, :tag

  has_many :taggings, :dependent => :destroy, :foreign_key => "taggable_id", :conditions => ['taggable_type = ?', Scrap.to_s ]
  has_many :votes, :dependent => :destroy, :foreign_key => "source_id", :conditions => ['source_type = ?', Scrap.to_s ]
  has_many :posts, :dependent => :destroy, :foreign_key => "scrap_id"
  has_many :revisions, :dependent => :destroy, :order => "revisions.created_at DESC", :include => :user
  has_many :index_revisions, :class_name => "Revision", :order => "revisions.created_at DESC", :select => 'id, created_at, change_size, user_id', :include => :user

  belongs_to :collection
  belongs_to :scrap_topic, :foreign_key => "collection_id", :counter_cache => :child_count #<<< this should be changed to "scrap_count"
  belongs_to :parent, :class_name => "Scrap", :foreign_key => :parent_id  #<<< this is probably not used now!!
  belongs_to :user, :foreign_key => "user_id"
  belongs_to :language

  attr_accessible :title, :content, :tags, :language_id
  attr_readonly :id, :parent_id, :collection_id, :type, :user_id
  alias :base_klass_save! :save!

  validates_presence_of :title, :message => 'cannot be blank'[:error_field_blank] if self.class.to_s == "Scrap" ## Must be a better way to override this!!?
  validates_presence_of :scrap_topic, :message => 'cannot be blank'[:error_field_blank]
  validates_presence_of :user

  def save!(current_user=nil)
    revision = Revision.new
    self.user_id = current_user.id if self.user_id.nil?
    revision.user_id = self.user_id
    revision.title = self.title
    self.serialize_yaml_fields #Force generation of YAML content
    self.content.gsub!(/\r\n/, "\n") #Save with unix line endings only
    revision.content = self.content
    revision.tag_cache = self.tag_cache

    ##TODO: Add tag handling code for exploding the tag string and supporting multiple types! 
    ##TODO: Add tag handling code for exploding the tag string and supporting multiple types! 

    #Calculate Change Size
    if self.revisions.size == 0
      revision.change_size = 100
    else
      # Calculate the size of the change
      diff = SimpleDiff::DiffBuilder.new(self.revisions.last.content, self.content)
      diff.traverse
      delta = diff.whats_changed?
      revision.change_size = ((delta[1].to_f/delta[3].to_f*100).round + (delta[2].to_f/delta[3].to_f*100).round).to_s
      revision.change_size = 100 if revision.change_size > 100
    end

    # Update nesting details (subject to race conditions, needs a transaction around it, or set using SQL!)
    if !self.parent_id.nil?
      parent = Scrap.find_by_id(self.parent_id)
    end
    if parent.nil?
      self.path      = ''
      self.depth     = 0
      self.parent_id = 0
    else
      #Padding zeros up to 6 digits supports 999,999 records safely
      self.path = parent.path + '/' + "%06d" % parent.id.to_s
      self.depth = parent.depth + 1
      self.parent_id = parent.id
    end
    
    begin
      Scrap.transaction do
        self.version = self.revisions.count.to_i + 1
        base_klass_save!
        revision.scrap_id = self.id
        revision.save!
        if self.class.to_s == "ParallelText"
          if scrap_page = self.scrap_page
            scrap_page.expire_cache #cache_fu integration
          end
        else
          if scrap_page = self.scrap_topic.scrap_page
            self.scrap_topic.scrap_page.expire_cache #cache_fu integration
          end
          self.scrap_topic.update_attribute("updated_at", Time.now)
        end
      end
    end
  end

  def title=(str)
    self[:title] = str.to_s.strip
    self.slug = self[:title]
  end

  def tags=(val)
    self.tag_list = val.gsub(/[,|\;]/, TagList.delimiter).gsub(/[ ]+/, TagList.delimiter)
    self.tag_cache = self.tag_list.to_s #Uses plugin to add tag associations
  end
  
  def tags
    # self.tag_cache -- faster!
    self.tag_list
  end

  def last_modified
    @last_modified ||= self.class.last_modified(self.id)
  end

  def self.last_modified(id = nil)
    options = { :order => "revisions.created_at DESC" }
    options[:conditions] = "scrap_id = #{id}" if id
    rev = Revision.find(:first, options).created_at rescue nil
    options[:include] = :revision
    options[:order] = "comments.created_at DESC"
    com = Comment.find(:first, options).created_at rescue nil
    return com && (!rev || com > rev) ? com : rev
  end
  
  def self.exists?(arg)
    if arg.is_a?(String)
      @existing_scraps ||= Scrap.connection.select_values("SELECT DISTINCT title FROM scraps")
      return @existing_scraps.include?(arg)
    end
    super
  end

  def scrap_topic_id
    self.collection_id
  end

  def scrap_topic_id=(val)
    self.collection_id = val.to_i
  end

  #deprecated??
  def find_scrap_topic(id=nil)
    #This is needed b/c STI enforces the type column value
    id = self.collection_id.to_i if id.nil?
    st = ScrapTopic.find_by_sql("SELECT * FROM collections WHERE id = #{id.to_i}")
    st[0]
  end
  
  def compare(a, b)
    c = [ ]
    c << Revision.find_by_id(a)
    c << Revision.find_by_id(b)
    c = c.compact.sort do |x, y|
      x.rid <=> y.rid
    end

  	data = {
      :a => {
        :attributes => c[0],
        :version => ""
       },
      :b => {
        :attributes => c[1],
        :version => ""
       },
      :tags => ""
  	}
    self.content = diff(data[:b][:attributes].content, data[:a][:attributes].content)
    self.title = diff(data[:b][:attributes].title, data[:a][:attributes].title)
    data[:tags] = diff(data[:b][:attributes].tag_cache, data[:a][:attributes].tag_cache)
    data[:a][:revision] = data[:a][:attributes].rid
    data[:b][:revision] = data[:b][:attributes].rid    
    return data
  end

  def summary_text
    title + " " + content[0..35]
  end

  protected
    def self.find_nested(parent_col='collection_id', parent_id=nil, maxrecs=25, page=1)
      sql = [ "SELECT scraps.*, CONCAT(path, '/', LPAD(scraps.id, 6, '0')) AS lineage FROM scraps WHERE (scraps.#{parent_col} = ?) AND deleted_at IS NULL ORDER BY lineage ASC", parent_id ]
      self.paginate_by_sql(sql, :page => page, :per_page => per_page)
    end

    def initialize(*args)
      super
      self.language_id = 2 # DLH: default to English for now
    end
end