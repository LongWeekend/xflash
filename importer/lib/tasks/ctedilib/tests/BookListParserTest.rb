require 'test/unit'

class BookListParserTest < Test::Unit::TestCase

  # This is a pretty poor test coverage at the moment, but most of the logic is in Entry, not Parser
  # This is more or less testing that it is working at the broad level
  def test_parse_beg_chinese
    expected_entries =[]
    results_data = WordListParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/beg_chinese.txt").run('BookEntry')
    assert_equal(3,results_data.count)
  end

  def test_parse_colloquial_chinese
    expected_entries =[]
    results_data = WordListParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/coll_chinese.txt").run('BookEntry')
    assert_equal(3,results_data.count)
  end

  def test_parse_integrated_chinese
    expected_entries =[]
    results_data = WordListParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/integrated_chinese.txt").run('BookEntry')
    assert_equal(10,results_data.count)
  end

  def test_parse_schaums
    expected_entries =[]
    results_data = WordListParser.new(File.dirname(__FILE__) + "/../../../../data/cedict/test_data/schaums.txt").run('BookEntry')
    assert_equal(7,results_data.count)
  end
end
