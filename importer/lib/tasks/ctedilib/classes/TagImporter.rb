class TagImporter
  
  include DatabaseHelpers
  
  #### DESC: Class Constructors
  def initialize (data, configuration, prev_entry_cache = false)
    @config = {}
    @tag_id = nil
    @human_importer = HumanTagImporter.new
    if prev_entry_cache
      @entry_cache = prev_entry_cache
    else
      @entry_cache = EntryCache.new
    end
    
    # Metadata for the tag itself
    @config[:metadata] = configuration
    
    # Data parsing parameter
    @config[:data] = data
    @config[:sql_buffer_size] = 1000
    @config[:sql_debug] = false
    
    @log_stream = nil
    if (@config[:metadata].file_dump_trace())
      #Get the stream
      filename = get_log_dump_filename()
      @log_stream = File.new(filename, "a+")
      
      #Start the stream with the date and time.
      now = Date.today.to_datetime
      @log_stream << "#{now}\n"
    end
    
    return self
  end
  
  def tag_id
    @tag_id
  end
  
  def self.tear_down_all_tags
    connect_db()
    $cn.execute("TRUNCATE TABLE card_tag_link")
    $cn.execute("TRUNCATE TABLE tags_staging")
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
  
  def get_log_dump_filename
    folder_path = File.dirname(__FILE__) + "/../../../../log"
    tag_name = @config[:metadata].short_name()
    return "#{folder_path}/#{tag_name}-import.log"
  end
  
  def setup_tag_row
    connect_db
    config = @config[:metadata]
    
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
                        [config.tag_id, config.tag_name, config.tag_type, config.short_name, config.description, config.source_name, config.source, config.visible, config.parent_tag_id, config.force_off, config.editable]
    else
      # Most other cases -- just add a new tag
      insert_query = "INSERT INTO tags_staging(tag_name, tag_type, short_name, description, source_name, source, visible, parent_tag_id, force_off, editable) VALUES('%s', '%s', '%s', '%s', '%s', '%s', %s, %s, %s, %s)" %
                        [config.tag_name, config.tag_type, config.short_name, config.description, config.source_name, config.source, config.visible, config.parent_tag_id, config.force_off, config.editable]
    end
            
    # Execute the query
    $cn.execute(insert_query)

    return last_inserted_id
  end
    
  def import
    # Insert into the tags_staging first to get the parent of the tags.
    connect_db
    @tag_id = setup_tag_row
    log("Inserted into the tags_staging table for short_name: %s with tag_id: %s" % [@config[:metadata].short_name, @tag_id], true)
    
    # After creating the table, skip the import process if we have no card data
    if (@config[:data] == nil or @config[:data].empty?)
      prt "Skipping matching process for empty tag (no data passed in)"
      return @tag_id
    end
    
    @entry_cache.prepare_cache_if_necessary
    
    multiple_found = 0
    not_found = 0
    found = 0
    card_ids = Array.new()
    @insert_tag_link_query = "INSERT card_tag_link(tag_id, card_id) VALUES(%s,%s);"
    bulkSQL = BulkSQLRunner.new(@config[:data].size, @config[:sql_buffer_size], @config[:sql_debug])

    # This block defines how the cards should be matched (beyond having the same headwords)
    normal_criteria = Proc.new do |dict_entry, tag_entry|
      # Comparing the pinyin/reading - ignore case for now
      if tag_entry.pinyin.length > 0
        same_pinyin = (dict_entry.pinyin.downcase.gsub(" ","") == tag_entry.pinyin.downcase.gsub(" ",""))
        if (same_pinyin == false and (tag_entry.pinyin.index("yi2") or tag_entry.pinyin.index("bu2")))
          same_pinyin = (dict_entry.pinyin.downcase.gsub(" ","") == tag_entry.pinyin.downcase.gsub(" ","").gsub("yi2","yi1").gsub("bu2","bu4"))
        end
      elsif tag_entry.pinyin_diacritic
        same_pinyin = (dict_entry.pinyin_diacritic.downcase.gsub(" ","") == tag_entry.pinyin_diacritic.downcase.gsub(" ",""))
      end
      # The "return" keyword will F everything up when used in blocks!
      same_pinyin
    end
    
    # Use this when we want to match headword only -- we don't care about the particulars of the card
    loose_criteria = Proc.new do |dict_entry, tag_entry|
      true
    end

    # This is the for each for every record data call the block with each line as the parameter.
    tickcount("Processing tag-card-match and importing") do
      @config[:data].each do |entry|
        # First, try to match it programmatically, also check the loose criteria if we didn't get any strict matches
        matching_cards = find_cards_similar_to(entry, normal_criteria)
        
        # If the normal criteria turned up nothing conclusive, check with human importer and/or log it
        normal_card = false
        if matching_cards.empty?
          # This is for the case where nothing matched at all on the strict criteria
          loosely_matching_cards = find_cards_similar_to(entry, loose_criteria)
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
        if matching_cards.empty?
        elsif matching_cards.count > 1
        else
          found += 1
          card_id = matching_cards.first.id
          raise "card ID must be initialized!" if (card_id == -1)
          if (!card_ids.include?(card_id))
            card_ids << card_id
            bulkSQL.add((@insert_tag_link_query % [@tag_id, card_id]))
          else
            log "\nSomehow, there is a duplicated card with id: %s from headword: %s, pinyin: %s, meanings: %s" % [card_id, entry.headword, entry.pinyin, entry.meanings.join("/")]
          end
        end
      end
    end

    # Write any remaining records & update tag counts
    bulkSQL.flush
    update_tag_count

    log "\n"
    log("Finish inserting: %s with %s records not found and %s duplicates" % [found.to_s(), not_found.to_s(), multiple_found.to_s()], true)
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