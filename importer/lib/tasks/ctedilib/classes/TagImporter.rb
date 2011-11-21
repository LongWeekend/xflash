class TagImporter
  
  include DatabaseHelpers
  
  #### DESC: Class Constructors
  def initialize (data, configuration)
    @config = {}
    @tag_id = nil
    @human_importer = HumanTagImporter.new
    
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

    # After executing, get the tag_id and set it globally
    @tag_id = last_inserted_id
    
    # Puts the feedback to the user
    log("Inserted into the tags_staging table for short_name: %s with tag_id: %s" % [inserted_short_name, @tag_id], true)
    prt_dotted_line
  rescue StandardError => err
    # In case the is some error is hapenning, try to delete from the databse first,
    # if a row has been inserted.
    if (@tag_id != nil)
      delete_query = "DELETE FROM tags_staging WHERE tag_id='%s'" % [@tag_id]
      $cn.execute(delete_query)
    end
    raise "Failed in inserting into the tags_staging with the configuration: %s\nUnderlying error was: %s" % [config, err]
  end
    
  def import
    # Insert into the tags_staging first to get the parent of the tags.
    connect_db
    
    # TODO: This should really *return* the tag_id -- MMA 11.20.2011
    setup_tag_row
    
    # After creating the table, skip the import process if we have no card data
    if (@config[:data] == nil or @config[:data].empty?)
      prt "Skipping matching process for empty tag (no data passed in)"
      return @tag_id
    end
    
    multiple_found = 0
    not_found = 0
    found = 0
    card_ids = Array.new()
    @insert_tag_link_query = "INSERT card_tag_link(tag_id, card_id) VALUES(%s,%s);"
    bulkSQL = BulkSQLRunner.new(@config[:data].size, @config[:sql_buffer_size], @config[:sql_debug])

    # This is the for each for every record data call the block with each line as the parameter.
    tickcount("Processing tag-card-match and importing") do
      @config[:data].each do |rec|
        # First, try to match it programmatically
        result = TagImporter.find_cards_similar_to(rec)
        
        # If nothing found by the TagImporter, ask the HumanImporter
        if result.empty? or result.count > 1
          matched_card = @human_importer.get_human_result_for_entry(result)
          if matched_card
            result = [matched_card]
          else
            if result.empty?
              not_found += 1
              log "\n[No Record]There are no card found in the card_staging with headword: %s. Reading: %s" % [rec.headword, rec.pinyin]
            else
              multiple_found += 1
              log "\n[Multiple Records]There are multiple cards found in the card_staging with headword: %s. Reading: %s" % [rec.headword, rec.pinyin]
            end
          end
        end
        
        # Finally, register the match if we have one
        if result.count == 1
          found += 1
          card_id = result[0].id
          if (!card_ids.include?(card_id))
            card_ids << card_id
            bulkSQL.add((@insert_tag_link_query % [@tag_id, card_id]))
          else
            log "\nSomehow, there is a duplicated card with id: %s from headword: %s, pinyin: %s, meanings: %s" % [card_id, rec.headword, rec.pinyin, rec.meanings.join("/")]
          end
        end
      end
    end

    # Write any remaining records & update tag counts
    bulkSQL.flush
    update_tag_count

    log "\n"
    log("Finish inserting: %s with %s records not found and %s duplicates" % [found.to_s(), not_found.to_s(), multiple_found.to_s()], true)
    return @tag_id
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
  def self.find_cards_similar_to(entry)
    # Make sure we only want the entry as an inheritance instances of Entry.
    raise "You must pass only Entry subclasses to find_cards_similar_to" unless entry.kind_of?(Entry)
    
    # If this has not been setup yet
    TagImporter.get_all_cards_from_db()
    
    # This block defines how the cards should be matched (beyond having the same headwords)
    criteria = Proc.new do |dict_entry, tag_entry|
      # Comparing the pinyin/reading - ignore case for now
      if tag_entry.pinyin.length > 0
        same_pinyin = (dict_entry.pinyin.downcase.gsub(" ","") == tag_entry.pinyin.downcase.gsub(" ",""))
      elsif tag_entry.pinyin_diacritic
        same_pinyin = (dict_entry.pinyin_diacritic.downcase.gsub(" ","") == tag_entry.pinyin_diacritic.downcase.gsub(" ",""))
      end
      result = same_pinyin
      # The "return" keyword will F everything up when used in blocks!
      result
    end
    
    # Try the fast hash first -- saves us from having to loop through all the cards and do comparisons
    indices = []
    if $card_entries_by_headword[:simp].key?(entry.headword_simp)
      dict_entry = $card_entries_by_headword[:simp][entry.headword_simp]
      if dict_entry.similar_to?(entry, criteria)
        indices << dict_entry
      end
    elsif $card_entries_by_headword[:trad].key?(entry.headword_trad)
      dict_entry = $card_entries_by_headword[:trad][entry.headword_trad]
      if dict_entry.similar_to?(entry, criteria)
        indices << dict_entry
      end
    else
      # OK, we made it here.  No fast hash for us, it's loopy doopy time
      $card_entries_array.each do |card|
        if card.similar_to?(entry, criteria)
          indices << card
        end
      end
    end
    return indices
  end

  # Initialise the card-entries hash and 
  # get the card_id as the id and the card object as the values
  def self.get_all_cards_from_db()
    # Card entries has been initialised, not going to initialised it twice.
    return if $card_entries
    
    tickcount("Retrieving card hash from database...") do
      connect_db()
      # Allocate a new hash object to the card_entries
      $card_entries = Hash.new()
      $card_entries_array = []
      
      # Keep an index of all cards sorted by both trad & simp headword
      $card_entries_by_headword = {}
      $card_entries_by_headword[:simp] = {}
      $card_entries_by_headword[:trad] = {}
      
      # Use this hash as a "blacklist" for any headwords we detect multiple times
      $dupe_headwords = {}
      $dupe_headwords[:simp] = {}
      $dupe_headwords[:trad] = {}

      # Get the entire data from the database
      select_query = "SELECT * FROM cards_staging"
      result_set = $cn.execute(select_query)
      
      # For each record in the result set
      result_set.each(:symbolize_keys => true, :as => :hash) do |rec|
        # Initialise the card object
        card = CEdictEntry.from_sql(rec)
        card.id = rec[:card_id]
        # Get the card id and makes that a symbol for the hash key.
        # puts "Inserting to hash with key: %s" % [card_id.to_s()]
        $card_entries[card.id.to_s().to_sym()] = card
        $card_entries_array << card
        TagImporter._add_card_to_headword_idx_hash(card, :simp)
        TagImporter._add_card_to_headword_idx_hash(card, :trad)
      end 
    end #tickcount
  end

  def self._add_card_to_headword_idx_hash(card, type = :simp)
    hw = (type == :simp) ? card.headword_simp : card.headword_trad
  
    # DUPE HEADWORD FLAGGING - we don't want dupe headwords in our super fast hash
    is_flagged_dupe = $dupe_headwords[type].key?(hw)
    if (is_flagged_dupe == false)
      # Now check that it's not the second occurance
      is_dupe = $card_entries_by_headword[type].key?(hw)
      if is_dupe == false
        $card_entries_by_headword[type][hw] = card
      else
        # It's a dupe, pull out the original from the quick lookup headword hash, add key to dupes
        $card_entries_by_headword[type].delete(hw)
        $dupe_headwords[type][hw] = true
      end
    end
  end

  
#EOF
end