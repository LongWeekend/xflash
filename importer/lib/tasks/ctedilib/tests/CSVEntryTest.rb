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

  def test_throw_exception
    entry = CSVEntry.new
    assert_raise(EntryParseException) do
      entry.parse_line('1463,"1463","看看","kànkan","I",,')
    end
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
  
  def test_optional_headword
    entry = CSVEntry.new
    entry.parse_line('58,"1352","鼻(子)","bí(zi) ","B","(N)","nose"')
    expected_meanings = [Meaning.new("nose")]
    assert_equal(expected_meanings, entry.meanings)
    
    assert_equal("鼻子",entry.headword_trad)
    assert_equal("bízi",entry.pinyin_diacritic)
  end
  
  def test_alternate_character
    entry = CSVEntry.new
    entry.parse_line('1344,"0003","一下子/兒","yíxiàzi/ér ","B","(N)","in a short while"')
    expected_meanings = [Meaning.new("in a short while")]
    assert_equal(expected_meanings, entry.meanings)
    
    assert_equal("一下子",entry.headword_trad)
    assert_equal("yíxiàzi",entry.pinyin_diacritic)
  end
  
  def test_meaning_separated_hw
    entry = CSVEntry.new
    entry.parse_line('568,"0276","叫1","jiào ","B","(VA)","to ask"')
    expected_meanings = [Meaning.new("to ask")]
    assert_equal(expected_meanings, entry.meanings)
    
    assert_equal("叫",entry.headword_trad)
    assert_equal("jiào",entry.pinyin_diacritic)
  end

end