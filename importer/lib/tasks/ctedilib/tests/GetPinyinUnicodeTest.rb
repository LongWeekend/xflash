require 'test/unit'

class GetPinyinUnicodeTest < Test::Unit::TestCase

  def test_pinyin_1
    reading = get_pinyin_unicode_for_reading("da1 pei4")
    expected_reading = "dāpèi"
    assert_equal(expected_reading,reading)
  end

  def test_pinyin_2
    reading = get_pinyin_unicode_for_reading("e2 wai4")
    expected_reading = "éwài"
    assert_equal(expected_reading,reading)
  end

  def test_pinyin_3
    reading = get_pinyin_unicode_for_reading("gai3 bian1")
    expected_reading = "gǎibiān"
    assert_equal(expected_reading,reading)
  end  
  
  def test_pinyin_4
    reading = get_pinyin_unicode_for_reading("ai4 dai4")
    expected_reading = "àidài"
    assert_equal(expected_reading,reading)
  end
  
  def test_fix_tone_3
    pinyin = fix_unicode_for_tone_3("ăĕĭŏŭ")
    expected_pinyin = "ǎěǐǒǔ"
    assert_equal(expected_pinyin,pinyin)
  end
  
  def test_pinyin_similarities_1
    reading = "ài dai5"
    pinyin = "àidāi"
    result = pinyin.is_similar_pinyin?(reading)
    assert_equal(result, true)
  end
  
  def test_pinyin_unicode
    reading = get_pinyin_unicode_for_reading("a5 i5 u5 e5 o5")
    expected_pinyin = "aiueo"
    assert_equal(reading, expected_pinyin)
   end
  
end
