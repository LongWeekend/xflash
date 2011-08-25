class TagsBaseImporter
  
  include ImporterHelpers
  
  #### DESC: Class Constructors
  def initialize (data, configuration)
    @config = {}
    @tag_id = 0
    
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
  
  def self.tear_down_all_tags
    connect_db()
    
    $cn.execute("TRUNCATE TABLE card_tag_link")
    $cn.execute("TRUNCATE TABLE tags_staging")
  end
  
  def clean_existing_tags_staging
    # Make sure we have the shortname and its not blank
    short_name = @config[:metadata].short_name()
    if short_name.strip().length() <= 0
      raise "Short_name is not provided in the configuration meta data, hence exception is thrown!"
    end

    # Prepare for the checking whether the existing tag has been inserted before.
    connect_db()
    removed_tag_id = -1
    select_query = "SELECT tag_id FROM tags_staging WHERE short_name = '%s'" % [short_name] 
    $cn.execute(select_query).each do |tag_id|
      removed_tag_id = tag_id[0]
    end
    
    if removed_tag_id >= 0
      $cn.execute("DELETE FROM tags_staging WHERE tag_id='#{removed_tag_id}'")
      $cn.execute("DELETE FROM card_tag_link WHERE tag_id='#{removed_tag_id}'")
    end
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
  
  def get_card_id_for_charcaters(characters)
    
  end
  
  def get_log_dump_filename
    tag_name = @config[:metadata].short_name()
    return "#{tag_name}-log.txt"
  end
  
  def setup_tag_row
    # Clean up before doing anything first.
    clean_existing_tags_staging
    # Try to connect to the database
    connect_db()
  
    # Grab the config and try inserting into the tags_staging table as row
    config = @config[:metadata]
    inserted_short_name = config.short_name
    insert_query = "INSERT INTO tags_staging(tag_name, tag_type, short_name, description, source_name, source, visible, parent_tag_id, force_off) VALUES('%s', '%s', '%s', '%s', '%s', '%s', %s, %s, %s)" %
                      [config.tag_name, config.tag_type, config.short_name, config.description, config.source_name, config.source, config.visible, config.parent_tag_id, config.force_off]
            
    # Execute the query
    $cn.execute(insert_query)
    
    # After executing, get the tag_id and set it globally
    select_query = "SELECT tag_id FROM tags_staging WHERE short_name='%s'" % [inserted_short_name]
    $cn.execute(select_query).each do |tag_id|
    @tag_id = tag_id
    end
    
    # Puts the feedback to the user
    log ("Inserted into the tags_staging table for short_name: %s with tag_id: %s" % [inserted_short_name, @tag_id], true)
    prt_dotted_line
  rescue StandardError => err
    # In case the is some error is hapenning, try to delete from the databse first,
    # if a row has been inserted.
    if ((inserted_short_name != nil) && (inserted_short_name.strip().length() > 0))
      delete_query = "DELETE FROM tags_staging WHERE short_name='%s'" % [inserted_short_name]
      $cn.execute(delete_query)
    end
    raise "Failed in inserting into the tags_staging with the configuration: %s\nUnderlying error was: %s" % [config, err]
  end
  
  # DESC: Abstract method, call 'super' from the child class to use the
  #       built-in functionality.
  def import(&block)
    # Sanity Check
    if !@config[:data]
      exit_with_error("Importer not configured correctly.", @config)
    end
    
    bulkSQL = BulkSQLRunner.new(@config[:data].size, @config[:sql_buffer_size], @config[:sql_debug])
    # This is the for each for every record data call the block with
    # each line as the parameter.
    tickcount("Processing tag-card-match and importing") do
      @config[:data].each do |rec|
        query = block.call(rec)
        # Its alright to put in a blank string to the bulkSQL as it keeps counting and 
        # flush the reminder of the data even if the buffer is not yet full. (when all the data has been proceessed)
        # We want that to happen and just in case we cant find a card, still want the rest to be in the table.
        bulkSQL.add(query) #unless ((query==nil)||(query.strip().length()<=0))
      end
    end
    
  end
  
end