require 'test/unit'

class CEdictParserTest < Test::Unit::TestCase

  # This is a pretty poor test coverage at the moment, but most of the logic is in Entry, not Parser
  # This is more or less testing that it is working at the broad level
  def test_parse
    expected_entries =[]
    results_data = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_cedict.u8").run
    assert_equal(6,results_data.count)
  end

  def test_parse_all
    results_data = CEdictParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/cedict_ts.u8").run
  end

end
