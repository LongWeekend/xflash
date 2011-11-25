class HumanTagImporter

  # MAIN METHODS

  def get_human_result_for_entry(fuzzy_entry = false, fuzzy_matches = [])
    # Don't take any bull
    raise "Impromper input to get_human_result_for_entry, must be Entry subclass" unless fuzzy_entry.kind_of?(Entry)
    raise "Impromper input to get_human_result_for_entry, second param must be array" unless fuzzy_matches.kind_of?(Array)
  
    # Initialize
    connect_db

    # Check the database to see if we have any objects that match it -- quick return if YES
    resolutions = $cn.execute("SELECT resolved_serialized_entry, should_ignore FROM tag_matching_exceptions WHERE entry_id = '%s' LIMIT 1" % fuzzy_entry.checksum).each do |rec|
      # Quick return on should ignore
      if rec[1] == true
        return false
      end
      
      # Otherwise match it
      if rec[0].nil? == false
        matched_entry = mysql_deserialise_ruby_object(rec[0])
        return matched_entry
      end
    end

    # Well, we didn't return above, so now add it as unmatched
    entry_id = _store_new_fuzzy_entry_as_unmatched(fuzzy_entry)
    _store_fuzzy_matches_as_unmatched_to_id(entry_id, fuzzy_matches) if (fuzzy_matches.empty? == false)
    return false
  end

  def add_match_for_entry(fuzzy_entry, matching_entry)
    connect_db
    update_sql = "UPDATE tag_matching_exceptions SET resolved_serialized_entry = '%s' WHERE entry_id = '%s'" % [mysql_serialise_ruby_object(matching_entry), fuzzy_entry.checksum]
    $cn.execute(update_sql)
  end
  
  def retrieve_exception_entry_from_db(entry)
    connect_db
    $cn.execute("SELECT serialized_entry FROM tag_matching_exceptions WHERE entry_id = '%s'" % [entry.checksum]).each do |rec|
      return mysql_deserialise_ruby_object(rec[0])
    end
    return false
  end
  
  # PRIVATE METHODS
  
  def _store_new_fuzzy_entry_as_unmatched(fuzzy_entry)
    hash = mysql_serialise_ruby_object(fuzzy_entry)
    desc = mysql_escape_str(fuzzy_entry.description)
    insert_sql = "INSERT INTO tag_matching_exceptions (entry_id, human_readable, serialized_entry, created_at, updated_at) VALUES ('%s','%s','%s',NOW(),NOW()) ON DUPLICATE KEY UPDATE human_readable = '%s', updated_at = NOW()" % [fuzzy_entry.checksum, desc, hash, desc]
    $cn.execute(insert_sql)
    return $cn.last_inserted_id
  end
  
  def _store_fuzzy_matches_as_unmatched_to_id(entry_id, fuzzy_matches)
    fuzzy_matches.each do |match_entry|
      hash = mysql_serialise_ruby_object(match_entry)
      desc = mysql_escape_str(match_entry.description)
      insert_sql = "INSERT INTO tag_matching_resolution_choices (tag_matching_exception_id, human_readable, serialized_entry, created_at, updated_at) VALUES ('%s','%s','%s',NOW(),NOW()) ON DUPLICATE KEY UPDATE human_readable = '%s', updated_at = NOW()" % [entry_id, desc, hash, desc]
      $cn.execute(insert_sql)
    end
  end
  
  # STATIC METHODS FOR DATABASE
  
  def self.truncate_exception_tables
    connect_db
    $cn.execute("TRUNCATE TABLE tag_matching_exceptions")
    $cn.execute("TRUNCATE TABLE tag_matching_resolution_choices")
  end
  
  # GETTERS
  
  def entries_for_human_review
    @entries_for_human_review
  end
  
  def human_matched_entries
    @human_matched_entries
  end
end