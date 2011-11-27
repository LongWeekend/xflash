class TagMatchingResolutionChoice < ActiveRecord::Base
  belongs_to :tag_matching_exception
  belongs_to :entry
end
