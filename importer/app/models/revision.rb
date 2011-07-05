class Revision < ActiveRecord::Base
  belongs_to :scrap, :foreign_key => "scrap_id"
  belongs_to :user

  # Get the revision number as displayed on the scrap
  def rid
    return 1 if self.scrap.nil?
    revs = self.scrap.index_revisions
    n = 0
    until n >= revs.length || revs[n] == self
      n += 1
    end
    revs.length - n
  end

  def earliest?
    return true if self.scrap.nil?
    self.id == self.scrap.index_revisions.last.id
  end

  def latest?
    return true if self.scrap.nil?
    self.id == self.scrap.index_revisions.first.id
  end

  def previous
    Revision.find(:first, :conditions => "revisions.id < '#{self.scrap_id}'", :order => "revisions.created_at DESC")
  end
  
  def earliest
    Revision.find(:first, :conditions => "revisions.id > '#{self.scrap_id}'", :order => "revisions.created_at ASC")
  end
  
  def nearest_neighbor
    ( previous || earliest )
  end

  def only?
    latest? && earliest?
  end

end
