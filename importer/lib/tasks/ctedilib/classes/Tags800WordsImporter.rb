class Tags800WordsImporter < TagsBaseImporter
  
  include CardHelpers
  
  def empty_staging_tables
    
  end
  
  def import
    # Open the connection to the database first
    connect_db()
    
    #Then do the loop by its super and process every data.
    super do |rec|
      # Debug purposes only.
      #puts ("Processing: %s" % [rec.headword_trad])
      
      result = find_cards_similar_to(rec)
      count = result.length()
      if (count <= 0)
        puts ("[No Record]There are no card found in the card_staging with headword: %s. Reading: %s\n\n" % [rec.headword_trad, rec.pinyin])
      #else
      #  puts ("Card %s found for entry: %s\n" % [rec.to_s(), result[0].to_s()])  
      end
      
    end # End of the super do |rec| loop
    
  end # End of the method body
  

  
end