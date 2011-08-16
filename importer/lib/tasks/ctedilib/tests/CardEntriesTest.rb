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
    cards = $card_entries.values()
    result = cards.select {|card| card.headword_trad == lookup_character}
  
    assert_equal(result.length(), 1)
    puts "Character %s has been found in card entry: %s" % [lookup_character, result[0]]
    assert_equal(result[0].headword_trad, lookup_character)
  end
  
  # Test on quick looking for a card with the same headwords
  def test_look_for_headword_cards_2
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    
    results = find_cards_similar_to(entry)
  
    assert_equal(results.length(), 1)
    puts "Entry %s has been found in card entry: %s" % [entry, results[0]]
    assert_equal(results[0].headword_trad, entry.headword_trad)
  end
  
  def test_look_for_headword_cards_3
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    
    results = find_cards_similar_to(entry)
  
    assert_equal(results.length(), 1)
    puts "Entry %s has been found in card entry: %s" % [entry, results[0]]
    assert_equal(results[0].headword_trad, entry.headword_trad)
  end
  
  def test_similarity_1
    # Get the entry
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    
    # Get the card
    connect_db()
    card = nil
    select_query = "SELECT * FROM cards_staging WHERE headword_trad = '愛戴'"
    $cn.execute(select_query).each(:symbolize_keys => true, :as => :hash) do |rec|
      card = CardEntry.new()
      card.parse_line(rec)
    end    
    
    # Assertion
    puts ("Comparing card:%s with entry: %s\n" % [card.to_s(), entry.to_s()])
    criteria = $options[:similarities_level][:headword] | $options[:similarities_level][:reading] | $options[:similarities_level][:meaning]
    assert_equal(card.similar_to?(entry, criteria), true)
  end
  
  def test_binary_operator
    a = $options[:similarities_level][:headword]
    b = $options[:similarities_level][:headword] | $options[:similarities_level][:reading]
    puts a
    puts b
  end

end