class TagMatchingException < ActiveRecord::Base
  has_many :tag_matching_resolution_choices
  
  def self.all_unmatched
    where("resolved_entry_id IS NULL AND should_ignore = 0")
  end
  
  def self.all_unmatched_and_has_options
    records = []
    self.all_unmatched.each do |exc|
      records << exc if (exc.tag_matching_resolution_choices.count > 0)
    end
    records
  end
  
  def self.all_unmatched_and_no_options
    records = []
    self.all_unmatched.each do |exc|
      records << exc if (exc.tag_matching_resolution_choices.count == 0)
    end
    records
  end
end
