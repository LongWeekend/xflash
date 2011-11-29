# Single entry class from Jun Da's bigram frequency list
class BigramEntry < Entry
  
  #===================================
  # Parses a line from the CEDICT data source
  #===================================
  def parse_line (line = "")
    # A little sanity checking on line - nil, blank, or comment = returns
    return false if (line.nil? or (line == "") or (line.index("/*")))
    
    @original_line = line
    
    # Get the headwords, traditional then simplified
    @headword_simp = get_headword(line)
    return true
  end

  #==================================
  # Parsing helper methods
  #==================================
 
  # Extracts and returns headword block
  def get_headword(line = "")
    segments = line.split("\t")
    raise EntryParseException, "Unable to parse bigram data: %s" % [line] unless segments.count == 5
    
    return segments[1]
  end
 
end