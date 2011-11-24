class TagMatchingException < ActiveRecord::Base
  has_many :tag_matching_resolution_choices
end
