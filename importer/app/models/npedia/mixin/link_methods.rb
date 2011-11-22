# This is dependant upon Scrap & Collection classes - This module keeps them DRY
module LinkMethods
  def links
    Link.find(:all, :conditions => {:source_id => self.id, :source_type => self.class.to_s})
  end

  def linked_to
    Link.find(:all, :conditions => {:related_id => self.id, :related_type => self.class.to_s})
  end

  def related_collections
    ar_base_klass = Collection.ar_base_klass(self)
    incoming = Collection.find(:all, :select => "Collections.*", :conditions => ["links.related_id = ? AND links.related_type = ? AND links.source_type = 'Collection'", self.id, ar_base_klass], :joins => "INNER JOIN links ON collections.id = links.source_id")
    outgoing = Collection.find(:all, :select => "Collections.*", :conditions => ["links.source_id = ? AND links.source_type = ? AND links.related_type = 'Collection'", self.id, ar_base_klass], :joins => "INNER JOIN links ON collections.id = links.related_id")
    incoming + outgoing
  end

  def related_scraps
    ar_base_klass = Scrap.ar_base_klass(self)
    incoming = Scrap.find(:all, :select => "scraps.*", :conditions => ["links.related_id = ? AND links.related_type = ? AND links.source_type = 'Scrap'", self.id, ar_base_klass], :joins => "INNER JOIN links ON scraps.id = links.source_id")
    outgoing = Scrap.find(:all, :select => "scraps.*", :conditions => ["links.source_id = ? AND links.source_type = ? AND links.related_type = 'Scrap'", self.id, ar_base_klass], :joins => "INNER JOIN links ON scraps.id = links.related_id")
    incoming + outgoing
  end

  def related
    return related_collections + related_scraps
  end
end