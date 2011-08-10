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
    
    #puts ("KCODE: " + $KCODE)
    
    #my_string = "\xC4\x81 \xC3\xA1 \xC7\x8E \xC3\xA0 \u+014D"
    
    
    #puts ("Test : %s" % my_string)
    
    #debugger
    #sym = "a1"
    
    #puts $chinese_reading_unicode[sym.to_sym] # + " ---- TEST"
    #puts "TEST---- " + [$chinese_reading_unicode[sym.to_sym]].pack('U*') + " ----TEST"
    
    #macron = [462].pack('U*')
    
    
    # This is the for each for every record data call the block with
    # each line as the parameter.
    @config[:data].each do |rec|
      block.call(rec)
    end
    
  end
  
end