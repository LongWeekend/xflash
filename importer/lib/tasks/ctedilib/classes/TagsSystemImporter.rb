class TagsSystemImporter < TagsBaseImporter
  
  include CardHelpers
  
  def empty_staging_tables
    
  end
  
  def import
    # Open the connection to the database first
    connect_db()
    
    # Insert into the tags_staging first
    # to get the parent of the tags.
    setup_tag_row()
    
    not_found = 0
    found = 0
    card_ids = Array.new()
    @insert_tag_link_query = "INSERT card_tag_link(tag_id, card_id) VALUES(%s,%s);"
    
    #Then do the loop by its super and process every data.
    super do |rec|
      # Debug purposes only.
      # puts ("Processing: %s" % [rec.headword_trad])
      insert_query = ""
      result = find_cards_similar_to(rec)
      if (result == nil)
        not_found += 1
        log "\n[No Record]There are no card found in the card_staging with headword: %s. Reading: %s" % [rec.headword_trad, rec.pinyin]
      else
        found += 1
        card_id = result.id
        if (!card_ids.include?(card_id))
          card_ids << card_id
          insert_query << @insert_tag_link_query % [@tag_id, card_id]
        else
          # There is a same card in the list of added card.
          log "\nSomehow, there is a duplicated card with id: %s from headword: %s, pinyin: %s, meanings: %s" % [card_id, rec.headword_trad, rec.pinyin, rec.meanings.join("/")]
        end
      end
      
      # This will return to the one calling this blocks
      # without the keyword return, seems strange, but works!
      insert_query
    end unless @config[:data] == nil # End of the super do |rec| loop

    log "\n"
    log ("Finish inserting: %s with %s records not found" % [found.to_s(), not_found.to_s()], true)
  end # End of the method body
  
end