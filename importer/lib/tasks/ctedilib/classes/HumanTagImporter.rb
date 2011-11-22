class HumanTagImporter

  # MAIN METHODS

  def get_human_result_for_entry(fuzzy_entry = false, fuzzy_matches = [])
    # Don't take any bull
    raise "Impromper input to get_human_result_for_entry, must be Entry subclass" unless fuzzy_entry.kind_of?(Entry)
  
    # Initialize
    connect_db

    # Check the database to see if we have any objects that match it -- quick return if YES
    resolutions = $cn.execute("SELECT serialized_entry, resolution_type FROM tag_matching_resolutions WHERE entry_id = '%s' LIMIT 1" % fuzzy_entry.checksum).each do |rec|
      resolution_type = rec[1]
      if (resolution_type == "human_matched")
        matched_entry = mysql_deserialise_ruby_object(rec[0])
        return matched_entry
      end
    end

    # Well, we didn't return above, so now add it as unmatched
    _store_new_fuzzy_entry_as_unmatched(fuzzy_entry)
    return false
  end

  def add_ignore_for_entry(fuzzy_entry)
    connect_db
    resolution_type = "ignore"
    insert_sql = "INSERT INTO tag_matching_resolutions (entry_id, serialized_entry, resolution_type) VALUES ('%s','%s','%s')" % [fuzzy_entry.checksum, mysql_serialise_ruby_object(matching_entry), resolution_type]
    $cn.execute(insert_sql)
  end

  def add_match_for_entry(fuzzy_entry, matching_entry)
    connect_db
    resolution_type = "human_matched"
    insert_sql = "INSERT INTO tag_matching_resolutions (entry_id, serialized_entry, resolution_type) VALUES ('%s','%s','%s')" % [fuzzy_entry.checksum, mysql_serialise_ruby_object(matching_entry), resolution_type]
    $cn.execute(insert_sql)
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
    insert_sql = "INSERT INTO tag_matching_exceptions (entry_id, human_readable, serialized_entry) VALUES ('%s','%s','%s') ON DUPLICATE KEY UPDATE human_readable = '%s'" % [fuzzy_entry.checksum, fuzzy_entry.description, hash, fuzzy_entry.description]
    $cn.execute(insert_sql)
  end
  
  def _store_fuzzy_matches_as_unmatched_to_id(entry_id, fuzzy_matches)
    fuzzy_matches.each do |match_entry|
      hash = mysql_serialise_ruby_object(match_entry)
      insert_sql = "INSERT INTO tag_matching_resolution_choices (base_entry_id, human_readable, serialized_entry) VALUES ('%s','%s','%s') ON DUPLICATE KEY UPDATE human_readable = '%s'" % [entry_id, match_entry.checksum, match_entry.description, hash, match_entry.description]
      $cn.execute(insert_sql)
    end
  end
  
  # STATIC METHODS FOR DATABASE
  
  def self.truncate_exception_tables
    connect_db
    $cn.execute("TRUNCATE TABLE tag_matching_exceptions")
    $cn.execute("TRUNCATE TABLE tag_matching_resolutions")
    $cn.execute("TRUNCATE TABLE tag_matching_resolution_choices")
  end
  
  def self.create_exception_tables
    connect_db
    sql_statements = IO.read((File.dirname(__FILE__) + '/../sql/create_exception_tables.sql'))
    sql_statements.split("\n\n").each do |statement|
      $cn.execute(statement)
    end
  end
  
  def self.drop_exception_tables
    connect_db
    $cn.execute("DROP TABLE IF EXISTS tag_matching_exceptions")
    $cn.execute("DROP TABLE IF EXISTS tag_matching_resolutions")
    $cn.execute("DROP TABLE IF EXISTS tag_matching_resolution_choices")
  end
  
  # GETTERS
  
  def entries_for_human_review
    @entries_for_human_review
  end
  
  def human_matched_entries
    @human_matched_entries
  end
end