class Vote < ActiveRecord::Base
  belongs_to :scrap, :foreign_key => "source_id", :conditions => { :source_type => "Scrap" }
  belongs_to :post, :foreign_key => "source_id", :conditions => { :source_type => "Post" }
  belongs_to :user, :foreign_key => "user_id"

  def self.up(obj, user, wt=1)
    self.vote_unique(obj, user.id, :up, wt)
  end

  def self.down(obj, user, wt=1)
    self.vote_unique(obj, user.id, :down, wt)
  end

  def self.rating(obj, user, rating, wt=0)
    self.vote_unique(obj, user.id, :rating, wt) if wt !=0
  end

  def self.abuse(obj, user, wt=1)
    #No self voting
    return if obj.user_id == user.id
    vote_type = "abuse"
    previous = self.find_all_by_source_id_and_source_type_and_vote_type_and_user_id(obj.id, obj.class.to_s, vote_type, user.id)
    if previous.size > 0
      previous.each do |v| v.destroy end  # Kill all previous abuse votes on object
      return false   # Return "false" to confirm abuse report retracted
    else
      o = self.new()
      o.vote_type = vote_type
      o.source_type = obj.class.to_s
      o.source_id = obj.id
      o.user_id = user.id
      o.weight = wt
      o.save!
      return true   # Return "true" to confirm abuse reported
    end
  end

  protected
    def self.vote_unique(obj, user_id, vote_type, wt)
      #No self voting
      return if obj.user_id == user_id
      vote_type=vote_type.to_s
      if vote_type == "up" or vote_type == "down"
        previous = self.find_all_by_source_id_and_source_type_and_user_id(obj.id, obj.class.to_s,user_id, :conditions => "vote_type ='up' or vote_type = 'down'" )
      else
        previous = self.find_all_by_source_id_and_source_type_and_vote_type_and_user_id(obj.id, obj.class.to_s, vote_type, user_id)
      end
      self.transaction do
        previous.each do |v| v.destroy end  # Kill all previous duplicated votes
        o = self.new()
        o.vote_type = vote_type
        o.source_type = obj.class.to_s
        o.source_id = obj.id
        o.user_id = user_id
        o.weight = wt
        o.save!
      end
    end
end