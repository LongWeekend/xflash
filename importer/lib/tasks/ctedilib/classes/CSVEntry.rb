# Single entry class from a book list
class CSVEntry < Entry
  #===================================
  # Parses a line from the data source
  #===================================
  def parse_line (line = "")
    # A little sanity checking on line
    return false if line.nil? or (line == "")

    @original_line = line

    segments = line.split(",\"")
    # This stops us from getting headers and other non-data rows
    if segments.count == 7 and segments[0].numeric?
      @headword_trad = segments[2].gsub("\"","").strip

      # This extra function call strips ouet any "stupid" round  tone-3 unicode points and replaces them with angled ones
      pinyin = segments[3].gsub("\"","").strip
      pinyin = Entry.fix_unicode_for_tone_3(pinyin)
      
      # Test if the reading is already encoded
      stripped_numbers = pinyin.gsub(/[1-5]+/,"")
      
      if (stripped_numbers == pinyin)
        @pinyin_diacritic = pinyin
      else
        @pinyin = pinyin
        @pinyin_diacritic = Entry.get_pinyin_unicode_for_reading(pinyin)
      end
      
      @grade = segments[4].gsub("\"","").strip
      pos_with_parens = segments[5].gsub("\"","")
      @pos << pos_with_parens[1..(pos_with_parens.length-2)]

      # We dont want the extra quotes in the end of the meaning, do we?
      clean_raw_meanings = segments[6].chop().gsub("\"","")
      
      # Get the meanings with the comma separated, 
      # also, make sure we dont include the spaces.
      @meanings = []
      clean_raw_meanings.split(",").each do |meaning|
        @meanings << Meaning.new(meaning)
      end
      return true
    elsif segments[0].gsub("\"","").strip.match($regexes[:single_letter])
      return false
    else
      raise "Improperly formatted CSV line: %s" % [line]
    end

  end

end