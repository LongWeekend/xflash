  
  # PINYIN XFRM
  def transform_pinyin(pinyin = "")
    syllables = [] 
    pinyin.split(" ").each do |syllable|
    
      # Get the tone number, then kill it
      tone_no_location = syllable.length - 1
      tone_number = syllable[tone_no_location..tone_no_location+1]
      syllable = syllable[0..tone_no_location-1]
      
      # Tone 1 - flat
      # Tone 2 - up
      # Tone 3 - down then up
      # Tone 4 - down
      if tone_number == "1"
      elsif tone_number == "2"
      elsif tone_number == "3"
      elsif tone_number == "4"
      else
        print "WTF - tone number %s" % tone_number
      end
#      ǒō
#      īìǐí
      
      # If there is only one vowel, it gets the mark!
#      vowel_count_regex = 
      
      # Determine which vowel gets the diacritic mark
      vowels_regex = /([aeiou]{1})/
      num_vowels = 0
      replace_position = 0
      last_vowel = ""
      vowel_string = ""
      curr_vowel = ""
      syllable.scan(vowels_regex) do |match|
        match.each do |tmp_vowel|
          vowel_string = "%s%s" % [vowel_string, tmp_vowel]
          num_vowels = num_vowels + 1
          last_vowel = curr_vowel
          curr_vowel = tmp_vowel
          pp "Current vowel: %s Last vowel: %s" % [curr_vowel, last_vowel]
          # RULE #1 - if the vowel is an a or an e, it always takes the mark!
          if curr_vowel == "a" or curr_vowel == "e"
            replace_position = num_vowels - 1
          # RULE #2 - If there are two vowels, and the first one is an "i" or a "u", then the second one gets it
          elsif last_vowel == "i" or last_vowel == "u"
            replace_position = num_vowels - 1
          end
        end
      end
      

#      vowel_to_replace = vowel_string[replace_position..replace_position+1]
      new_vowel_string[replace_position] = "x"
      pp new_vowel_string
      pp vowel_string
      debugger
      syllable = syllable.gsub(vowel_string,new_vowel_string)
      
      pp syllable

#      change_location = syllable.length - 2
#      old_letter = syllable[change_location]
      
#      syllable[change_location] = @@pinyin_xfrm_array[tone_number][old_letter]
      syllables << syllable
    end
    return syllables.join(" ")
  end