#constants
MATCHED_HEADWORD                = "HM"
MATCHED_CROSS_HEADWORD          = "CM" # Matched old 'headword' to new 'alt_headword'
MATCHED_READING                 = "RM"
MATCHED_MEANING                 = "MM"
MATCHED_READING_PARTIAL_FIRST   = "RP"
MATCHED_READING_PARTIAL_OTHER   = "RO"
MATCHED_MEANING_PARTIAL         = "MP"
MATCHED_MEANING_MUNGED_FIRST    = "MF"
MATCHED_MEANING_MUNGED          = "MG"
MATCHED_MEANING_CONTAINED       = "MC"
MATCHED_MEANING_LEVEN           = "ML"
ORPHANED_HEADWORD               = "HO"
MATCHED_HM_RM_SINGLE_RECORD     = "SR"
MATCHED_MEANING_SINGLE_GLOSS    = "SG"
MATCHED_BY_HUMAN                = "HU"

class JFlashMigration

  include ImporterHelpers
  include DatabaseHelpers

  def initialize(old_source_table_name="cards_staging_rel1", new_source_table_name="cards_staging_humanised")
    @old_source_table = old_source_table_name
    @new_source_table = new_source_table_name
    @new_card_working_table = "MERGE_" + new_source_table_name
    @old_card_working_table = "MERGE_" + old_source_table_name
    @human_checked_table    = "MERGE_human_checked"
    @buffered_cards = {}
    @should_check_human_cards = false
    @is_dry_run = false
    @debug_print_key = nil      # If set, should print the contents of this key to the console when looped
    @n = 0                  # Num of records to get from the DB
    @offset = 0              # offset to start from when getting records
    @merge_key_order_hash = { # Represents number of passes, and which keys are passed for each pass
        1 => ["HM_RM_MM"],
        2 => ["HM_RM_MP", "HM_RP_MM"],
        3 => ["HM_RO_MM","HM_RO_MP"],
        4 => ["HM_RM_MF","HM_RP_MF"], 
        5 => ["HM_RM_MG","HM_RP_MG"], 
        6 => ["HM_RP_MP"],
        7 => ["HM_MM", "HM_RM_MC", "HM_RM_ML"], 
        8 => ["CM_RM_MM","CM_RP_MM","CM_MM","HM_RP_MC"], 
        9 => ["CM_RM_MC", "CM_RM_ML", "CM_RP_MC", "HM_RO_MC", "HM_RP_ML"],
        10 => ["CM_RO_MM","HM_RM_SG", "HM_RP_SG","HM_RO_ML"],
        11 => ["HM_RM_SR", "HM_RO_SG"],
        12 => ["HM_RO_MG"],
        13 => ["CM_ML","CM_RP","CM_RM","CM_MC", "CM_RP"],
        14 => ["HM_MF"],
        15 => ["HM_SG"],
        16 => ["HM_ML"],
        17 => ["HM_MG","HM_RM_SR"],
        18 => ["RM_MP"],
        19 => ["HO"],
        20 => ["HU"],
    }
    #"HM_RM", >>>  gives many false positives!
  end
  
  # Set this to avoid committing matches to SQL tables
  def set_dry_run
    @is_dry_run = true
  end

  # Set should check human cards?
  def set_should_check_human_cards
    @should_check_human_cards = true
  end
  
  # Sets the range that we will operate in
   def set_run_range (n, offset)
     @n = n
     @offset = offset
   end
   
  def set_debug_print_key (key)
    @debug_print_key = key
  end

  def run
    connect_db
    
    # Matching loop
    limit = ""
    passes = @merge_key_order_hash.size # How many times shoulds we loop

    # Create working copies of both tables
    prt "Resetting working tables if necessary..."
    self.class.reset_working_tables(@old_card_working_table, @new_card_working_table, @old_source_table, @new_source_table) if !mysql_table_exists("card_migration_results")
    

    for pass_no in 1..passes do
      count = 0
      matched = {}
      unmatched = []
      results = []
      
      dupe_double_check = {}

      # Determine if we are at a human step, if so, run the debugger to pause execution
      keys_for_this_pass = @merge_key_order_hash[pass_no]
      if keys_for_this_pass.index(MATCHED_BY_HUMAN)
        self.class.create_checked_by_humans_table
        set_should_check_human_cards
        debugger  #THIS CALL NEEEEEDS to be here, it is NOT debug code - humans need to do something after the last command
      end

      prt "Starting merging pass #{pass_no}..."

      # Buffer OLD cards into indexes by headword / alt_headword / card_id
      prt "Buffering cards to match against..."
      set_buffered_cards(self.class.create_buffer_comparision_data({ :table => @new_card_working_table }))

      # Do we have a custom offset?
      limit = "LIMIT #{@offset},#{@n}" if @n.to_i > 0

      sql_data =$cn.execute("SELECT card_id, headword, alt_headword, reading, meaning, tags FROM #{@old_card_working_table} ORDER BY headword #{limit}")
      sql_data.each do | card_id, headword, alt_headword, reading, meaning, tags |
        count = count+1
        get_matching_cards(card_id, headword, alt_headword, reading, meaning, tags).each do |buffered_card|
          
          if buffered_card.size < 1
            unmatched << card_id
          else
            match_txt = buffered_card[:results].compact.join("_")
            matched[match_txt] = [] if !matched.has_key?(match_txt)
            matched[match_txt] << { :new_id => buffered_card[:card_id], :old_id => card_id }
          end
        end
      end

      # Time to update the working tables
      $options[:verbose] = true # force debug output on!
      bulkSQL = BulkSQLRunner.new(0,10000)
      matched_new_card_ids = []
      matched_old_card_ids = []

      keys_for_this_pass = @merge_key_order_hash[pass_no]

      prt "\n\nHere are the results..."
      prt_dotted_line
      prt "New : #{count}".ljust(10)
      matched.keys.sort.each do |key|
        # Accepts partial or complete meaning matches
        matched[key].each do |rec|
          # Print debug information if set
          if key == @debug_print_key
            debug_old_id = rec[:old_id]
            debug_new_id = rec[:new_id]
            old_card =$cn.execute("SELECT card_id, headword, alt_headword, reading, meaning, tags FROM #{@old_card_working_table} WHERE card_id = #{debug_old_id}")
            old_card.each do | card_id, headword, alt_headword, reading, meaning, tags |
              new_cards = get_buffered_cards
              prt "------------------------------------------"
              prt "OH: "+headword
              prt "NH: "+new_cards[:by_card_id][debug_new_id][:headword]
              prt "OR: "+reading
              prt "NR: "+new_cards[:by_card_id][debug_new_id][:reading]
              prt "OM: "+meaning
              prt "NM: "+new_cards[:by_card_id][debug_new_id][:meaning]
            end
          end
          
          if keys_for_this_pass.index(key)
            old_id = rec[:old_id]
            # Special handling if it is an orphaned -- so check
            new_id = (key == ORPHANED_HEADWORD ? 0 : rec[:new_id])
            # Final check to make sure we are not creating a dupe
              # Record match in results table
              bulkSQL.add("INSERT INTO card_migration_results (new_card_id, old_card_id, result) values (#{new_id}, #{old_id}, '#{key}');")
              # Buffer IDs to remove from working tables
              matched_new_card_ids << new_id
              matched_old_card_ids << old_id
          end
        end
        prt "#{key} : #{matched[key].size}".ljust(10)
      end
    
      # Only commit SQL if this is NOT a dry run
      if (!@is_dry_run)
        bulkSQL.flush
      else
        prt "Dry run, not committing bulk SQL"
      end

      prt "Matched_new_card_ids #{matched_new_card_ids.size}"
      prt "Matched_old_card_ids #{matched_old_card_ids.size}"

      if (!@is_dry_run)
        prt "Deleting matched records from working tables"
        prt_dotted_line
        $cn.execute("DELETE FROM #{@new_card_working_table} WHERE card_id IN (#{matched_new_card_ids.join(",")})") if matched_new_card_ids.size > 0
        $cn.execute("DELETE FROM #{@old_card_working_table} WHERE card_id IN (#{matched_old_card_ids.join(",")})") if matched_old_card_ids.size > 0
      else
        prt "Dry run, not deleting cards from merge table"
      end

    end
    
  end


  #---------------------------------------------------------------------------
  # BUFFERING FUNCTIONS
  #---------------------------------------------------------------------------

  # Setter for class property buffered_cards
  def set_buffered_cards(buffered_cards)
    @buffered_cards = buffered_cards
  end

  # Getter for class property buffered_cards
  def get_buffered_cards
    return @buffered_cards
  end

  # Create buffered cards hashes
  def self.create_buffer_comparision_data(options={:table=>"", :where=>"", :limit =>""})
    connect_db

    buffered_cards = {}
    buffered_cards[:by_headword] = {}
    buffered_cards[:by_alt_headword] = {}
    buffered_cards[:by_reading] = {}
    buffered_cards[:by_card_id] = {}

    where = (options.has_key?(:where) && options[:where] != "" ? "WHERE #{options[:where]}" : "")
    limit = (options.has_key?(:limit) && options[:limit] != "" ? "LIMIT #{options[:limit]}" : "")
    $cn.execute("SELECT card_id, headword, alt_headword, reading, meaning FROM #{options[:table]} #{where} ORDER BY card_id #{limit}").each do | card_id, headword, alt_headword, reading, meaning |
      buffered_cards[:by_headword][headword] = [] if !buffered_cards[:by_headword].has_key?(headword)
      buffered_cards[:by_headword][headword] << card_id 

      buffered_cards[:by_reading][reading] = [] if !buffered_cards[:by_reading].has_key?(reading)
      buffered_cards[:by_reading][reading] << card_id 

      alt_headword.split($delimiters[:jflash_alt_headwords]).each do |hw|
        buffered_cards[:by_alt_headword][hw] = [] if !buffered_cards[:by_alt_headword].has_key?(hw)
        buffered_cards[:by_alt_headword][hw] << card_id
      end

      buffered_cards[:by_card_id][card_id] = {:headword => headword, :alt_headword => alt_headword, :reading => reading, :meaning => meaning}
    end
    return buffered_cards
  end
  
  
  #---------------------------------------------------------------------------
  # MATCHING FUNCTIONS
  #---------------------------------------------------------------------------

  # Returns cards matched by us
  def get_human_matched_cards(card_id)
    connect_db
    matches_array = []
    sql_query = "SELECT new_card_id FROM #{@human_checked_table} WHERE old_card_id = #{card_id} LIMIT 1"
    sql_data = $cn.execute(sql_query)
    sql_data.each do |new_card_id|
      # As long as we found a record we don't care
        match = {}
        match[:card_id] = new_card_id[0]
        match[:results] = [MATCHED_BY_HUMAN]
        matches_array << match
    end
    return matches_array
  end
  
  # DESC: Match existing cards to the current 'old' card
  def get_matching_cards(card_id, headword, alt_headword, reading, meaning, tags)
    
    matches_array = []
    
    ## 0:
    if @should_check_human_cards
      matches_array = get_human_matched_cards(card_id)
      return matches_array if matches_array.size > 0
    end

    ## 1: Match by headword
    headword_match_type, matched_data = match_headwords(get_buffered_cards, headword)
    if (headword_match_type == MATCHED_HEADWORD) or (headword_match_type == MATCHED_CROSS_HEADWORD) 

      buffered_card_id_array = get_buffered_cards[:by_headword][headword] if headword_match_type == MATCHED_HEADWORD
      buffered_card_id_array = get_buffered_cards[:by_alt_headword][headword] if headword_match_type == MATCHED_CROSS_HEADWORD

      # Loop through each matching card's ID
      buffered_card_id_array.each do |buffered_card_id|
      	prt "old: " + card_id + " new:" + buffered_card_id
        match = {}
        match[:card_id] = buffered_card_id
        match[:results] = [headword_match_type]

        # 2: Match by readings
        reading_match_type, matched_data = match_readings(get_buffered_cards[:by_card_id][buffered_card_id][:reading].strip, reading.strip)
        match[:results] << reading_match_type

        # 3: Match by meanings
        meaning_is_matched = false
        old_meaning = meaning.strip
        new_meaning = get_buffered_cards[:by_card_id][buffered_card_id][:meaning].strip
        if old_meaning == new_meaning
          meaning_is_matched = true
          match[:results] << MATCHED_MEANING
        else
          m_partial_match_type, matched_data = match_meaning_partial(old_meaning, new_meaning)
          meaning_is_matched = true if (m_partial_match_type != nil) 
          match[:results] << m_partial_match_type
        end
        
        # Special check for HM_RM -- is there only one card?  If so, match it
        if (headword_match_type == MATCHED_HEADWORD and reading_match_type == MATCHED_READING and !meaning_is_matched and  buffered_card_id_array.size == 1)
          match[:results] << MATCHED_HM_RM_SINGLE_RECORD
        end
              
        # Store the results
        matches_array << match
      end

    # No headword match, see if orphaned card?
    else
      match = {}
      funky_match = false
      # Is this a kana-only headword??
      if headword.scan($regexes[:kana_or_basic_punctuation])
        matched_new_card = JFlashImporter.get_kana_only_duplicate_by_reading_optimised(headword,$options[:card_types]['DICTIONARY'])
        ##prt "Am I here every time?"
        if matched_new_card
          match[:card_id] = 0
          match[:results] = [ORPHANED_HEADWORD]
          matches_array << match
          funky_match = true
        end
      end

      # is it an orphaned JLPT word??
      if tags.scan("jlpt").size > 0 and card_id.to_i > 145000 and !funky_match
        ##pp "In non-match block - here"
        match[:card_id] = 0
        match[:results] = [ORPHANED_HEADWORD]
        matches_array << match
        funky_match = true
      else
        # LAST DITCHED
        buffered_card_id_array = get_buffered_cards[:by_reading][reading]
        if (buffered_card_id_array)
          buffered_card_id_array.each do |buffered_card_id|
            old_meaning = meaning.strip
            new_meaning = get_buffered_cards[:by_card_id][buffered_card_id][:meaning].strip
            reading_match_type, matched_data = match_readings(get_buffered_cards[:by_card_id][buffered_card_id][:reading].strip, reading.strip)
            m_partial_match_type, matched_data = match_meaning_partial(old_meaning, new_meaning)
            if (m_partial_match_type and reading_match_type)
              match[:card_id] = buffered_card_id
              match[:results] = [reading_match_type, m_partial_match_type]
              matches_array << match
              funky_match = true
            end
          end
        end
      end

    end  # headword matched
    
