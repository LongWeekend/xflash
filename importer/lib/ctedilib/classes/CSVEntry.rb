#!/usr/bin/env ruby -w
# encoding: UTF-8
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
      # The first gsub removes numbers, parenthesis and quotes, the second removes variant char in any "headword/variant char" pattern
      @headword_trad = segments[2].gsub(/["\(\)1-5（）]/,"").gsub(/(\/.+)/,"").strip
      
      # These cards don't have a simplified headword, but it may aid in matching, so set them both here.
      @headword_simp = @headword_trad

      # The first gsub removes parenthesis and quotes, the second removes variant char in any "reading/variant reading" pattern
      pinyin = segments[3].gsub(/["\(\)（）]/,"").gsub(/(\/.+)/,"").strip
      # This extra function call strips ouet any "stupid" round  tone-3 unicode points and replaces them with angled ones
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
      raise EntryParseException, "Improperly formatted CSV line: %s" % [line]
    end

  end
  
  # OVERRIDES
  
  def default_match_criteria
    normal_criteria = Proc.new do |dict_entry, tag_entry|
      same_headword = (dict_entry.headword_trad == tag_entry.headword_trad) || (dict_entry.headword_simp == tag_entry.headword_simp)
      if same_headword
        # Comparing the pinyin/reading - ignore case for now
        tag_pinyin = tag_entry.pinyin_diacritic.gsub(" ","")
        dict_pinyin = dict_entry.pinyin_diacritic.gsub(" ","")
        
        # Don't use "downcase" in the case where "Surname" is one of the meanings.
        if dict_entry.meaning_txt.downcase.index("surname")
          same_pinyin = (dict_pinyin == tag_pinyin)
        else
          same_pinyin = (dict_pinyin.downcase == tag_pinyin.downcase)
        end
          
        # If we didn't match right away, also check for the funny tone changes 
        if (same_pinyin == false and (tag_pinyin.index("yí") or tag_pinyin.index("bú")))
          same_pinyin = (dict_pinyin.downcase == tag_pinyin.downcase.gsub("yí","yi1").gsub("bú","bu4"))
        end
          
        # The "return" keyword will F everything up when used in blocks!
        same_pinyin
      else
        false #hw did not match
      end
    end
    return normal_criteria
  end

end