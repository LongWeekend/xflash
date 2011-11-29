require 'test/unit'

class BigramEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = BigramEntry.new
    assert_equal(false, entry.parse_line(nil))
  end
  
  def test_throw_exception
    entry = BigramEntry.new
    assert_raise(EntryParseException) do
      entry.parse_line("8	工作	18904	6.89133239246213454")
    end
  end

  def test_ignore_comment
    entry = BigramEntry.new
    assert_equal(false, entry.parse_line("/* 序列号	双字组	频率	相互信息分值*/"))
  end

  # Tests that basic headword can be parsed

  def test_parse_headword
    entry = BigramEntry.new
    entry.parse_line("8	工作	18904	6.89133239246	213454")
    assert_equal("",entry.headword_trad)
    assert_equal("工作",entry.headword_simp)
  end

end