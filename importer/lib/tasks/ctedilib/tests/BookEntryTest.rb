require 'test/unit'

class BookEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = BookEntry.new
    assert_equal(false, entry.parse_line(nil))
  end

  # Tests that basic headword and reading can be parsed

  def test_parse_headword_and_reading
    entry = BookEntry.new
    entry.parse_line("再	再	zai4	/again/")
    assert_equal("再",entry.headword_trad)
    assert_equal("再",entry.headword_simp)
    assert_equal("zai4",entry.pinyin)
    assert_equal("再	再	zai4	/again/",entry.original_line)
  end
  
  def test_description
    entry = BookEntry.new
    entry.parse_line("再	再	zai4	/again/")
    assert_equal("再 再 [zai4], again",entry.description)
  end

  def test_parse_meaning
    entry = BookEntry.new
    entry.parse_line("市區地圖	市区地图	shi4 qu1 di4 tu2	/city map/foobar/")
    expected_meanings = [Meaning.new("city map"),Meaning.new("foobar")]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  def test_parse_pinyin
    entry = BookEntry.new
    entry.parse_line("綠色通道	绿色通道	lu:4 se4 tong1 dao4	/green channel/")
    expected_pinyin = "lü4 se4 tong1 dao4"
    assert_equal(expected_pinyin,entry.pinyin)
  end

end