=begin
    matches_array.each do |marray|
      m_key = marray[:results].flatten.join("_")
      buffered_cards = get_buffered_cards
      card = buffered_cards[:by_card_id][marray[:card_id]]
      prt "HEADW MATCH" if marray[:results].index("HM")
      prt "CROSS MATCH" if marray[:results].index("CM")
      prt "(old)#{headword}\n(new)#{card[:headword]}"
      prt "PARTIAL RDG" if marray[:results].index("RP")
      prt "MATCHED RDG" if marray[:results].index("RM")
      prt "(old)#{reading}\n(new)#{card[:reading]}"
      prt "PARTIAL MNG" if marray[:results].index("MP")
      prt "MUNGED MNG!" if marray[:results].index("MG")
      str1 = card[:meaning].gsub($regexes[:non_alphanumeric],"")
      str2 = meaning.gsub($regexes[:non_alphanumeric],"")
      ave_len = ((str1.strip).size.to_f + (str2.strip).size.to_f) / 2
      prt "(old)#{meaning}\n(new)#{card[:meaning]}" 
      ldistance = (Levenshtein.distance(str1.strip.downcase, str2.strip.downcase).to_f / ave_len) *100
      puts "ldistance = #{ldistance}"
      prt ""
    end
=end
    pp matches_array if matches_array.size > 1
    
    return matches_array
  end
  
  # matches readings
  def match_readings(old_reading,new_reading)
    if (old_reading == new_reading)
      matched_type = MATCHED_READING
      matched_data = old_reading
    else 
      old_readings = old_reading.split($delimiters[:jflash_readings])
      new_readings = new_reading.split($delimiters[:jflash_readings])
      intersection = (new_readings & old_readings)
      if old_readings[0].strip == new_readings[0].strip
        matched_type = MATCHED_READING_PARTIAL_FIRST
        matched_data = old_readings[0]
      elsif intersection.size > 0
        matched_type = MATCHED_READING_PARTIAL_OTHER
        matched_data = intersection
      else
        matched_type = nil
        matched_data = nil
      end
    end
    return matched_type, matched_data
  end


  # matches headwords
  def match_headwords(old_data_hash, headword)
    if old_data_hash[:by_headword].has_key?(headword)
      matched_type = MATCHED_HEADWORD
      matched_data = headword
    elsif old_data_hash[:by_alt_headword].has_key?(headword)
      matched_type = MATCHED_CROSS_HEADWORD
      matched_data = headword
    else
      matched_type = nil
      matched_data = nil
    end
    return matched_type, matched_data
  end


  # matches partial meanings
  def match_meaning_partial(old_meaning, new_meaning)
    matched_type = nil
    matched_data = nil
    
    # jFlash 1.0 did not have parens on language origin tags, so we have to take out to match
    new_meaning.scan($regexes[:origin_language_tag]).each do |arr|
      str = arr[0]
      new_meaning = new_meaning.gsub("("+str+")",str)
    end
    old_meaning.scan($regexes[:origin_language_tag]).each do |arr|
      str = arr[0]
      old_meaning = old_meaning.gsub("("+str+")",str)
    end

    # strip out the data
    regex_cleaners = []
    regex_cleaners << $regexes[:parenthetical]
    regex_cleaners << $regexes[:leading_trailing_slashes_greedy]
    regex_cleaners << $regexes[:any_whitespace]
    regex_cleaners << ";"
    regex_cleaners << "/"
    regex_cleaners.each do |regex|
      old_meaning = old_meaning.gsub(regex, "")
      new_meaning = new_meaning.gsub(regex, "")
    end

    if new_meaning == old_meaning
      matched_type = MATCHED_MEANING_PARTIAL
      matched_data = new_meaning
    elsif old_meaning.scan(new_meaning).size > 0
      old_meaning_start = old_meaning[0..(new_meaning.length-1)]
      if (old_meaning_start == new_meaning)
        matched_type = MATCHED_MEANING_MUNGED_FIRST
        matched_data = new_meaning
      else
        matched_type = MATCHED_MEANING_MUNGED
        matched_data = new_meaning
      end
    elsif new_meaning.scan(old_meaning).size > 0
      matched_type = MATCHED_MEANING_CONTAINED
      matched_data = new_meaning
    else
      ldistance = get_levenshtein_of(old_meaning,new_meaning)
      if ldistance < 60
        matched_type = MATCHED_MEANING_LEVEN
        matched_data = ldistance
      else
        old_str_max = (old_meaning.size > 19 ? old_meaning[0..19] : old_meaning)
        new_str_max = (new_meaning.size > 19 ? new_meaning[0..19] : new_meaning)
        ldistance = get_levenshtein_of(old_str_max, new_str_max)
        if ldistance < 60
          matched_type = MATCHED_MEANING_SINGLE_GLOSS
          matched_data = ldistance
        end
      end # else check individual glosses
    end
    return matched_type, matched_data
  end

  def get_levenshtein_of(str1, str2)
    str1.gsub!($regexes[:non_alphanumeric],"")
    str2.gsub!($regexes[:non_alphanumeric],"")
    ave_len = ((str1.strip).size.to_f + (str2.strip).size.to_f) / 2
    return (Levenshtein.distance(str1.strip.downcase, str2.strip.downcase).to_f / ave_len) *100
  end

  # Splits a string by a semicolon and trims the output and sticks it into an array
  def split_munged_meaning(input_str)
    return input_str.split(";")
  end

  # Creates a small array of cards out of the buffered cards
  def prepare_card_array_from_card_ids (card_ids_array)
    # Get me something I can work with people!
    # Locally cache the matching headword buffered cards directly
    new_cards_array = []
    card_ids_array.each do |new_card_id|
      new_cards_array << get_buffered_cards[:by_card_id][new_card_id]
    end
    return new_cards_array
  end

  # Should we assign this 1 meaning to one of n card ids based on a meaning match?
  def match_munged_meaning (single_meaning_str, single_reading_str, new_cards_array)

    # initialize return value
    matched_new_card_id = 0

     # Make sure no one is passing us bad data
     return matched_new_card_id if new_cards_array.size == 0

    # If there is more than one reading, pick the one that matches and see if we have a partial match
    already_have_matched_reading = false
    only_one_reading_match = false
    new_cards_array.each do |card_hash|
      pp "Reading string is : ${card_hash[:reading]}"
      if (single_reading_str == card_hash[:reading]) and (already_have_matched_reading == false)
        already_have_matched_reading = true
        only_one_reading_match = true
        matched_new_card_id = card_hash[:card_id]
        pp "Matched ${matched_new_card_id}"
      elsif already_have_matched_reading == true
        # Whoops, more than one, so this isn't going to work - reset
        matched_new_card_id = 0
        only_one_reading_match = false
        pp "Multiple headwords with same reading -- must be different sense"
      end
    end

