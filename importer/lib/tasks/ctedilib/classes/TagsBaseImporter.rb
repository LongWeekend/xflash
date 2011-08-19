class TagsBaseImporter
  
  include ImporterHelpers
  
  #### DESC: Class Constructors
  def initialize (data, configuration)
    @config = {}
    
    # Metadata for the tag itself
    @config[:metadata] = configuration
    
    # Data parsing parameter
    @config[:data] = data
    @config[:sql_buffer_size] = 1000
    @config[:sql_debug] = false
    
    return self
  end
  
  def get_card_id_for_charcaters(characters)
    
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