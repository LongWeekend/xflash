require 'test/unit'

class CEdictParserTest < Test::Unit::TestCase

  # This is a pretty poor test coverage at the moment, but most of the logic is in Entry, not Parser
  # This is more or less testing that it is working at the broad level
  def test_parse
    results_data = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_cedict.u8").run
    assert_equal(5,results_data.count)
  end
  
  # Count should be one less than the number of records because we are removing a variant-only item
  def test_match_variant
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/cedict_parser_match_variant_only.txt")
    entries = parser.run
    assert_equal(14,entries.count)
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

end
