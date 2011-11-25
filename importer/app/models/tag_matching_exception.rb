class TagMatchingException < ActiveRecord::Base
  has_many :tag_matching_resolution_choices
  
  def self.all_unmatched
    where("resolved_serialized_entry IS NULL")
  end
  
  def self.all_unmatched_and_has_options
    records = []
    self.all_unmatched.each do |exc|
      records << exc if (exc.tag_matching_resolution_choices.count > 0)
    end
    records
  end
end