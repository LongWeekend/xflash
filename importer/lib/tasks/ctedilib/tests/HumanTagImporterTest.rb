require 'test/unit'

class HumanTagImporterTest < Test::Unit::TestCase
  include DatabaseHelpers
  
  # This is a brand-new importer, it shouldn't have any human-matched entries associated
  def test_initialization
    human_tag_importer = HumanTagImporter.new
    assert_equal(0,human_tag_importer.human_matched_entries.count)
    assert_equal(0,human_tag_importer.entries_for_human_review.count)
  end
  
  # Test that the matcher returns false (no match) when nothing matches, also test that it was flagged for human review
  def test_multiple_match_resolution
    # Create our word list input -- the entry we are trying to match
    fuzzy_entry = CSVEntry.new
    fuzzy_entry.parse_line("")
  
    # Create our result inputs -- TagImporter returns these when it doesn't know which to match to
    results = []
    results << CEdictEntry.new.parse_line("")
    results << CEdictEntry.new.parse_line("")
    results << CEdictEntry.new.parse_line("")
    
    human_tag_importer = HumanTagImporter.new
    assert_equal(false, human_tag_importer.get_human_result_for_entry(fuzzy_entry))
    
    # There should be 1 in the queue now
    assert_equal(1,human_tag_importer.entries_for_human_review.count)
  end
  
  # Test the addition of a human-matched entry -- some web interface would call this
  def test_add_human_resolution
    # Create our word list input -- the entry we are trying to match
    fuzzy_entry = CSVEntry.new
    fuzzy_entry.parse_line("")

    matching_entry = CEdictEntry.new
    matching_entry.parse_line("")

    human_tag_importer = HumanTagImporter.new
    human_tag_importer.add_match_for_entry(fuzzy_entry, matching_entry)
    
    assert_equal(1,human_tag_importer.human_matched_entries.count)
    assert_equal(matching_entry, human_tag_importer.get_human_result_for_entry(fuzzy_entry))
  end

end