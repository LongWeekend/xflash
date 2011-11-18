require 'test/unit'

class CardEntriesTest < Test::Unit::TestCase
  
  include CardHelpers

  # Test on getting the entire cards on the big hash table
  def test_getting_all_cards
    get_all_cards_from_db()
    expected_num_of_cards = 99139
    assert_equal($card_entries.length(), expected_num_of_cards)
  end
  
  # Test on quick looking for a card with the same headwords
  def test_look_for_headword_cards_1
    get_all_cards_from_db()
    
    lookup_character = "丈母娘"
    result = $card_entries_array.select {|card| card.headword_trad == lookup_character}
  
    assert_equal(result.length(), 1)
    assert_equal(result[0].headword_trad, lookup_character)
  end
  
  # Test on quick looking for a card with the same headwords
  def test_look_for_headword_cards_2
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    
    result = TagImporter.find_cards_similar_to(entry)
    assert_equal(result.headword_trad, entry.headword_trad)
  end
    
  def test_similarity_exact_true
    # Get the entry
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    
    # Get the card
    connect_db()
    card = nil
    select_query = "SELECT * FROM cards_staging WHERE headword_trad = '愛戴'"
    $cn.execute(select_query).each(:symbolize_keys => true, :as => :hash) do |rec|
      card = CEdictEntry.new
      card.hydrate_from_hash(rec)
    end    
        
    criteria = Proc.new do |headword, same_pinyin, same_meaning, is_proper_noun|
      return same_pinyin || same_meaning || (is_proper_noun == false)
    end
    
    assert_equal(card.similar_to?(entry, criteria))
  end
  
  def test_similarity_partial_true
    # The character 打擊 has different reading, but has the same meaning and headword
    # Get the entry
    entry = CSVEntry.new
    entry.parse_line("378,\"0381\",\"打擊\",\"dăjí\",\"A\",\"(VA)\",\"strike,hit,attack\"")

    # Get the card
    connect_db()
    card = nil
    select_query = "SELECT * FROM cards_staging WHERE headword_trad = '打擊'"
    $cn.execute(select_query).each(:symbolize_keys => true, :as => :hash) do |rec|
      card = CEdictEntry.new
      card.hydrate_from_hash(rec)
    end    
    
    criteria = Proc.new do |headword, same_pinyin, same_meaning, is_proper_noun|
      return same_pinyin || same_meaning || (is_proper_noun == false)
    end
    assert_equal(card.similar_to?(entry, criteria), true)
   end
   
   def test_similarity_one_true
     # Get the entry
     entry = CSVEntry.new
     entry.parse_line("377,\"0378\",\"打發\",\"dăfā\",\"A\",\"(VA)\",\"to while away (one's time)\"")

     # Get the card
     connect_db()
     card = nil
     select_query = "SELECT * FROM cards_staging WHERE headword_trad = '打發'"
     $cn.execute(select_query).each(:symbolize_keys => true, :as => :hash) do |rec|
       card = CEdictEntry.new
       card.hydrate_from_hash(rec)
     end    

    criteria = Proc.new do |headword, same_pinyin, same_meaning, is_proper_noun|
      return same_pinyin || same_meaning || (is_proper_noun == false)
    end

     assert_equal(card.similar_to?(entry, criteria), true)
   end
   
   def test_find_variant
    get_all_cards_from_db()
    
    lookup_character = "龜"
    cards = $card_entries.values()
    result = cards.select {|card| card.headword_trad == lookup_character}
  
    assert_equal(result.length(), 1)
    assert_equal(result[0].headword_trad, lookup_character)
   end

end