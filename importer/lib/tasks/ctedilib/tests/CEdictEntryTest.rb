require 'test/unit'

class CEdictEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = CEdictEntry.new
    entry.parse_line(nil)
  end
  
  def test_comment
    entry = CEdictEntry.new
    entry.parse_line("# foobar")
  end
  
  # Test exception thrown if data input is bad
  def test_bad_input_exception
    entry = CEdictEntry.new
    assert_raise(EntryParseException) do
      entry.parse_line("播放機 播放机 [bo1 fang4 ji1 /erhua variant of 旁邊|旁边, lateral")
    end
  end
  
  def test_description
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/")
    assert_equal("播放機 播放机 [bo1 fang4 ji1], player (e.g. CD player)",entry.description)
  end

  # Tests that basic headword and reading can be parsed
  def test_parse_headword_and_reading
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/")
    assert_equal("播放機",entry.headword_trad)
    assert_equal("播放机",entry.headword_simp)
    assert_equal("bo1 fang4 ji1",entry.pinyin)
    assert_equal("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/",entry.original_line)
  end

  def test_parse_single_meaning
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/")
    
    expected_meaning = Meaning.new("player (e.g. CD player)",[])
    assert_equal([ expected_meaning ],entry.meanings)
  end
#堆壘數論 堆垒数论 [dui1 lei3 shu4 lun4] /additive number theory (math.)/

  # Test our ability to break out meanings and extract tags from each  
  def test_parse_multi_meaning
    entry = CEdictEntry.new
    entry.parse_line("方 方 [fang1] /square/power or involution (mathematics)/upright/honest/fair and square/direction/side/party (to a contract, dispute etc)/place/method/prescription (medicine)/upright or honest/just when/only or just/classifier for square things/abbr. for square or cubic meter/ \r\n")
    expected_meanings = [Meaning.new("square"),Meaning.new("power or involution",["mathematics"]),
            Meaning.new("upright"), Meaning.new("honest"), Meaning.new("fair and square"),
            Meaning.new("direction"), Meaning.new("side"), Meaning.new("party (to a contract, dispute etc)"),
            Meaning.new("place"),Meaning.new("method"), Meaning.new("prescription",["medicine"]),
            Meaning.new("upright or honest"), Meaning.new("just when"), Meaning.new("only or just"),
            Meaning.new("classifier for square things"), Meaning.new("abbr. for square or cubic meter",["abbr"])]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Test our ability to break out meanings and extract tags from each  
  def test_parse_multi_meaning_replacements
    entry = CEdictEntry.new
    entry.parse_line("方 方 [fang1] /square/power or involution (math.)/upright/honest/fair and square/direction/side/party (to a contract, dispute etc)/place/method/prescription (med.)/upright or honest/just when/only or just/classifier for square things/abbr. for square or cubic meter/ \r\n")
    expected_meanings = [Meaning.new("square"),Meaning.new("power or involution",["mathematics"]),
            Meaning.new("upright"), Meaning.new("honest"), Meaning.new("fair and square"),
            Meaning.new("direction"), Meaning.new("side"), Meaning.new("party (to a contract, dispute etc)"),
            Meaning.new("place"),Meaning.new("method"), Meaning.new("prescription",["medicine"]),
            Meaning.new("upright or honest"), Meaning.new("just when"), Meaning.new("only or just"),
            Meaning.new("classifier for square things"), Meaning.new("abbr. for square or cubic meter",["abbr"])]
    assert_equal(expected_meanings,entry.meanings)
  end

  # Test erhua parsing
  def test_get_erhua_variant
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /erhua variant of 旁邊|旁边, lateral")
    assert_equal(true,entry.is_erhua_variant?)
  end

  # Test ability to extract classifier  
  def test_parse_classifier
    entry = CEdictEntry.new
    entry.parse_line("攝像機 摄像机 [she4 xiang4 ji1] /video camera/CL:部[bu4]/")
    expected_meanings = [Meaning.new("video camera")]
    assert_equal("部[bu4]",entry.classifier)
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Extract variants - no pinyin
  def test_parse_variant_no_pinyin
    entry = CEdictEntry.new
    entry.parse_line("斾 斾 [pei4] /variant of 旆, pennant/banner/")
    expected_meanings = [Meaning.new("pennant"),Meaning.new("banner")]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(false,entry.is_erhua_variant?)
    assert_equal("旆",entry.variant_of)
  end
  
  # Extract variants with pinyin
  def test_parse_variant_pinyin
    entry = CEdictEntry.new
    entry.parse_line("旄 旄 [mao4] /variant of 耄[mao4]/")
    expected_meanings = []
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(false,entry.is_erhua_variant?)
    assert_equal("耄[mao4]",entry.variant_of)
  end
  
  # Extract variants - erhua
  def test_parse_erhua_variant
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side/to the side/beside/")
    expected_meanings = [Meaning.new("lateral"),Meaning.new("side"),
                         Meaning.new("to the side"),Meaning.new("beside")]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(true,entry.is_erhua_variant?)
    assert_equal("旁邊|旁边",entry.variant_of)
  end
  
  def test_parse_archaic_variant
  
    # FIRST, "Archaic"
    entry = CEdictEntry.new
    entry.parse_line("㐅 㐅 [wu3] /archaic variant of 五[wu3]/")
    
    # This is only a variant, there is no meaning
    expected_meanings = []
    assert_equal(expected_meanings,entry.meanings)
    
    assert_equal(true,entry.has_variant?)
    assert_equal("五[wu3]",entry.variant_of)
    assert_equal(false,entry.is_erhua_variant?)
    assert_equal(true,entry.is_only_redirect?)


    # SECOND, "old"
    entry = CEdictEntry.new
    entry.parse_line("㬎 㬎 [xian3] /old variant of 顯|显[xian3]/visible/apparent/")
    
    # This is only a variant, there is no meaning
    expected_meanings = [Meaning.new("visible"),Meaning.new("apparent")]
    assert_equal(expected_meanings,entry.meanings)
    
    assert_equal(true,entry.has_variant?)
    assert_equal("顯|显[xian3]",entry.variant_of)
    assert_equal(false,entry.is_erhua_variant?)
    assert_equal(false,entry.is_only_redirect?)
  end
  
  def test_partial_tag_matches
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side (Japanese)/to the side (Budd.)/beside (Buddhist)/")
    
    expected_meanings = [Meaning.new("lateral"), Meaning.new("side (Japanese)",["japanese"]),
                         Meaning.new("to the side (Budd.)",["buddhism"]),
                         Meaning.new("beside (Buddhist)",["buddhism"])]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(true,entry.is_erhua_variant?)
    assert_equal("旁邊|旁边",entry.variant_of)
  end
  
  # The first generation of the parser didn't support multiple parentheticals
  def test_multiple_parentheticals
    entry = CEdictEntry.new
    entry.parse_line("黑客 黑客 [hei1 ke4] /hacker (computing) (loanword)/");
  end
  
  # If the meaning starts with "surname", tag it as a surname
  def test_surname_autotag
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /surname Makdad/foobar/")
    expected_meanings = [Meaning.new("surname Makdad",["surname"]),
                         Meaning.new("foobar")]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Test "redirect" detection
  def test_see_redirect
    entry = CEdictEntry.new
    entry.parse_line("旮 旮 [ga1] /see 旮旯[ga1 la2]/")
    assert_equal(true,entry.is_only_redirect?)
  end
  
  def test_see_also_redirect_reference
    entry = CEdictEntry.new
    entry.parse_line("人字拖鞋 人字拖鞋 [ren2 zi4 tuo1 xie2] /flip flops/flip-flop sandals/thongs/see also 人字拖/")
    assert_equal(false,entry.is_only_redirect?)
    expected_references = ["人字拖"]
    assert_equal(expected_references,entry.references)
  end

  def test_multiple_references
    entry = CEdictEntry.new
    entry.parse_line("令 令 [ling2] /see 脊令[ji2 ling2]/see 令狐[Ling2 hu2]/")
    assert_equal(true,entry.is_only_redirect?)
    expected_references = ["脊令[ji2 ling2]","令狐[Ling2 hu2]"]
    assert_equal(expected_references,entry.references)
  end
  
  # Test detection of "see also" type meanings
  def test_references
    entry = CEdictEntry.new
    entry.parse_line("昏睡病 昏睡病 [hun1 shui4 bing4] /sleeping sickness/African trypanosomiasis/see also 非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]/")
    assert_equal(false,entry.is_only_redirect?)
    
    expected_references = ["非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]"]
    assert_equal(expected_references,entry.references)
  end
  
  def test_meaning_html
    entry = CEdictEntry.new
    entry.parse_line("明天見 明天见 [ming2 tian1 jian4] /see you tomorrow/")
    expected = "see you tomorrow"
    assert_equal(expected,entry.meaning_html("inhuman"))
  end

  def test_meaning_html_multiple
    entry = CEdictEntry.new
    entry.parse_line("人字拖鞋 人字拖鞋 [ren2 zi4 tuo1 xie2] /flip flops/flip-flop sandals/thongs/see also 人字拖/")
    expected = "<ol><li>flip flops</li><li>flip-flop sandals</li><li>thongs</li></ol>"
    assert_equal(expected,entry.meaning_html("inhuman"))
  end
  
  def test_meaning_txt
    entry = CEdictEntry.new
    entry.parse_line("明天見 明天见 [ming2 tian1 jian4] /see you tomorrow/")
    expected = "see you tomorrow"
    assert_equal(expected,entry.meaning_txt("inhuman"))
  end
  
  def test_meaning_fts
    entry = CEdictEntry.new
    entry.parse_line("明天見 明天见 [ming2 tian1 jian4] /see you tomorrow/")
    expected = "see you tomorrow"
    assert_equal(expected,entry.meaning_fts("inhuman"))
  end
  
  def test_meaning_fts_stopwords
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side/to the side/beside/CL:foobar/")
    expected = "lateral side beside"
    assert_equal(expected,entry.meaning_fts("inhuman"))
  end
  
  def test_to_insert_sql
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side/to the side/beside/")
    cedict_hash = mysql_serialise_ruby_object(entry)
    expected = "INSERT INTO cards_staging (headword_trad,headword_simp,headword_en,reading,reading_diacritic,meaning,meaning_html,meaning_fts,classifier,tags,referenced_cards,is_reference_only,is_variant,is_erhua_variant,is_proper_noun,variant,cedict_hash) VALUES ('旁邊兒','旁边儿','lateral','pang2 bian1 r5','páng biān r','lateral; side; to the side; beside','<ol><li>lateral</li><li>side</li><li>to the side</li><li>beside</li></ol>','lateral side beside',NULL,'',NULL,0,1,1,0,'旁邊|旁边','%s');" % cedict_hash
    assert_equal(expected,entry.to_insert_sql)
  end
  
  def test_inline_match
    base_entry = CEdictEntry.new
    base_entry.parse_line("味同嚼蠟 味同嚼蜡 [wei4 tong2 jue2 la4] /insipid (like chewing wax)/")
    
    # Headword mismatch
    inline_entry = Entry.parse_inline_entry("人字拖|人字拖[wei4 tong2 jue2 la4]")
    assert_equal(false,base_entry.inline_entry_match?(inline_entry))

    # Pinyin+headword match
    inline_entry = Entry.parse_inline_entry("味同嚼蠟|味同嚼蜡[wei4 tong2 jue2 la4]")
    assert_equal(true,base_entry.inline_entry_match?(inline_entry))
    
    # Headword only match (both)
    inline_entry = Entry.parse_inline_entry("味同嚼蠟|味同嚼蜡")
    assert_equal(true,base_entry.inline_entry_match?(inline_entry))
    
    # Headword only match
    inline_entry = Entry.parse_inline_entry("味同嚼蠟")
    assert_equal(true,base_entry.inline_entry_match?(inline_entry))

    # Pinyin mismatch+headword match
    inline_entry = Entry.parse_inline_entry("味同嚼蠟|味同嚼蜡[wei4 fu2 jue2 la4]")
    assert_equal(false,base_entry.inline_entry_match?(inline_entry))
  end
  
  def test_add_ref_entry_to_meaning
    base_entry = CEdictEntry.new
    base_entry.parse_line("味同嚼蠟 味同嚼蜡 [wei4 tong2 jue2 la4] /insipid (like chewing wax)/")
    
    ref_entry = CEdictEntry.new
    ref_entry.parse_line("味同嚼蠟 味同嚼蜡 [wei4 tong2 jiao2 la4] /see 味同嚼蠟|味同嚼蜡[wei4 tong2 jue2 la4]/")
    base_entry.add_ref_entry_into_meanings(ref_entry)
    
    meaning_two = Meaning.new("Also: 味同嚼蠟|味同嚼蜡 [wei4 tong2 jiao2 la4]",["reference"])
    assert_equal(meaning_two,base_entry.meanings[1])
  end

  def test_add_erhua_entry_to_meaning
    base_entry = CEdictEntry.new
    base_entry.parse_line("哥們 哥们 [ge1 men5] /Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")
    
    erhua_entry = CEdictEntry.new
    erhua_entry.parse_line("哥們兒 哥们儿 [ge1 men5 r5] /erhua variant of 哥們|哥们, Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")
    
    base_entry.add_variant_entry_to_base_meanings(erhua_entry)
    assert_equal(5,base_entry.meanings.count)
    
    expected_meaning = Meaning.new("Has Erhua variant: 哥們兒|哥们儿 [ge1 men5 r5]",["reference"])
    assert_equal(expected_meaning,base_entry.meanings[4])
  end

  def test_add_base_entry_to_erhua_entry_meaning
    base_entry = CEdictEntry.new
    base_entry.parse_line("哥們 哥们 [ge1 men5] /Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")
    
    erhua_entry = CEdictEntry.new
    erhua_entry.parse_line("哥們兒 哥们儿 [ge1 men5 r5] /erhua variant of 哥們|哥们, Brothers!/brethren/dude (colloquial)/brother (diminutive form of address between males)/")

    erhua_entry.add_base_entry_to_variant_meanings(base_entry)
    assert_equal(5,erhua_entry.meanings.count)
    
    expected_meaning = Meaning.new("Erhua variant of: 哥們|哥们 [ge1 men5]",["reference"])
    assert_equal(expected_meaning,erhua_entry.meanings[4])
  end
  

  # Test pinyin conversion function
#  def test_transform_pinyin
#    entry = CEdictEntry.new
#    result1 = entry.transform_pinyin("she4 xiang4 ji1")
#    result2 = entry.transform_pinyin("pang2 bian1 r5")
#    assert_equal("she xiang ji",result1)
#    assert_equal("pang bian r",result2)
#  end

end