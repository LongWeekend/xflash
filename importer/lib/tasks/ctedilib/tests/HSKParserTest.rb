require 'test/unit'

class HSKParserTest < Test::Unit::TestCase

  # This is a pretty poor test coverage at the moment, but most of the logic is in Entry, not Parser
  # This is more or less testing that it is working at the broad level
  def test_parse_version1
    expected_entries =[]
    results_data = HSKParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/hsk.txt").run
    assert_equal(8,results_data.count)
  end
end
