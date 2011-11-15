require 'test/unit'

class CEdictParserTest < Test::Unit::TestCase

  def test_parse
    results_data = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_cedict.u8").run
    # MMA: This is 3 now, not 5, because our parser no longer returns erhua or variant entries with the run method
    assert_equal(3,results_data.count)
  end
  
  # Count should be two less than the number of records because we are removing a variant-only item, plus another variant with definition
  def test_match_variant
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_variant_only.txt")
    entries = parser.run
    assert_equal(13,entries.count)
    assert_equal(1,parser.variant_only_entries.count)
    assert_equal(1,parser.variant_entries.count)
  end

  # Count should be one less than the number of records because we are removing a reference-only item
  def test_match_reference
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_reference.txt")
    entries = parser.run
    assert_equal(6,entries.count)
    assert_equal(1,parser.reference_only_entries.count)
  end
  
  def test_match_reference_merge
    base_entry = CEdictEntry.new
    base_entry.parse_line("味同嚼蠟 味同嚼蜡 [wei4 tong2 jue2 la4] /insipid (like chewing wax)/")
    
    ref_entry = CEdictEntry.new
    ref_entry.parse_line("味同嚼蠟 味同嚼蜡 [wei4 tong2 jiao2 la4] /see 味同嚼蠟|味同嚼蜡[wei4 tong2 jue2 la4]/")
    
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_reference.txt")
    merged_entries = parser.merge_references_into_base_entries([base_entry],[ref_entry])
    
    meaning_one = Meaning.new("insipid (like chewing wax)")
    meaning_two = Meaning.new("Also: 味同嚼蠟|味同嚼蜡[wei4 tong2 jue2 la4]",["reference"])
    
    # The merge should have added the reference entry to the base entry's meaning
    assert_equal(meaning_one,merged_entries[0].meanings[0])
    assert_equal(meaning_two,merged_entries[0].meanings[1])
  end
  
  def test_match_erhua_cross_reference_parse
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_erhua.txt")
    entries = parser.run
    assert_equal(5,entries.count)
    assert_equal(1,parser.erhua_variant_entries.count)
  end

  def test_match_variant_cross_reference_parse
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_variant.txt")
    entries = parser.run
    assert_equal(4,entries.count)
    assert_equal(1,parser.variant_entries.count)
  end

  def test_erhua_cross_reference
    base_entry = CEdictEntry.new
    base_entry.parse_line("哥們 哥们 [ge1 men5] /Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")
    erhua_entry = CEdictEntry.new
    erhua_entry.parse_line("哥們兒 哥们儿 [ge1 men5 r5] /erhua variant of 哥們|哥们, Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")

    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_erhua.txt")
    muxed_base_entries = parser.add_variant_entries_into_base_entries([base_entry], [erhua_entry])
    muxed_erhua_entries = parser.add_base_entries_into_variant_entries([erhua_entry], [base_entry])
    assert_equal(5,muxed_base_entries[0].meanings.count)
    assert_equal(5,muxed_erhua_entries[0].meanings.count)
    
    base_meaning_one = Meaning.new("brother (diminutive form of address between males)")
    base_meaning_two = Meaning.new("Has Erhua variant: 哥們兒 哥们儿 [ge1 men5 r5]",["reference"])
    assert_equal(base_meaning_one,muxed_base_entries[0].meanings[3])
    assert_equal(base_meaning_two,muxed_base_entries[0].meanings[4])

    erhua_meaning_one = Meaning.new("brother (diminutive form of address between males)")
    erhua_meaning_two = Meaning.new("Erhua variant of: 哥們 哥们 [ge1 men5]",["reference"])
    assert_equal(erhua_meaning_one,muxed_erhua_entries[0].meanings[3])
    assert_equal(erhua_meaning_two,muxed_erhua_entries[0].meanings[4])
  end

  def test_variant_cross_reference
    base_entry = CEdictEntry.new
    base_entry.parse_line("念 念 [nian4] /to read/to study (a degree course)/to read aloud/to miss (sb)/idea/remembrance/twenty (banker's anti-fraud numeral corresponding to 廿, 20)/")
    variant_entry = CEdictEntry.new
    variant_entry.parse_line("唸 唸 [nian4] /variant of 念, to read aloud/")

    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_variant.txt")
    muxed_base_entries = parser.add_variant_entries_into_base_entries([base_entry], [variant_entry])
    muxed_variant_entries = parser.add_base_entries_into_variant_entries([variant_entry], [base_entry])
    assert_equal(8,muxed_base_entries[0].meanings.count)
    assert_equal(2,muxed_variant_entries[0].meanings.count)
    
    base_meaning_one = Meaning.new("twenty (banker's anti-fraud numeral corresponding to 廿, 20)")
    base_meaning_two = Meaning.new("Has variant: 唸 唸 [nian4]",["reference"])
    assert_equal(base_meaning_one,muxed_base_entries[0].meanings[6])
    assert_equal(base_meaning_two,muxed_base_entries[0].meanings[7])

    variant_meaning_one = Meaning.new("to read aloud")
    variant_meaning_two = Meaning.new("Variant of: 念 念 [nian4]",["reference"])
    assert_equal(variant_meaning_one,muxed_variant_entries[0].meanings[0])
    assert_equal(variant_meaning_two,muxed_variant_entries[0].meanings[1])
  end
  
  def test_classifier_expansion
    results_data = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_cedict.u8").run
    entry = results_data[1]
    
    expected_meanings = [Meaning.new("video camera"),Meaning.new("Counter: 部[bu4]",["classifier"])]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  def test_multiple_classifier_expansion
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_multiple_classifiers.txt")
    entries = parser.run
    
    expected_meanings = [Meaning.new("store"),Meaning.new("shop"),Meaning.new("Counter: 家[jia1]",["classifier"]),Meaning.new("Counter: 個|个[ge4]",["classifier"])]
    assert_equal(expected_meanings,entries[1].meanings)
  end

end
