require 'test/unit'

class HumanTagImporterTest < Test::Unit::TestCase
  include DatabaseHelpers
  
  def setup
    HumanTagImporter.truncate_exception_tables
  end
  
  def teardown
    HumanTagImporter.truncate_exception_tables
  end
  
  # TESTS
  
  def test_bad_input
    human_tag_importer = HumanTagImporter.new
    assert_raise(RuntimeError) do
      result = human_tag_importer.get_human_result_for_entry("foobar")
    end
  end
    
  # This is a brand-new importer, it shouldn't have any human-matched entries associated
  def test_initialization
    entry = CEdictEntry.new
    entry.parse_line("百 百 [Bai3] /surname Bai/")
    human_tag_importer = HumanTagImporter.new
    result = human_tag_importer.get_human_result_for_entry(entry)
    assert_equal(false,result)
    
    # Now also test that something was added to the database
    result = human_tag_importer.retrieve_exception_entry_from_db(entry)
    assert_equal(result, entry)
  end
  
  # Test that the matcher returns false (no match) when nothing matches, also test that it was flagged for human review
  def test_multiple_match_resolution
    # Create our word list input -- the entry we are trying to match
    fuzzy_entry = HSKEntry.new
    fuzzy_entry.parse_line("18,2-6,百,bai3,hundred; numerous; all kinds of; surname Bai,")
  
    # Create our result inputs -- TagImporter returns these when it doesn't know which to match to
    results = []
    results << CEdictEntry.new.parse_line("百 百 [Bai3] /surname Bai/")
    results << CEdictEntry.new.parse_line("百 百 [bai3] /hundred/numerous/all kinds of/")
    
    human_tag_importer = HumanTagImporter.new
    assert_equal(false, human_tag_importer.get_human_result_for_entry(fuzzy_entry, []))
  end
  
  def test_description_sql_escaped_and_added_options
    # Create our word list input -- the entry we are trying to match
    fuzzy_entry = HSKEntry.new
    fuzzy_entry.parse_line("18,2-6,百,bai3,hundred; num'erous; all ki\"nd's of; surna'me Bai,")
  
    # Create our result inputs -- TagImporter returns these when it doesn't know which to match to
    results = []
    entry = CEdictEntry.new
    entry.parse_line("百 百 [Bai3] /surn\"am'e Bai/")
    results << entry
    entry = CEdictEntry.new
    entry.parse_line("百 百 [bai3] /hundred/nu'merous/a'll k\"\"inds of/")
    results << entry
    
    human_tag_importer = HumanTagImporter.new
    assert_equal(false, human_tag_importer.get_human_result_for_entry(fuzzy_entry, results))
  end

  
  # Test the addition of a human-matched entry -- some web interface would call this
  def test_add_human_resolution
    # Create our word list input -- the entry we are trying to match
    fuzzy_entry = HSKEntry.new
    fuzzy_entry.parse_line("18,2-6,百,bai3,hundred; numerous; all kinds of; surname Bai,")

    matching_entry = CEdictEntry.new
    matching_entry.parse_line("百 百 [bai3] /hundred/numerous/all kinds of/")

    human_tag_importer = HumanTagImporter.new
    assert_equal(false, human_tag_importer.get_human_result_for_entry(fuzzy_entry))
    human_tag_importer.add_match_for_entry(fuzzy_entry, matching_entry)
    assert_equal(matching_entry, human_tag_importer.get_human_result_for_entry(fuzzy_entry))
  end

end