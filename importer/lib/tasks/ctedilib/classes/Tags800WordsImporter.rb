class Tags800WordsImporter < TagsBaseImporter
  
  include CardHelpers
  
  def empty_staging_tables
    
  end
  
  def import
    # Open the connection to the database first
    # and get the entire cards on the hash table
    connect_db()
    get_all_cards_from_db()
    
    not_found = 0
    found = 0
    card_ids = Array.new()
    @insert_tag_link_query = "INSERT card_tag_link(tag_id, card_id) VALUES(%s,%s);"
    @tag_id = 0
    
    #Then do the loop by its super and process every data.
    super do |rec|
      # Debug purposes only.
      # puts ("Processing: %s" % [rec.headword_trad])
      insert_query = ""
      result = find_cards_similar_to(rec)
      count = result.length()
      if (count <= 0)
        not_found += 1
        puts ("[No Record]There are no card found in the card_staging with headword: %s. Reading: %s\n\n" % [rec.headword_trad, rec.pinyin])
      else
        found += 1
        card_id = result[0].id
        if (!card_ids.include?(card_id))
          card_ids << result[0].id
          insert_query << @insert_tag_link_query % [@tag_id, card_id]
        end
      end
      
      # This will return to the one calling this blocks
      # without the keyword return, seems strange, but works!
      insert_query
    end # End of the super do |rec| loop

    puts ("Finish inserting: %s with %s records not found" % [found.to_s(), not_found.to_s()])
    
  end # End of the method body
end