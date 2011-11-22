#
# ABOUT: Talk posts belong to scraps (objects containing content)
#
class TalkPost < Post

  has_many :votes, :foreign_key => "source_id", :conditions => { :source_type => "TalkPost" }

  belongs_to :scrap, :foreign_key => "scrap_id"
  belongs_to :user

  validates_presence_of :user, :body, :scrap

	def solution?
		false
	end

  def self.find_nested(scrap_id, num, page)
    #TalkPosts attach to scraps (and their children)
    super('scrap_id', scrap_id, num, page)
  end
end