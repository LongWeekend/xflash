require 'test/unit'

class BookEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = BookEntry.new
    entry.init
    entry.parse_line(nil)
  end

  # Tests that basic headword and reading can be parsed

  def test_parse_headword_and_reading
    entry = BookEntry.new
    entry.parse_line("再	再	zai4	/again/")
    assert_equal("再",entry.headword_trad)
    assert_equal("再",entry.headword_simp)
    assert_equal("zai4",entry.pinyin)
  end

  def test_parse_meaning
    entry = BookEntry.new
    entry.parse_line("市區地圖	市区地图	shi4 qu1 di4 tu2	/city map/foobar/")
    expected_meanings = ["city map","foobar"]
    assert_equal(expected_meanings,entry.meanings)
  end

end