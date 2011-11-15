
module CardHelpers
  
  # Initialise the card-entries hash and 
  # get the card_id as the id and the card object as the values
  def get_all_cards_from_db()
     if ($card_entries)
       # puts "Card entries has been initialised, not going to initialised it twice."
       return false
     end
     
     prt "Retrieving card hash from database..."
     
     # Connect to db first
     connect_db()
     # Allocate a new hash object to the card_entries
     $card_entries = Hash.new()
     # Get the entire data from the database
     select_query = "SELECT * FROM cards_staging"
     result_set = $cn.execute(select_query)
     
     # For each record in the result set
     result_set.each(:symbolize_keys => true, :as => :hash) do |rec|
       # Initialise the card object
       card = CardEntry.new()
       card.parse_line(rec)
       # Get the card id and makes that a symbol for the hash key.
       card_id = rec[:card_id]
       # puts "Inserting to hash with key: %s" % [card_id.to_s()]
       $card_entries[card_id.to_s().to_sym()] = card
     end # End for-each
     
     prt "...Finished."
  end # End for method definition
  
  # Find cards object which has similarities with the entry as the parameter
  def find_cards_similar_to(entry)
    # Make sure we only want the entry as an 
    # inheritance instances of Entry.
    if (!entry.kind_of?(Entry))
      return nil
    end
    
    # If this has not been setup yet
    get_all_cards_from_db()
    
    # Prepare the result to put the matches and 
    # the cards object from the Hash-values
    result = Array.new()
    cards = $card_entries.values()
    
    criteria = Proc.new do |headword, same_pinyin, same_meaning, is_proper_noun|
      # Don't match proper nouns, it tends to be surnames and such
      result = same_pinyin || same_meaning || (is_proper_noun == false)
      
      if (!result)
        # This is a little bit strange as both the pinyin nor the meaning
        # is the same. This is better to be logged.
        # p "Both pinyin nor the meaning is the same, but there is a card with headword #{headword}."
      end
      
      #return with the result
      result
    end
  
    #matches = cards.select { |card| card.similar_to?(entry, $options[:likeness_level][:partial_match]) }
    index = cards.index { |card| card.similar_to?(entry, criteria) }
    return cards[index] unless ((index==nil)||(index==0))
    return nil
  end # End for method definition


  # DESC: Combines arrays and ensures they are flatten/compacted/unique
  def combine_and_uniq_arrays(array1, *others)
    result = []
    result << array1
    others.each do |arr|
      result << arr
    end
    return result.flatten.compact.uniq
  end
  
    # XFORMATION: Remove common English stop words from string
  def xfrm_remove_stop_words(str)
    stop_words = ['Variant','variant', 'Erhua', 'Counter', 'Has', 'I', 'me', 'a', 'an', 'am', 'are', 'as', 'at', 'be', 'by','how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'than', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will', 'with', 'the']
    results = []
    str.gsub!($regexes[:inlined_tags], "") ## remove tag blocks
    str.split(' ').each do |sstr|
      # remove non word characters from string
      results << sstr unless stop_words.index(sstr.gsub(/[^a-zA-Z|\s]/, '').strip)
    end
    return results.flatten.compact.join(' ')
  end

  
end