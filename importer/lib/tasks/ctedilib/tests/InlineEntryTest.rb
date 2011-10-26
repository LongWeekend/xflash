require 'test/unit'

class InlineEntryTest < Test::Unit::TestCase

  def test_normal_ref
    entry = InlineEntry.new
    entry.parse_line("龜|龟[gui1]")
    assert_equal("龜",entry.headword_trad)
    assert_equal("龟",entry.headword_simp)
    assert_equal("gui1",entry.pinyin)
  end

  def test_headword_trad_single
    entry = InlineEntry.new
    entry.parse_line("齰")
    assert_equal("齰",entry.headword_trad)
    assert_equal(nil,entry.headword_simp)
  end
  
  def test_headword_no_reading
    entry = InlineEntry.new
    entry.parse_line("鬱|郁")
    assert_equal("鬱",entry.headword_trad)
    assert_equal("郁",entry.headword_simp)
  end
  
  def test_no_simplified_with_reading
    entry = InlineEntry.new
    entry.parse_line("令狐[Ling2 hu2]")
    assert_equal("令狐",entry.headword_trad)
    assert_equal(nil,entry.headword_simp)
    assert_equal("Ling2 hu2",entry.pinyin)
  end
  
  def test_random_meaning
    entry = InlineEntry.new
    entry.parse_line("魑 mountain demon")
    assert_equal("魑",entry.headword_trad)
    assert_equal(nil,entry.headword_simp)
  end

end
