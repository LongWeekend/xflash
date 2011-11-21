require 'test/unit'

class CSVEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = CSVEntry.new
    entry.parse_line(nil)
  end

  def test_heading_detector
    entry = CSVEntry.new
    result = entry.parse_line('"Z",,,,,,')
    assert_equal(false, result)
  end

  # Tests that basic headword and reading can be parsed

  def test_parse_headword_and_reading
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    assert_equal("愛戴",entry.headword_trad)
    assert_equal("",entry.headword_simp)
    assert_equal(["VS"],entry.pos)
    assert_equal("àidài",entry.pinyin_diacritic)
    assert_equal("",entry.pinyin)
    assert_equal("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"",entry.original_line)
  end
  
  # Description uses inlining tags, so the VS gets put in to the meaning
  def test_description
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    assert_equal("愛戴  [àidài], love and respect (VS)",entry.description)
  end
  
  def test_parse_meaning
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    expected_meanings = [Meaning.new("love and respect")]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  def test_parse_meaning_multiple
    entry = CSVEntry.new
    entry.parse_line('1,"1387","挨","āi ","A","(VS)","get close to,be next to,follow in sequence or along designated route/direction"')
    expected_meanings = [Meaning.new("get close to"),Meaning.new("be next to"),Meaning.new("follow in sequence or along designated route/direction")]
    assert_equal(expected_meanings,entry.meanings)
  end

end