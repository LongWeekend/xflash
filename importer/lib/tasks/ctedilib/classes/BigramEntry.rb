# Single entry class from Jun Da's bigram frequency list
class BigramEntry < Entry
  
  #===================================
  # Parses a line from the CEDICT data source
  #===================================
  def parse_line (line = "")
    # A little sanity checking on line - nil, blank, or comment = returns
    return false if (line.nil? or (line == "") or (line.index("/*")))
    
    @original_line = line
    
    # Get the headword
    segments = line.split("\t")
    raise EntryParseException, "Unable to parse bigram data: %s" % [line] unless segments.count == 5
    
    # Now check once to see if it's a fishy character
    headword = segments[1].strip
    mutual_information_value = segments[3]
    if headword.index("的") and (mutual_information_value < 3.5)
      raise EntryParseException, "Not processing fishy bigram entry: %s" % [line]
    else
      @headword_simp = headword
    end
    return true
  end
  
  #=================================
  # MATCHING METHODS
  #=================================
  
  def default_match_criteria
    criteria = Proc.new do |dict_entry, tag_entry|
      # These no-return statements weird me out
      same_headword = (dict_entry.headword_simp == tag_entry.headword_simp)
    end
    return criteria
  end
  
  # Override this method to do more than just headword matches -- use "headword contains"
  def loose_match_criteria
    criteria = Proc.new do |dict_entry, tag_entry|
      # These no-return statements weird me out
      contains_headword = (dict_entry.headword_simp.index(tag_entry.headword_simp).nil? == false)
    end
    return criteria
  end
  
end