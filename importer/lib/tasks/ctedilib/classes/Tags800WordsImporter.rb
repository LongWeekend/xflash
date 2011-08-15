class Tags800WordsImporter < TagsBaseImporter
  
  def empty_staging_tables
    
  end
  
  def import
    # Open the connection to the database first
    connect_db()
    
    #Then do the loop by its super and process every data.
    super do |rec|
      # Debug purposes only.
      #puts ("Processing: %s" % [rec.headword_trad])
      
      # Prepare for some local variables to indicate the exact_match and the query
      exact_match = false
      count = 0
      select_query = "SELECT * FROM cards_staging"
      result_set = $cn.execute(select_query)
      
      result_set.each(:symbolize_keys => true, :as => :hash) do |rec|
        
        card = CardEntry.new()
        card.parse_line(rec)
        
      end
      
=begin
      result_set.each do | card_id, headword_trad, reading, meaning, meaning_fts |
        # Try to get the pinyin code for the reading 
        # for the card result with the same headword  
        pinyin_unicode = get_pinyin_unicode_for_reading(reading.downcase())
        ### Made the reading strings in a downcase for consistencies comparison (above)
        ### Also, downcase the pinyin string from the tag entry (below)
        if (pinyin_unicode == rec.pinyin.downcase())
          #puts ("Character: %s has pinyin unicode %s is a match with rec %s." % [rec.headword_trad, rec.pinyin, pinyin_unicode])
          exact_match = true
        else
          # Get the array of meanings from the database
          meanings = Array.new()
          meanings.add_element_with_stripping_from_array!(meaning.split(";"))
          meanings.add_element_with_stripping_from_array!(meaning_fts.split(";"))
          
          # Try to match it between the entry's meaning
          # and the database meaning
          similar = rec.has_similar_meaning?(meanings)
          if (similar)
            # puts ("---------------")
            # puts ("[%s]The reading: %s has similar pinyin with: %s. Result: %s" % [rec.headword_trad, reading, rec.pinyin, pinyin_unicode])
            # puts ("Meaning %s is inside %s" % [rec.meanings.join("//").to_s(), meanings.join(";").to_s()])
            # puts ("---------------")
            exact_match = true
          end
        end
        count = count + 1
        end # End of the query loop
        
        if (count <= 0)
          puts ("[No Record]There are no card found in the card_staging with headword: %s. Reading: %s\n\n" % [rec.headword_trad, rec.pinyin])
        elsif (!exact_match)
          puts ("There are no card found for entry: %s, with reading: %s\nMeaning: %s\n\n" % 
                  [rec.headword_trad, rec.pinyin, rec.meanings.join("//").to_s()])  
        end
        
=end 
      
    end # End of the super do |rec| loop
    
  end # End of the method body
  

  
end