require 'test/unit'

class CEdictEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = CEdictEntry.new
    entry.init
    entry.parse_line(nil)
  end

  # Test parsing utils
  def test_get_tags_from_meaning
    entry = CEdictEntry.new
    entry.init
    tags = entry.get_tags_for_meaning("power or involution (mathematics)")
    expected = {:full_match=>["mathematics"], :partial_match=>[]}
    assert_equal(expected,tags)
  end

  def test_strip_tags_from_meaning
    entry = CEdictEntry.new
    entry.init
    meaning = entry.strip_tags_from_meaning("power or involution (mathematics)","mathematics")
    expected = "power or involution"
    assert_equal(expected,meaning)
  end

  # Test abbr parsing
  def test_abbr_detection
    entry = CEdictEntry.new
    entry.init
    result = entry.found_abbreviation("abbr. for square or cubic meter")
    assert_equal(true,result)
  end

  # Test erhua parsing
  def test_get_erhua_variant
    entry = CEdictEntry.new
    entry.init
    result = entry.found_erhua_variant("erhua variant of 旁邊|旁边, lateral")
    assert_equal(true,result)
    assert_equal(true,entry.is_erhua_variant)
  end

  def test_strip_erhua_variant
    entry = CEdictEntry.new
    entry.init
    result = entry.strip_erhua_variant("erhua variant of 旁邊|旁边, lateral")
    assert_equal("variant of 旁邊|旁边, lateral",result)
  end
  
  # Tests that basic headword and reading can be parsed

  def test_parse_headword_and_reading
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/")
    assert_equal("播放機",entry.headword_trad)
    assert_equal("播放机",entry.headword_simp)
    assert_equal("bo1 fang4 ji1",entry.pinyin)
  end

  def test_parse_single_meaning
    entry = CEdictEntry.new
    entry.parse_line("播放機 播放机 [bo1 fang4 ji1] /player (e.g. CD player)/")
    expected_meanings = [{:meaning=>"player (e.g. CD player)",:tags=>[]}]
    assert_equal(expected_meanings,entry.meanings)
  end
