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
    @cards_multiple_found = 0
    @cards_not_found = 0
    @duplicate_source_cards = 0
    @cards_matched = 0
    
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
  
  def cards_multiple_found
    @cards_multiple_found
  end
  
  def duplicate_source_cards
    @duplicate_source_cards
  end
  
  def cards_not_found
    @cards_not_found
  end
  
  def cards_matched
    @cards_matched
  end
  
  def get_log_dump_filename
    Rails.root.join("log",@config[:tag_configuration].short_name()+"-import.log").to_s
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
    update_tag_count(tag_id)
  end
    
  def match_cards
    # Quick return if this method isn't set up with any matching data
    if (@config[:data].nil? or @config[:data].empty?)
      prt "Skipping matching process for empty tag (no data passed in)"
      return []
    end
    
    @entry_cache.prepare_cache_if_necessary
    
    @cards_multiple_found = 0
    @cards_not_found = 0
    @cards_matched = 0
    @duplicate_source_cards = 0
    card_ids = Array.new

    # This is the for each for every record data call the block with each line as the parameter.
    tickcount("Processing tag-card-match for '%s' - %s cards" % [@config[:tag_configuration].short_name, @config[:data].count]) do
      @config[:data].each do |entry|
        # Cache these once so we're not making new blocks on every loop
        default_match_criteria = entry.default_match_criteria if default_match_criteria.nil?
        loose_match_criteria = entry.loose_match_criteria if loose_match_criteria.nil?
        
        # First, try to match it programmatically, also check the loose criteria if we didn't get any strict matches
        matching_cards = find_cards_similar_to(entry, default_match_criteria)
        
        # If the normal criteria turned up nothing conclusive, check with human importer and/or log it
        if matching_cards.empty?
          matching_cards = _match_entry_with_loose_criteria(entry, loose_match_criteria)
        elsif matching_cards.count > 1
          matching_cards = _match_entry_with_multiple_results(entry, matching_cards)
        end

        # OK, we've been through all we can do in terms of recovery, et al.  Log the results, good or bad
        if matching_cards.count == 1
          card_id = matching_cards.first.id
          raise "card ID must be initialized!" if (card_id == -1)
          # Don't include a card_id more than once in a tag (a "unique" operation basically)
          if (card_ids.include?(card_id) == false)
            @cards_matched += 1
            card_ids << card_id
          else
            # Make note of this
            @duplicate_source_cards += 1
          end
        end
      end # end of do block - each
    end # end of do block - tickcount
    log("Finish matching: %s with %s records not found and %s duplicates" % [card_ids.size, @cards_not_found, @cards_multiple_found], true)
    return card_ids
  end # End of the method body
  
  def _match_entry_with_loose_criteria(entry, loose_match_criteria)
    # This is for the case where nothing matched at all on the strict criteria
    loosely_matching_cards = find_cards_similar_to(entry, loose_match_criteria)
    matched_cards = []
    
    # Note that even if there is 1 record in loosely_matching_cards, we don't take it -- we pass it -- because we
    # want a human to look at it.  AFTER a human has looked at it, it will return from this method.
    matched_card = @human_importer.get_human_result_for_entry(entry, loosely_matching_cards)
    if matched_card
      # Great, we got something
      matched_cards << matched_card
    else
      if loosely_matching_cards.count > 1
        @cards_multiple_found += 1
        log "\n[Multiple Records]There are multiple loosely matching cards found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
      else
        @cards_not_found += 1
        log "\n[No Record]There are no card found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
      end
    end
    return matched_cards
  end
  
  def _match_entry_with_multiple_results(entry, matching_cards)
    # This is where too much matched on the strict criteria
    matched_cards = []
    matched_card = @human_importer.get_human_result_for_entry(entry, matching_cards)
    if matched_card
      # Great, we got something
      matched_cards << matched_card
    else
      @cards_multiple_found += 1
      log "\n[Multiple Records]There are multiple cards found in the card_staging with headword: %s. Reading: %s" % [entry.headword, entry.pinyin]
    end
    return matched_cards
  end
  
  def update_tag_count(tag_id = -1)
    connect_db
    
    # Grab the tag_id first
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