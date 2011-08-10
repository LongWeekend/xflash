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
      select_query = "SELECT card_id, headword_trad, reading FROM cards_staging WHERE headword_trad = '%s'" % [rec.headword_trad]
      $cn.execute(select_query).each do | card_id, headword_trad, reading |
        # Try to get the pinyin code for the reading 
        # for the card result with the same headword  
        pinyin_unicode = get_pinyin_unicode_for_reading(reading)
        if (pinyin_unicode == rec.pinyin)
          #puts ("Character: %s has pinyin unicode %s is a match with rec %s." % [rec.headword_trad, rec.pinyin, pinyin_unicode])
          exact_match = true
        end
      end # End of the query loop
      
      if (!exact_match)
        puts ("There are no card found for entry: %s, with reading: %s\nMeaning: %s\n" % 
                [rec.headword_trad, rec.pinyin, rec.meanings.join("//").to_s()])  
      end
    end # End of the super do |rec| loop
    
  end # End of the method body
  
end