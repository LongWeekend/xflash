require 'test/unit'

class EntryTest < Test::Unit::TestCase

  # This should work for all entries
  def test_check_pos_tag
    assert_equal(true,Entry.is_pos_tag?("VS"))
    assert_equal(false,Entry.is_pos_tag?("foobar"))
  end
  
  def test_inline_parse_null
    result = Entry.parse_inline_entry("")
    assert_equal(nil,result)
  end
  
  def test_inline_parse_not_null
    result = Entry.parse_inline_entry("方")
    assert_equal(result.headword_trad,"方")
  end

  def test_update_sql
    entry = Entry.new
    entry.id = 1
    cedict_hash = mysql_serialise_ruby_object(entry)
    expected = "UPDATE cards_staging SET headword_trad = '',headword_simp = '',headword_en = '',reading = '',reading_diacritic = '',meaning = '',meaning_html = '',meaning_fts = '',classifier = NULL,entry_tags = '',referenced_cards = NULL,is_reference_only = 0,is_variant = 0,is_erhua_variant = 0,is_proper_noun = 0,variant = NULL,priority_word = 0, cedict_hash = '%s' WHERE card_id = 1;" % cedict_hash
    assert_equal(expected,entry.to_update_sql)
  end
  
  def test_update_sql_fail
    entry = Entry.new
    assert_equal(false, entry.to_update_sql)
  end

#========================
# PINYIN CONVERSION TESTS
#========================

  def test_pinyin_bad_pinyin_input
    assert_raise(ToneParseException) do
      reading = Entry.get_pinyin_unicode_for_reading("f1 off4")
    end
  end
  
  def test_pinyin_no_input
    reading = Entry.get_pinyin_unicode_for_reading("")
    assert_equal("",reading)
  end

  def test_pinyin_spacing
    reading = Entry.get_pinyin_unicode_for_reading("da1 pei4", true)
    expected_reading = "dā pèi"
    assert_equal(expected_reading,reading)
  end

  def test_pinyin_1
    reading = Entry.get_pinyin_unicode_for_reading("da1 pei4")
    expected_reading = "dāpèi"
    assert_equal(expected_reading,reading)
  end

  def test_pinyin_2
    reading = Entry.get_pinyin_unicode_for_reading("e2 wai4")
    expected_reading = "éwài"
    assert_equal(expected_reading,reading)
  end

  def test_pinyin_3
    reading = Entry.get_pinyin_unicode_for_reading("gai3 bian1")
    expected_reading = "gǎibiān"
    assert_equal(expected_reading,reading)
  end  
  
  def test_pinyin_4
    reading = Entry.get_pinyin_unicode_for_reading("ai4 dai4")
    expected_reading = "àidài"
    assert_equal(expected_reading,reading)
  end
  
  def test_maintain_caps
    reading = Entry.get_pinyin_unicode_for_reading("Bai4")
    expected_reading = "Bài"
    assert_equal(expected_reading,reading)
  end
  
  def test_pinyin_single_letter
    reading = Entry.get_pinyin_unicode_for_reading("ka3 la1 O K")
    expected_reading = "kǎlāOK"
    assert_equal(expected_reading,reading)
    
    reading = Entry.get_pinyin_unicode_for_reading("D N A jian4 ding4")
    expected_reading = "DNAjiàndìng"
    assert_equal(expected_reading,reading)
    
    reading = Entry.get_pinyin_unicode_for_reading("U S B ji4 yi4 bang4")
    expected_reading = "USBjìyìbàng"
    assert_equal(expected_reading,reading)
    
    reading = Entry.get_pinyin_unicode_for_reading("G dian3")
    expected_reading = "Gdiǎn"
    assert_equal(expected_reading,reading)
    
    reading = Entry.get_pinyin_unicode_for_reading("T xu4")
    expected_reading = "Txù"
    assert_equal(expected_reading,reading)
    
    reading = Entry.get_pinyin_unicode_for_reading("n xu4")
    expected_reading = "nxù"
    assert_equal(expected_reading,reading)
  end
  
  def test_u_umlaut
    pinyin = Entry.get_pinyin_unicode_for_reading("qi1 lu:4")
    expected_pinyin = "qīlǜ"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = Entry.get_pinyin_unicode_for_reading("qi1 lv4")
    expected_pinyin = "qīlǜ"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = Entry.get_pinyin_unicode_for_reading("San1 Lu:e4")
    expected_pinyin = "SānLüè"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = Entry.get_pinyin_unicode_for_reading("shi4 lu:e4")
    expected_pinyin = "shìlüè"
    assert_equal(expected_pinyin,pinyin)
    
    pinyin = Entry.get_pinyin_unicode_for_reading("U:5")
    expected_pinyin = "ü"
    assert_equal(expected_pinyin,pinyin)

    pinyin = Entry.get_pinyin_unicode_for_reading("lu:4 se4 tong1 dao4")
    expected_pinyin = "lǜsètōngdào"
    assert_equal(expected_pinyin,pinyin)
    
    # Gonna fail as the capital 'V' cannot be used as
    # the u umlaut symbol
    #pinyin = Entry.get_pinyin_unicode_for_reading("V5")
    #expected_pinyin = "ü"
    #assert_equal(expected_pinyin,pinyin)

    # fail
    pinyin = Entry.get_pinyin_unicode_for_reading("shi4 lu:3e4")
    expected_pinyin = "shìlü3è"
    assert_equal(expected_pinyin,pinyin)
  end
  
  def test_fix_tone_3
    pinyin = Entry.fix_unicode_for_tone_3("ăĕĭŏŭ")
    expected_pinyin = "ǎěǐǒǔ"
    assert_equal(expected_pinyin,pinyin)
  end
  
  def test_pinyin_unicode
    reading = Entry.get_pinyin_unicode_for_reading("a5 i5 u5 e5 o5 u:5 v5")
    expected_pinyin = "aiueoüü"
    assert_equal(reading, expected_pinyin)
  end
  

end