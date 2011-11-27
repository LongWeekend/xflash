class Entry < ActiveRecord::Base
  set_table_name "cards_staging"
  primary_key = "card_id"
  
  def human_readable_trimmed
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
