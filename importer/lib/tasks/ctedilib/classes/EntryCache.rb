class EntryCache

  def initialize(init_card_array = [])
    @card_entries = false
    @card_entries_array = false
    
    @card_entries_by_headword = {}
    @card_entries_by_headword[:simp] = {}
    @card_entries_by_headword[:trad] = {}
    
    # Use this hash as a "blacklist" for any headwords we detect multiple times
    @dupe_headwords = {}
    @dupe_headwords[:simp] = {}
    @dupe_headwords[:trad] = {}
    
    # This is really for mock purposes -- skip around the SQL
    if init_card_array.empty? == false
      @card_entries = {}
      @card_entries_array = []
      init_card_array.each do |card|
        _cache_card(card)
      end
    end
  end
  
  # ======================
  # CUSTOM GETTERS
  # ======================
  
  def card_entries_array
    return @card_entries_array if @card_entries_array
    
    # Lazy load if we have to
    _cache_sql_cards(_get_cards_from_db)
    return @card_entries_array
  end
  
  def card_entries
    # Quick return if we're already done
    return @card_entries if @card_entries
    
    # Lazy load if we have to
    _cache_sql_cards(_get_cards_from_db)
    return @card_entries
  end

  # ======================
  # PUBLIC METHODS
  # ======================
  
  def prepare_cache_if_necessary
    if (@card_entries == false)
      tickcount("Caching cards_staging to memory...") do
        _cache_sql_cards(_get_cards_from_db)
      end
    end
  end

  def entry_in_cache?(entry = false,type = :trad)
    raise "Need an Entry subclass!" if (entry.kind_of?(Entry) == false)
    
    headword = (type == :trad) ? entry.headword_trad : entry.headword_simp
    dict_entry = false
    if @card_entries_by_headword[type].key?(headword)
      dict_entry = @card_entries_by_headword[type][headword]
    end
    
    return dict_entry
  end
  
  def size_of_headword_cache(type = :trad)
    return @card_entries_by_headword[type].count
  end
    
  # ======================
  # PRIVATE METHODS
  # ======================
  
  def _get_cards_from_db
    connect_db
    select_query = "SELECT * FROM cards_staging"
    result_set = $cn.execute(select_query)
    return result_set
  end
  
  # Initialise the card-entries hash and 
  # get the card_id as the id and the card object as the values
  def _cache_sql_cards(result_set)
    raise "Improper type passed to (should be mysql result set)" if (result_set.kind_of?(Mysql2::Result) == false)
    
    @card_entries = {}
    @card_entries_array = []
    
    result_set.each(:symbolize_keys => true, :as => :hash) do |rec|
      card = CEdictEntry.from_sql(rec)
      card.id = rec[:card_id]
      _cache_card(card)
    end 
  end
  
  def _cache_card(card)
    @card_entries[card.id.to_s().to_sym()] = card
    @card_entries_array << card
    _add_card_to_headword_idx_hash(card, :simp)
    _add_card_to_headword_idx_hash(card, :trad)
  end

  def _add_card_to_headword_idx_hash(card, type = :simp)
    hw = (type == :simp) ? card.headword_simp : card.headword_trad
  
    # DUPE HEADWORD FLAGGING - we don't want dupe headwords in our super fast hash
    is_flagged_dupe = @dupe_headwords[type].key?(hw)
    if (is_flagged_dupe == false)
      # Now check that it's not the second occurance
      is_dupe = @card_entries_by_headword[type].key?(hw)
      if is_dupe == false
        @card_entries_by_headword[type][hw] = card
      else
        # It's a dupe, pull out the original from the quick lookup headword hash, add key to dupes
        @card_entries_by_headword[type].delete(hw)
        @dupe_headwords[type][hw] = true
      end
    end
  end

end