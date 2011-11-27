class Entry < ActiveRecord::Base
  set_table_name "cards_staging"
  set_primary_key :card_id
  has_many :tag_matching_resolution_choice
  
  def human_readable
    return "%s %s [%s], %s" % [headword_trad, headword_simp, reading, meaning_trimmed]
  end
  
  def meaning_trimmed
    if meaning.length > 80
      meaning[0..80]
    else
      meaning
    end
  end
end
