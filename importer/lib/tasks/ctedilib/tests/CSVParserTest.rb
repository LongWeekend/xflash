require 'test/unit'

class CSVParserTest < Test::Unit::TestCase

  # This is a pretty poor test coverage at the moment, but most of the logic is in Entry, not Parser
  # This is more or less testing that it is working at the broad level
  def test_parse
    expected_entries =[]
    results_data = CSVParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/800.txt").run
    assert_equal(4,results_data.count)
  end

end
