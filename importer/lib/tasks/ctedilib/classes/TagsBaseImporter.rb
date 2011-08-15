class TagsBaseImporter
  
  include ImporterHelpers
  
  #### DESC: Class Constructors
  def initialize (data)
    @config = {}
    @config[:data] = data
    
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
    
    # This is the for each for every record data call the block with
    # each line as the parameter.
    @config[:data].each do |rec|
      block.call(rec)
    end
    
  end
  
end