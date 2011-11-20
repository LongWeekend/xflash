require 'test/unit'

class HSKEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = CSVEntry.new
    assert_equal(false, entry.parse_line(nil))
  end

  # Tests that basic headword and reading can be parsed

  def test_parse_headword_and_reading
    entry = HSKEntry.new
    entry.parse_line('3,4,爸爸,ba4 ba5,"(informal) father; CL:個|个[ge4],位[wei4]"')
    assert_equal("爸爸",entry.headword_simp)
    assert_equal("ba4 ba5",entry.pinyin)
    assert_equal("4",entry.grade)
  end

  def test_parse_meaning
    entry = HSKEntry.new
    entry.parse_line('3,1,爸爸,ba4 ba5,"(informal) father; CL:個|个[ge4],位[wei4]"')
    expected_meanings = ["(informal) father","CL:個|个[ge4],位[wei4]"]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  def test_parse_level
    entry = HSKEntry.new
    entry.parse_line('1,3,"阿姨","a1 yi2","maternal aunt; step-mother; childcare worker; nursemaid; woman of similar age to ones parents (term of address used by child); CL:個|个[ge4]"')
    assert_equal("3",entry.grade)
  end
  
end