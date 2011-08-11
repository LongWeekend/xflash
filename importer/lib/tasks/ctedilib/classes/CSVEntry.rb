# Single entry class from a book list
class CSVEntry < Entry
  #===================================
  # Parses a line from the data source
  #===================================
  def parse_line (line = "")
    init()
  
    # A little sanity checking on line
    if line.nil?
      pp "CSVEntry received a nil line"
      return false
    end
    
    segments = line.split(",\"")
    # This stops us from getting headers and other non-data rows
    if segments.count == 7 and segments[0].numeric?
      @headword_trad = segments[2].gsub("\"","").strip
      # This extra function call strips out any "stupid" round  tone-3 unicode points and replaces them with angled ones
      @pinyin = fix_unicode_for_tone_3(segments[3].gsub("\"","").strip)
      @grade = segments[4].gsub("\"","").strip
      pos_with_parens = segments[5].gsub("\"","")
      @pos << pos_with_parens[1..(pos_with_parens.length-2)]
      # Get the meanings with the comma separated, 
      # also, make sure we dont include the spaces.
      @meanings = Array.new()
      @meanings.add_element_with_stripping_from_array!(segments[6].chop().split(","))
      return true
    else
      return false
    end

  end

end