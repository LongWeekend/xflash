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
  
  def test_pinyin_single_letter
    reading = get_pinyin_unicode_for_reading("ka3 la1 O K")
    expected_reading = "kǎlāOK"
    assert_equal(expected_reading,reading)
    
    reading = get_pinyin_unicode_for_reading("D N A jian4 ding4")
    expected_reading = "DNAjiàndìng"
    assert_equal(expected_reading,reading)
    
    reading = get_pinyin_unicode_for_reading("U S B ji4 yi4 bang4")
    expected_reading = "USBjìyìbàng"
    assert_equal(expected_reading,reading)
    
    reading = get_pinyin_unicode_for_reading("G dian3")
    expected_reading = "Gdiǎn"
    assert_equal(expected_reading,reading)
    
    reading = get_pinyin_unicode_for_reading("T xu4")
    expected_reading = "Txù"
    assert_equal(expected_reading,reading)
  end
  
  def test_u_umlaut
    pinyin = get_pinyin_unicode_for_reading("qi1 lu:4")
    expected_pinyin = "qīlǜ"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = get_pinyin_unicode_for_reading("qi1 lv4")
    expected_pinyin = "qīlǜ"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = get_pinyin_unicode_for_reading("San1 Lu:e4")
    expected_pinyin = "sānlüè"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = get_pinyin_unicode_for_reading("shi4 lu:e4")
    expected_pinyin = "shìlüè"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = get_pinyin_unicode_for_reading("U:5")
    expected_pinyin = "ü"
    assert_equal(expected_pinyin,pinyin)

    pinyin = get_pinyin_unicode_for_reading("lu:4 se4 tong1 dao4")
    expected_pinyin = "lǜsètōngdào"
    assert_equal(expected_pinyin,pinyin)
    
    # Gonna fail as the capital 'V' cannot be used as
    # the u umlaut symbol
    #pinyin = get_pinyin_unicode_for_reading("V5")
    #expected_pinyin = "ü"
    #assert_equal(expected_pinyin,pinyin)

    # fail
    pinyin = get_pinyin_unicode_for_reading("shi4 lu:3e4")
    expected_pinyin = "shìlü3è"
    assert_equal(expected_pinyin,pinyin)
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
    reading = get_pinyin_unicode_for_reading("a5 i5 u5 e5 o5 u:5 v5")
    expected_pinyin = "aiueoüü"
    assert_equal(reading, expected_pinyin)
  end
  
end