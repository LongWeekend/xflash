class TagMatchingResolutionChoice < ActiveRecord::Base
  belongs_to :tag_matching_exception
  
  # So we don't end up displaying realllly long things in the display boxes
  def human_readable_trimmed
    # 80 characters is the threshold
    if human_readable.length > 80
      human_readable[0..80]
    else
      human_readable
    end
  end
end