#      if intersection.size > 0

    # If only one of the readings matched up, we're calling that one done
    if only_one_reading_match
      return matched_new_card_id
    end
    
    # OK, now the HARD part - we have MULTIPLE headwords with the SAME reading.
  end


  # DESC: Remove the migration results table!
  def self.remove_migration_results_table
    connect_db
    $cn.execute("DROP TABLE IF EXISTS card_migration_results")
  end

  # DESC: re-create the human checking table here
  def self.create_checked_by_humans_table
    connect_db
    $cn.execute("DROP TABLE IF EXISTS MERGE_human_checked")
    $cn.execute("CREATE TABLE MERGE_human_checked SELECT j1.card_id AS old_card_id, j2.card_id AS new_card_id, j1.headword AS old_headword, j1.reading AS old_reading, j2.reading AS new_reading, j1.tags, j1.meaning AS old_meaning, j2.meaning AS new_meaning FROM MERGE_cards_staging_rel1 j1, MERGE_cards_staging_humanised j2 WHERE j1.headword = j2.headword")
  end
  
  # DESC: Removes old working tables and starts again!
  def self.reset_working_tables(old_wrk_table_name, new_wrk_table_name, old_src_table_name, new_src_table_name)
    connect_db

    exit_with_error("'#{old_src_table_name}' table not found!") if !mysql_table_exists(old_src_table_name)
    exit_with_error("'#{new_src_table_name}' table not found!") if !mysql_table_exists(new_src_table_name)

    $cn.execute("DROP TABLE IF EXISTS #{new_wrk_table_name}")
    $cn.execute("DROP TABLE IF EXISTS #{old_wrk_table_name}")
    $cn.execute("DROP TABLE IF EXISTS card_migration_results")

    if !mysql_table_exists(new_wrk_table_name)
      $cn.execute("CREATE TABLE #{new_wrk_table_name} SELECT * FROM #{new_src_table_name}")
      $cn.execute("ALTER TABLE #{new_wrk_table_name} ADD PRIMARY KEY (card_id)")
      $cn.execute("UPDATE #{new_wrk_table_name} SET reading = REPLACE(reading, ',', ';');")
    end
    if !mysql_table_exists(old_wrk_table_name)
      $cn.execute("CREATE TABLE #{old_wrk_table_name} SELECT * FROM #{old_src_table_name}")
      $cn.execute("ALTER TABLE #{old_wrk_table_name} ADD PRIMARY KEY (card_id)")
      $cn.execute("UPDATE #{old_wrk_table_name} SET meaning = REPLACE(meaning, ' ()', '');")
      $cn.execute("UPDATE #{old_wrk_table_name} SET reading = REPLACE(reading, ',', ';');")
    end
    if !mysql_table_exists("card_migration_results")
      $cn.execute("CREATE TABLE card_migration_results (new_card_id int(11) NOT NULL DEFAULT 0, old_card_id int(11) NOT NULL DEFAULT 0, result varchar(10) DEFAULT NULL)")
      $cn.execute("ALTER TABLE card_migration_results ADD INDEX (new_card_id)")
      $cn.execute("ALTER TABLE card_migration_results ADD INDEX (old_card_id)")
    end
  end

end