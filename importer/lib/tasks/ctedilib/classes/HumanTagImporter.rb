class HumanTagImporter

  # CLASS CONSTRUCTOR 
  
  def initialize
    @human_matched_entries = []
    @entries_for_human_review = []
  end

  # MAIN METHODS

  def get_human_result_for_entry(fuzzy_entry = false, fuzzy_matches = [])
    # Don't take any bull
    raise "Impromper input to get_human_result_for_entry, must be Entry subclass" unless fuzzy_entry.kind_of?(Entry)
  
    # Check the database to see if we have any objects that match it
    resolutions = $cn.execute("SELECT * FROM tag_matching_resolutions WHERE entry_id = '%s'" % fuzzy_entry.checksum)
    
    return false
  end
  
  def _store_new_fuzzy_entry_as_unmatched(fuzzy_entry)
    key = mysql_serialise_ruby_object(fuzzy_entry)
    insert_sql = "INSERT INTO tag_matching_exceptions (entry_id, human_readable, serialized_entry) VALUES ('%s','%s','%s')" % [fuzzy_entry.checksum, fuzzy_entry.description, key]
    $cn.execute(insert_sql)
  end
  
  def _store_fuzzy_matches_as_unmatched_to_key(key, fuzzy_matches)
    fuzzy_matches.each do |match_entry|
      serialized_entry = mysql_serialise_ruby_object(match_entry)
      insert_sql = "INSERT INTO tag_matching_resolution_choices (key, data, human_readable) VALUES ('%s','%s','%s')" % [key, serialized_entry, match_entry.description]
      $cn.execute(insert_sql)
    end
  end
  
  def add_match_for_entry(fuzzy_entry, matching_entry)
  end
  
  # GETTERS
  
  def entries_for_human_review
    @entries_for_human_review
  end
  
  def human_matched_entries
    @human_matched_entries
  end
end