#堆壘數論 堆垒数论 [dui1 lei3 shu4 lun4] /additive number theory (math.)/

  # Test our ability to break out meanings and extract tags from each  
  def test_parse_multi_meaning
    entry = CEdictEntry.new
    entry.parse_line("方 方 [fang1] /square/power or involution (mathematics)/upright/honest/fair and square/direction/side/party (to a contract, dispute etc)/place/method/prescription (medicine)/upright or honest/just when/only or just/classifier for square things/abbr. for square or cubic meter/ \r\n")
    expected_meanings = [{:meaning=>"square",:tags=>[]},
                         {:meaning=>"power or involution",:tags=>["mathematics"]},
                         {:meaning=>"upright",:tags=>[]},
                         {:meaning=>"honest",:tags=>[]},
                         {:meaning=>"fair and square",:tags=>[]},
                         {:meaning=>"direction",:tags=>[]},
                         {:meaning=>"side",:tags=>[]},
                         {:meaning=>"party (to a contract, dispute etc)",:tags=>[]},
                         {:meaning=>"place",:tags=>[]},
                         {:meaning=>"method",:tags=>[]},
                         {:meaning=>"prescription",:tags=>["medicine"]},
                         {:meaning=>"upright or honest",:tags=>[]},
                         {:meaning=>"just when",:tags=>[]},
                         {:meaning=>"only or just",:tags=>[]},
                         {:meaning=>"classifier for square things",:tags=>[]},
                         {:meaning=>"abbr. for square or cubic meter",:tags=>["abbr"]}]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Test our ability to break out meanings and extract tags from each  
  def test_parse_multi_meaning_replacements
    entry = CEdictEntry.new
    entry.parse_line("方 方 [fang1] /square/power or involution (math.)/upright/honest/fair and square/direction/side/party (to a contract, dispute etc)/place/method/prescription (med.)/upright or honest/just when/only or just/classifier for square things/abbr. for square or cubic meter/ \r\n")
    expected_meanings = [{:meaning=>"square",:tags=>[]},
                         {:meaning=>"power or involution",:tags=>["mathematics"]},
                         {:meaning=>"upright",:tags=>[]},
                         {:meaning=>"honest",:tags=>[]},
                         {:meaning=>"fair and square",:tags=>[]},
                         {:meaning=>"direction",:tags=>[]},
                         {:meaning=>"side",:tags=>[]},
                         {:meaning=>"party (to a contract, dispute etc)",:tags=>[]},
                         {:meaning=>"place",:tags=>[]},
                         {:meaning=>"method",:tags=>[]},
                         {:meaning=>"prescription",:tags=>["medicine"]},
                         {:meaning=>"upright or honest",:tags=>[]},
                         {:meaning=>"just when",:tags=>[]},
                         {:meaning=>"only or just",:tags=>[]},
                         {:meaning=>"classifier for square things",:tags=>[]},
                         {:meaning=>"abbr. for square or cubic meter",:tags=>["abbr"]}]
    assert_equal(expected_meanings,entry.meanings)
  end
  # Test ability to extract classifier  
  def test_parse_classifier
    entry = CEdictEntry.new
    entry.parse_line("攝像機 摄像机 [she4 xiang4 ji1] /video camera/CL:部[bu4]/")
    expected_meanings = [{:meaning=>"video camera",:tags=>[]}]
    assert_equal("部[bu4]",entry.classifier)
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Extract variants - no pinyin
  def test_parse_variant_no_pinyin
    entry = CEdictEntry.new
    entry.parse_line("斾 斾 [pei4] /variant of 旆, pennant/banner/")
    expected_meanings = [{:meaning=>"pennant",:tags=>[]},
                         {:meaning=>"banner",:tags=>[]}]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(false,entry.is_erhua_variant)
    assert_equal("旆",entry.variant_of)
  end
  
  # Extract variants with pinyin
  def test_parse_variant_pinyin
    entry = CEdictEntry.new
    entry.parse_line("旄 旄 [mao4] /variant of 耄[mao4]/")
    expected_meanings = []
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(false,entry.is_erhua_variant)
    assert_equal("耄[mao4]",entry.variant_of)
  end
  
  # Extract variants - erhua (gee I wish I knew what that was)
  def test_parse_erhua_variant
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side/to the side/beside/")
    expected_meanings = [{:meaning=>"lateral",:tags=>[]},
                         {:meaning=>"side",:tags=>[]},
                         {:meaning=>"to the side",:tags=>[]},
                         {:meaning=>"beside",:tags=>[]}]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(true,entry.is_erhua_variant)
    assert_equal("旁邊|旁边",entry.variant_of)
  end
  
  def test_partial_tag_matches
    entry = CEdictEntry.new
    entry.parse_line("旁邊兒 旁边儿 [pang2 bian1 r5] /erhua variant of 旁邊|旁边, lateral/side (Japanese)/to the side (Budd.)/beside (Buddhist)/")
    expected_meanings = [{:meaning=>"lateral",:tags=>[]},
                         {:meaning=>"side (Japanese)",:tags=>["japanese"]},
                         {:meaning=>"to the side (Budd.)",:tags=>["buddhism"]},
                         {:meaning=>"beside (Buddhist)",:tags=>["buddhism"]}]
    assert_equal(expected_meanings,entry.meanings)
    assert_equal(true,entry.is_erhua_variant)
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
    expected_meanings = [{:meaning=>"surname Makdad",:tags=>["surname"]},
                         {:meaning=>"foobar",:tags=>[]}]
    assert_equal(expected_meanings,entry.meanings)
  end
  
  # Test "redirect" detection
  def test_see_redirect
    entry = CEdictEntry.new
    entry.parse_line("旮 旮 [ga1] /see 旮旯[ga1 la2]/")
    assert_equal(true,entry.is_only_redirect)
    
    expected_references = ["旮旯[ga1 la2]"]
    assert_equal(expected_references,entry.references)
  end
  
  # Gotcha!
  def test_see_redirect_false_positive
    entry = CEdictEntry.new
    entry.parse_line("明天見 明天见 [ming2 tian1 jian4] /see you tomorrow/")
    assert_equal(false,entry.is_only_redirect)
    assert_equal(true,entry.references.empty?)
  end
  
  # Test detection of "see also" type meanings
  def test_references
    entry = CEdictEntry.new
    entry.parse_line("昏睡病 昏睡病 [hun1 shui4 bing4] /sleeping sickness/African trypanosomiasis/see also 非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]/")
    assert_equal(false,entry.is_only_redirect)
    
    expected_references = ["非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]"]
    assert_equal(expected_references,entry.references)
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