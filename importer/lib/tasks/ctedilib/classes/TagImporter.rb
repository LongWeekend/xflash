class TagImporter
  
  include DatabaseHelpers

  def self.tear_down_all_tags
    connect_db
    $cn.execute("TRUNCATE TABLE card_tag_link")
    $cn.execute("TRUNCATE TABLE tags_staging")
  end
  
  #### DESC: Class Constructors
  def initialize (data, configuration, prev_entry_cache = false)
    @config = {}
    @tag_id = nil
    @human_importer = HumanTagImporter.new
    
    # If we are passed an EntryCache, use it, otherwise create a new cache.
    if prev_entry_cache
      @entry_cache = prev_entry_cache
    else
      @entry_cache = EntryCache.new
    end
    
    # Metadata for the tag itself
    @config[:tag_configuration] = configuration
    
    # Data parsing parameter
    @config[:data] = data
    @config[:sql_buffer_size] = 1000
    @config[:sql_debug] = false
    
    @log_stream = nil
    if (@config[:tag_configuration].file_dump_trace())
      #Get the stream
      filename = get_log_dump_filename()
      @log_stream = File.new(filename, "a+")
      
      #Start the stream with the date and time.
      now = Date.today.to_datetime
      @log_stream << "#{now}\n"
    end
    
    return self
  end
  
  def get_log_dump_filename
    folder_path = File.dirname(__FILE__) + "/../../../../log"
    tag_name = @config[:tag_configuration].short_name()
    return "#{folder_path}/#{tag_name}-import.log"
  end

  def log(string, print_both=false)
    logged_to_file = false
    if (@log_stream != nil)
      logged_to_file = true
      @log_stream << "#{string}\n"
    end
    
    if ((!logged_to_file)||(print_both))
      puts "\n#{string}"
    end
  end

  def tag_id
    @tag_id
  end
  
  def insert_tag_into_table
    connect_db
    config = @config[:tag_configuration]
    
    # If the shortname is longer than 20 characters, throw an exception as the table structure
    # for tags_staging, the shortname is only for 20 characters long.
    if config.short_name.length > 20
      raise "The shortname for tag name #{config.tag_name} cannot be longer than 20 characters."
    end
    
    # try inserting into the tags_staging table as row 
    inserted_short_name = config.short_name
    if config.tag_id != nil
      # For specific cases where the YAML file tells us what SQL ID to use -- presently used for Starred
      insert_query = "INSERT INTO tags_staging(tag_id, tag_name, tag_type, short_name, description, source_name, source, visible, parent_tag_id, force_off, editable) VALUES(%s, '%s', '%s', '%s', '%s', '%s', '%s', %s, %s, %s, %s)" %
                        [config.tag_id, mysql_escape_str(config.tag_name), config.tag_type, config.short_name, mysql_escape_str(config.description), config.source_name, config.source, config.visible, config.parent_tag_id, config.force_off, config.editable]
    else
      # Most other cases -- just add a new tag
      insert_query = "INSERT INTO tags_staging(tag_name, tag_type, short_name, description, source_name, source, visible, parent_tag_id, force_off, editable) VALUES('%s', '%s', '%s', '%s', '%s', '%s', %s, %s, %s, %s)" %
                        [mysql_escape_str(config.tag_name), config.tag_type, config.short_name, mysql_escape_str(config.description), config.source_name, config.source, config.visible, config.parent_tag_id, config.force_off, config.editable]
    end
            
    $cn.execute(insert_query)
    return last_inserted_id
  end
    
  def insert_card_tag_links_for_ids(tag_id, card_ids = [])
    # Now actually write out all the cards to the DB
    bulkSQL = BulkSQLRunner.new(card_ids.size, @config[:sql_buffer_size], @config[:sql_debug])
    insert_tag_link_query = "INSERT card_tag_link(tag_id, card_id) VALUES (#{tag_id},%s);"
    card_ids.each do |card_id|
      bulkSQL.add((insert_tag_link_query % [card_id]))
    end
    bulkSQL.flush
    update_tag_count
  end
    
  def import
    # Insert into the tags_staging first to get the parent of the tags.
    connect_db
    @tag_id = insert_tag_into_table
    log("Inserted into the tags_staging table for short_name: %s with tag_id: %s" % [@config[:tag_configuration].short_name, @tag_id], true)
    
    # After creating the table, skip the import process if we have no card data
    if (@config[:data].nil? or @config[:data].empty?)
      prt "Skipping matching process for empty tag (no data passed in)"
      return @tag_id
    end
    
    @entry_cache.prepare_cache_if_necessary
    
    multiple_found = 0
    not_found = 0
    found = 0
    card_ids = Array.new

    # This is the for each for every record data call the block with each line as the parameter.
    tickcount("Processing tag-card-match and importing") do
      @config[:data].each do |entry|
        # Cache these once so we're not making new blocks on every loop
        default_match_criteria = entry.default_match_criteria if default_match_criteria.nil?
        loose_match_criteria = entry.loose_match_criteria if loose_match_criteria.nil?
        
        # First, try to match it programmatically, also check the loose criteria if we didn't get any strict matches
        matching_cards = find_cards_similar_to(entry, default_match_criteria)
        
        # If the normal criteria turned up nothing conclusive, check with human importer and/or log it
        normal_card = false
        if matching_cards.empty?
          # This is for the case where nothing matched at all on the strict criteria
          loosely_matching_cards = find_cards_similar_to(entry, loose_match_criteria)
          matched_card = @human_importer.get_human_result_for_entry(entry, loosely_matching_cards)
          if matched_card
            # Great, we got something
            matched_cards = [matched_card]
          else
            if loosely_matching_cards.count > 1
              multiple_found += 1
              log "\n[Multiple Records]There are multiple loosely matching cards found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
            else
              not_found += 1
              log "\n[No Record]There are no card found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
            end
          end
        elsif matching_cards.count > 1
          # This is where too much matched on the strict criteria
          matched_card = @human_importer.get_human_result_for_entry(entry, matching_cards)
          if matched_card
            # Great, we got something
            matched_cards = [matched_card]
          else
            multiple_found += 1
            log "\n[Multiple Records]There are multiple cards found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
          end
        else
          # Only 1 record for strict match, all is normal
          normal_card = true
        end

        # OK, we've been through all we can do in terms of recovery, et al.  Log the results, good or bad
        if matching_cards.count == 1
          card_id = matching_cards.first.id
          raise "card ID must be initialized!" if (card_id == -1)
          if (!card_ids.include?(card_id))
            found += 1
            card_ids << card_id
          else
            log "\nSomehow, there is a duplicated card with id: %s from headword: %s, pinyin: %s, meanings: %s" % [card_id, entry.headword, entry.pinyin, entry.meanings.join("/")]
          end
        end
      end
    end

    # Now actually do the SQL work from our in-memory card_ids array
    insert_card_tag_links_for_ids(@tag_id, card_ids)
    log("Finish inserting: %s with %s records not found and %s duplicates" % [card_ids.size, not_found, multiple_found], true)
    return found
  end # End of the method body
  
  def update_tag_count
    connect_db
    
    # Grab the tag_id first
    tag_id = @tag_id
    count = 0
    
    select_count_query = "SELECT count(card_id) as cnt FROM card_tag_link WHERE tag_id = #{tag_id}"
    $cn.execute(select_count_query).each do |cnt|
      count = cnt
    end
    
    update_query = "UPDATE tags_staging SET count = #{count} WHERE tag_id = #{tag_id}"
    $cn.execute(update_query)
  end
  
  # Find cards object which has similarities with the entry as the parameter
  def find_cards_similar_to(entry, criteria)
    # Make sure we only want the entry as an inheritance instances of Entry.
    raise "You must pass only Entry subclasses to find_cards_similar_to" unless entry.kind_of?(Entry)
    
    # Try the fast hash first -- saves us from having to loop through all the cards and do comparisons
    indices = []
    if (dict_entry = @entry_cache.entry_in_cache?(entry, :trad))
      if dict_entry.similar_to?(entry, criteria)
        indices << dict_entry
      end
    elsif (dict_entry = @entry_cache.entry_in_cache?(entry, :simp))
      if dict_entry.similar_to?(entry, criteria)
        indices << dict_entry
      end
    else
      # OK, we made it here.  No fast hash for us, it's loopy doopy time
      @entry_cache.card_entries_array.each do |card|
        if card.similar_to?(entry, criteria)
          indices << card
        end
      end
    end
    return indices
  end
  
#EOF
end