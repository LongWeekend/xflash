class ScrapBook < Collection

#has_many :scraps, :through => :links, :foreign_key => "source_id", :conditions => "source_type = 'ScrapBook' OR related_type = 'ScrapBook'"

end