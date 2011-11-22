class TagProxy
  acts_as_cached

  def self.get_cached_tags(key_model="")
    get_cache("tag_proxy:#{key_model}_tag_group") do
      if key_model.empty?
        key_model = "scrap"
      else
        key_model = key_model.singularize
      end
      groups_arr = []
      $NpediaKeyModels.each {|s| 
        if s[:model].to_s.downcase == key_model
          groups = s[:public_tag_groups]
          groups_arr = groups.nil? ? [] : groups.split(",") 
          break
        end
      }
      if groups_arr.nil?
        return nil
      else
        return Tag.find(:all, :conditions => {:group => groups_arr}, :order => "name ASC")
      end
    end
  end
  
end