#
# ABOUT: ScrapTopics are the core indexing item in Npedia. Like topics in an encyclopedia
#
# 1 ScrapTopics are a collection of scraps (reading/usage, example, tip, url, scrap, youtube url, etc)
# 2 Each scrap belongs to one collection (as main owner) ... sure, why not??
# 3 Multiple associations are made through 'acts_as_taggable_on :topics'
# 4 Linkable using the 'Links' class
#
class ScrapTopic < Collection

  has_many :scraps, :foreign_key => 'collection_id'
  has_many :scrap_topic_aliases, :foreign_key => 'collection_id'
  has_one :scrap_page, :foreign_key => :cacheable_id, :conditions => ['cacheable_type = ?', ScrapTopic.to_s ]

  def also_known_as
    self.subtitle
  end

  def also_known_as=(val)
    self.subtitle=val
  end

  protected
    # This is dangerous and may not be needed??
    def self.refresh_counters
      ActiveRecord::Base.connection.execute("UPDATE collections set child_count=0 WHERE type=\'ScrapTopic\'")
      ScrapTopic.find(:all).each do |s|
        ScrapTopic.update_counters s.id, :child_count => s.scraps.count
      end
    end
end