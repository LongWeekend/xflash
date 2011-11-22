class Link < ActiveRecord::Base
  belongs_to :user
  acts_as_taggable_on :link_tags
  attr_accessible :tags
  before_save :order_keys

  def tags=(val)
    self.link_tag_list = val.gsub(/[ |\;]/, ",").gsub(/[,]+/, ",").split(/ /)
  end
  
  def tags
    self.link_tags
  end

  def self.collection_to_collection(sid, tid, user_id, pos=0, priv=0)
    self.relate(sid, tid, user_id, pos, priv, 'Collection', 'Collection')
  end

  def self.collection_to_scrap(sid, tid, user_id, pos=0, priv=0)
    self.relate(sid, tid, user_id, pos, priv, 'Collection', 'Scrap')
  end

  def self.scrap_to_scrap(sid, tid, user_id, pos=0, priv=0)
    self.relate(sid, tid, user_id, pos, priv, 'Scrap', 'Scrap')
  end

  def self.relate(sid, tid, user_id, pos, priv, stype, rtype)
    l = self.find_or_initialize_by_source_id_and_related_id_and_source_type_and_related_type(sid, tid, stype, rtype)
    l.user_id = user_id
    l.position = pos
    l.private = priv
    l.save!
    l
  end

  protected
    def order_keys
      # Links to/from same Npedia base type are stored in order of small to large primary key
      if self.source_type == self.related_type
        if self.source_id > self.related_id
          self.source_id, self.related_id = self.related_id, self.source_id
        end
      end
    end
end

=begin
        # Move this into the Link model!
        # Move this into the Link model!
        related_collections = params[:related_collections].strip.gsub(/[,|\;]/, " ").gsub(/[ ]+/, " ").split(/ /)
        related_scraps = params[:related_scraps].strip.gsub(/[,|\;]/, " ").gsub(/[ ]+/, " ").split(/ /)
        for r in related_collections do
          if c = Collection.find_by_title(r)
            @link = Link.collection_to_scrap(@scrap_topic.id, c.collection_id, c.id)
            if @link.new_record?
              @link.user_id = current_user.id
              @link.private = false
              @link.position = 0
              @link.save!
            end
            @link.tags = params[:tags]
          end
        end
        # Move this into the Link model!
        # Move this into the Link model!
=end
