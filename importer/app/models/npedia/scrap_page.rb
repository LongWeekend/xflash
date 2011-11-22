class ScrapPage < ActiveRecord::Base
  acts_as_cached

  has_many :tags_by_scrap_page, :foreign_key => :id
  belongs_to :scrap_topic, :foreign_key => :cacheable_id, :conditions => ['type = ?', ScrapTopic.to_s ]
  belongs_to :parallel_text, :foreign_key => :cacheable_id, :conditions => ['type = ?', ParallelText.to_s ]

  #thinking sphinx
  define_index do
    indexes :title, :sortable => true
    indexes :content
    has :cacheable_type, :cacheable_id, :created_at
    has tags_by_scrap_page(:tag_id), :as => :tag_ids, :source => :query
    set_property :delta => true
  end

  def slug
    self.slug_cache
  end
end