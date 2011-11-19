require 'test/unit'

class CSVEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = CSVEntry.new
    entry.init
    entry.parse_line(nil)
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
  end
  
  def test_parse_meaning
    entry = CSVEntry.new
    entry.parse_line("2,\"2119\",\"愛戴\",\"àidài \",\"A\",\"(VS)\",\"love and respect\"")
    expected_meanings = ["love and respect"]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  def test_parse_meaning_multiple
    entry = CSVEntry.new
    entry.parse_line('1,"1387","挨","āi ","A","(VS)","get close to,be next to,follow in sequence or along designated route/direction"')
    expected_meanings = ["get close to","be next to","follow in sequence or along designated route/direction"]
    assert_equal(expected_meanings,entry.meanings)
  end

end