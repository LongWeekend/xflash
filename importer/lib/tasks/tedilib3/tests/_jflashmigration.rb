require 'test/unit'

class JFlashMigrationTest < Test::Unit::TestCase

  def setup_class_instance
    migration = JFlashMigration.new
    return migration
  end

  def test_dry_run
    migration = setup_class_instance
    migration.set_dry_run
    migration.run
  end

  def test_match_readings
    migration = setup_class_instance
    match_type, match_data = migration.match_readings("ベータカロチン; ベタカロチン","ベータカロチン; ベタカロチン")
    assert_equal("RM", match_type, "Readings not matched properly!")
  end

  def test_match_readings_partial
    migration = setup_class_instance
    match_type, match_data = migration.match_readings("ベータカロチン; ベータカロテン; ベタカロチン","ベータカロチン; ベタカロチン")
    assert_equal("RP", match_type, "Readings not matched properly!")
  end

  def test_get_matching_cards
    migration = setup_class_instance
    connect_db
    old_card_id = 145760
    new_card_id = 148574
    old_cards_hash = JFlashMigration.create_buffer_comparision_data({:table => "MERGE_cards_staging_humanised", :where => "card_id=#{new_card_id}" })
    migration.set_buffered_cards(old_cards_hash)
    sql_data = $cn.execute("SELECT card_id, headword, alt_headword, reading, meaning FROM MERGE_cards_staging_rel1  WHERE card_id=#{old_card_id}") 
    sql_data.each do |card_id, headword, alt_headword, reading, meaning|
      migration.get_matching_cards(old_cards_hash, card_id, headword, alt_headword, reading, meaning).each do |m|
        match_txt = m[:results].compact.join("_")
        assert_equal("HM_RM_MM", match_txt, "Match type did not match! :D")
      end
    end
  end
  
  def test_match_headwords
     migration = setup_class_instance
    old_card_ids = JFlashMigration.create_buffer_comparision_data({:table =>"cards_staging_rel1"})
    migration.set_buffered_cards(old_card_ids)
    match_type, match_data = migration.match_headwords(old_card_ids,"１０００円")
    assert_equal("HM", match_type, "Headword not matched properly!")
  end

  def test_match_meaning_partial
    migration = setup_class_instance

    old_meanings = []
    new_meanings =[]

    old_meanings << "x-mark (used to indicate an incorrect answer in a test, etc.) (noun); impossibility  /  futility  /  uselessness (ペケ only)"
    new_meanings << "x-mark (used to indicate an incorrect answer in a test, etc.) (noun); impossibility / futility / uselessness"

    old_meanings << "beta-carotene (noun)"
    new_meanings << "beta-carotene (some stuff) (noun)"

    old_meanings << "Ah! (expression of surprise, recollection, etc.)  /  Oh! (interjection); Hey! (to get someone's attention)"
    new_meanings << "Ah! (expression of surprise, recollection, etc.) / Oh!; Hey! (to get someone's attention)"

    old_meanings << "palace  /  (in China built by Wu Dynasty King) (noun)"
    new_meanings << "palace (in China built by Wu Dynasty King) (noun)"
    
    old_meanings << "mark cf. Mark (noun)"
    new_meanings << "mark (cf. Mark) (noun)"
    
    old_meanings << "leftovers (after filleting a fish) (noun); rice chaff; flaw (esp. of a person); rough  /  roughly (prefix); crude  /  raw  /  natural  /  wild"
    new_meanings << "leftovers (after filleting a fish) (noun, prefix); rice chaff; flaw (esp. of a person) / rough / roughly (prefix); crude / raw / natural / wild"
    
    for i in 0..old_meanings.size-1 do
      match_type, match_data = migration.match_meaning_partial(old_meanings[i], new_meanings[i])
      assert_equal("MP", match_type, "Meaning partial not matched properly! #{old_meanings[i]} (#{i})")
    end

  end
  
  # Takes a munged JFLash 1.0 definition and tests that it can be partially matched to a JFlash 1.1 meaning
  def no_test_old_munged_meaning_to_new_single_meaning
    migration = setup_class_instance

    old_meanings << "market / fair (noun); city (noun, noun suffix)"
    new_meanings << "market / fair (noun)"
   　# split it on the semicolon and test   
    # match_type, match_data = JFlashMigration.match_meaning_partial(old_meanings[i], new_meanings[i])
  end

  def test_match_partial_first_reading
     migration = setup_class_instance
     old_reading = "ちょう, とばり"
     new_readings = [["ちょう","RP"],["とばり","RO"]]
     new_readings.each do |new_reading, expected|
       result = migration.match_readings(old_reading,new_reading)
       assert_equal(result,expected,"Didn't match properly!!")
     end
  end

  def test_match_munged_meaning
    migration = setup_class_instance
    migration.set_buffered_cards(JFlashMigration.create_buffer_comparision_data({:table => "MERGE_cards_staging_humanised"}))
    pp migration.get_buffered_cards.size
  
    old_meaning = "market / fair (noun); city (noun, noun suffix)"
    old_reading = "いち"
    new_meaning_array = ["market / fair (noun)"]
    new_reading_array = ["いち"]

    # old ID 93836  new IDs = 105423, 105422
    old_meaning = "thing / article / goods / fellow / affair (noun); substitute (noun)"
    old_reading = "しろもの"
    new_meaning_array = ["substitute (noun)","thing / article / goods / fellow / affair (noun)"]
    new_reading_array = ["だいぶつ","しろもの"]
    new_card_ids = ["105423","105422"]

    # old ID = 93176, new ID = 38487, 38488
    old_meaning = "evil thought / malicious motive (noun); nausea / urge to vomit (noun)"
    old_reading = "あくしん"
    new_meaning_array = ["evil thought / malicious motive (noun)","nausea / urge to vomit (noun)"]
    new_reading_array = ["あくしん","おしん"]
    new_card_ids = ["38487","38488"]

    #old ID = 109080, new ID = 97791
    old_meaning = "red  /  crimson  /  scarlet (noun); red-containing colour (e.g. brown, pink, orange); (often written as アカ); red light; (in) the red red ink (i.e. in finance or proof-reading) (noun); complete  /  total  /  perfect  /  obvious (の adj, prefix noun)"
    old_reading = "あか"
    new_meaning_array = ["red / crimson / scarlet (noun); red-containing colour (e.g. brown, pink, orange); Red (i.e. communist) (often written as アカ); red light; red ink (i.e. in finance or proof-reading) / (in) the red; complete / total / perfect / obvious (の adj, prefix noun)"]
    new_reading_array = ["あか"]
    new_card_ids = ["97791"]
    
    #old ID =94976, new ID = 38428,38427
    old_meaning = "nasty smelling air / noxious gas / evil 'ki' (noun); ill will / malice / evil intent / ill feeling / distrust (noun)"
    old_reading = "あっき"    
    new_meaning_array = ["ill will / malice / evil intent / ill feeling / distrust (noun)","nasty smelling air / noxious gas / evil 'ki' (noun)"]
    new_reading_array = ["わるぎ","あっき"]
    new_card_ids = ["38428","38427"]
    
    #OLD ID = 80958, new ID = 48750, 48749
    old_meaning = "to unfasten / to untie / to unwrap  /  (e.g. parcel) (~くverb L5, verb trans.); to solve  /  to answer (解く only) (~くverb L5, verb trans.); to untie (解く only); to comb  /  to untangle (hair)  /  (esp. 梳く)"
    old_reading = "ほどく"    
    new_meaning_array = ["to solve / to answer (~くverb L5, verb trans); to untie; to comb / to untangle (hair) (esp. 梳く)","to unfasten / to untie / to unwrap (e.g. parcel) (~くverb L5, verb trans)"]
    new_reading_array = ["とく","ほどく"]
    new_card_ids = ["38428","38427"]
  end
  
  # Tests the split
  def test_split_munged_meaning
    migration = setup_class_instance

    input =  "market / fair (noun); city (noun, noun suffix)"
    output = ["market / fair (noun)", "city (noun, noun suffix)"]
    assert_equal(output,migration.split_munged_meaning(input),"Could not split input:" + input)

    input = "to unfasten / to untie / to unwrap  /  (e.g. parcel) (~くverb L5, verb trans.); to solve  /  to answer (解く only) (~くverb L5, verb trans.); to untie (解く only); to comb  /  to untangle (hair)  /  (esp. 梳く)"
    output = ["to unfasten / to untie / to unwrap  /  (e.g. parcel) (~くverb L5, verb trans.)","to solve  /  to answer (解く only) (~くverb L5, verb trans.)", "to untie (解く only)","to comb  /  to untangle (hair)  /  (esp. 梳く)"]
    assert_equal(output,migration.split_munged_meaning(input),"Could not split input:" + input)
  end

  def test_get_human_matched_cards
    migration = setup_class_instance
    matches = []
    matched_hash = {}
    matched_hash[:card_id] = "38784"
    matched_hash[:results] = ["HU"]
    matches << matched_hash
    result = migration.get_human_matched_cards("40034")
    assert_equal(matches,result,"WTF??")
  end

  def test_munged_first_meaning_matched
    migration = setup_class_instance
    old =  "11 o'clock; 1100 hours"
    new = "11 o'clock"
    new_matched = "11o'clock"
    result = migration.match_meaning_partial(old,new)
    assert_equal([MATCHED_MEANING_MUNGED_FIRST,new_matched],result,"Could not match input")

    old =  "11 o'clock; 1100 hours"
    new = "1100 hours"
    new_matched = "1100hours"
    result = migration.match_meaning_partial(old,new)
    assert_equal([MATCHED_MEANING_MUNGED,new_matched],result,"Could not match input")
  end

  def no_test_compare_specific
    migration = setup_class_instance

    # Get specific old card
    old_card_ids = JFlashMigration.create_buffer_comparision_data({:table => "MERGE_cards_staging_rel1", :where => "headword = 'βカロチン'"})
    migration.set_buffered_cards(old_card_ids)
    old_card = old_card_ids[:by_card_id].first[1]
    assert_equal("βカロチン", old_card[:headword], "Specic Card Comparison: HW did not match!")

    match_type, match_data = migration.match_readings(old_card[:reading],"ベータカロチン; ベタカロチン")
    assert_equal("RP", match_type, "Specic Card Comparison: Reading did not match!")

    old_meaning = old_card[:meaning].strip
    new_meaning = "beta-carotene (noun)".strip
    assert_equal(old_meaning, new_meaning, "Specic Card Comparison: Meaning did not match!")

  end

end
