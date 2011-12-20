# Single entry class from an HSK word list
class HSKEntry < Entry
  #===================================
  # Parses a line from the data source
  #===================================
  def parse_line (line = "")
    # A little sanity checking on line
    return false if line.nil? or (line == "")
    
    # Hold on to this for later when we need a unique ID
    @original_line = line
    
    # Set up to loop through the line one character at a time
    line_length = line.length - 1
    current_index = 0
    current_char = ""
    segments = []
    segments[0] = ""
    is_in_quotes = false
    
    for i in (0..line_length)
      current_char = line[i].chr
      # if we are at a delimiter...
      if current_char == "," and !is_in_quotes
        current_index = current_index + 1
        segments[current_index] = ""
      elsif current_char == '"' and !is_in_quotes
        is_in_quotes = true
      elsif current_char == '"' and is_in_quotes
        is_in_quotes = false
      else
        # Otherwise add the character
        segments[current_index] = segments[current_index] + current_char
      end
    end

    # This stops us from getting headers and other non-data rows
    # In the HSK data provided for the level 2 and above, it has the comma in the end of
    # a line and that causes the "\r\n" is in the 6th element of a segment
    if segments.count >= 5 and segments[0].numeric?
      @grade = segments[1]
      @headword_simp = segments[2]
      reading = segments[3]
      @pinyin = reading
      @pinyin_diacritic = Entry.get_pinyin_unicode_for_reading(reading)
      @meanings = []
      segments[4].strip.split("; ").each do |meaning|
        @meanings << Meaning.new(meaning)
      end
      return true
    else
      return false
    end
  end
end