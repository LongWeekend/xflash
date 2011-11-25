class TagMatchingResolution < ActiveRecord::Base
  belongs_to :tag_matching_exception
  belongs_to :tag_matching_resolution_choice
end
