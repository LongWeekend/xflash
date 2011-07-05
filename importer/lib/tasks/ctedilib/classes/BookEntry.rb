# Single entry class from a book list
class BookEntry < Entry
  
  #===================================
  # Parses a line from the CEDICT data source
  #===================================
  def parse_line (line = "")
    init
  
    # A little sanity checking on line
    if line.nil?
      pp "BookEntry received a nil line"
      return false
    end
    
    # Get the headwords, traditional then simplified
    headword_arr = get_headwords(line)
    @headword_trad = headword_arr[0]
    @headword_simp = headword_arr[1]
    
    # Now get the reading
    @pinyin = get_pinyin(line)
    @meanings = get_meanings(line)
    
    return true
  end

  #==================================
  # Parsing helper methods
  #==================================
 
  # Extracts and returns headword block
  def get_headwords(line = "")
    first_tab = line.index("\t")
    second_tab = line.index("\t",first_tab+1)
    headwords = []
    headwords << line[0..first_tab].strip
    headwords << line[first_tab..second_tab].strip
    return headwords
  end
  
  def get_pinyin(line = "")
    beginning_of_meaning = line.index("/") - 1
    end_of_hw_trad = line.index("\t")
    end_of_hw_simp = line.index("\t",end_of_hw_trad+1)
    return line[end_of_hw_simp..beginning_of_meaning].strip
  end
  
  def get_meanings(line = "")
    first_index = line.index("/") + 1
    length = line.length
    meanings = line[first_index..length].split("/")
    return meanings
  end
  
end