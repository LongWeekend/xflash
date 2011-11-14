require 'test/unit'

class MeaningTest < Test::Unit::TestCase

  # Test equals
  def test_equal
    meaning1 = Meaning.new("foo",["bar"]);
    meaning2 = Meaning.new("foo",["bar"]);
    assert_equal(meaning1,meaning2)
  end
  
  def test_not_equal
    meaning1 = Meaning.new("fo2");
    meaning2 = Meaning.new("foo");
    assert_not_equal(meaning1,meaning2)
  end
  
  def test_not_equal_different_tag
    meaning1 = Meaning.new("foo",["foo"]);
    meaning2 = Meaning.new("foo",["bar"]);
    assert_not_equal(meaning1,meaning2)
  end

  # Test abbr parsing
  def test_abbr_detection
    meaning = Meaning.new("abbr. for square or cubic meter")
    assert_equal(true,meaning.found_abbreviation?)
  end
  
  # Test ability to extract classifier
  def test_parse_classifier
    meaning = Meaning.new("CL:部[bu4]")
    assert_equal("部[bu4]",meaning.classifier)
  end

  # Test tag parsing
  def test_get_tags_from_meaning
    meaning = Meaning.new("power or involution (mathematics)")
    meaning.parse
    tags = ["mathematics"]
    assert_equal(tags,meaning.tags)
  end

  def test_partial_tag_matches
    meaning = Meaning.new("to the side (Budd.)")
    meaning.parse
    assert_equal(["buddhism"],meaning.tags)
    
    meaning = Meaning.new("side (Japanese)")
    meaning.parse
    assert_equal(["japanese"],meaning.tags)
  end
  
  # Test tag stripping
  def test_strip_tags_from_meaning
    meaning = Meaning.new("power or involution (mathematics)")
    meaning.parse
    expected = "power or involution"
    assert_equal(expected,meaning.meaning)
  end

  # Test detection of "see also" type meanings
  def test_reference_detection
    meaning = Meaning.new("see also 非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]")
    meaning.parse
    expected_reference = "非洲錐蟲病|非洲锥虫病[fei1 zhou1 zhui1 chong2 bing4]"
    assert_equal(expected_reference,meaning.reference)
    assert_equal(true,meaning.is_redirect_only?)
  end
  
  # Test erhua parsing
  def test_get_erhua_variant
    meaning = Meaning.new("erhua variant of 旁邊|旁边, lateral")
    meaning.parse
    assert_equal("旁邊|旁边",meaning.variant)
    assert_equal(true,meaning.is_erhua?)
  end
  
  # Test the stripping thereafter
  def test_strip_erhua_variant
    meaning = Meaning.new("erhua variant of 旁邊|旁边, lateral")
    meaning.parse
    assert_equal("lateral",meaning.meaning)
    assert_equal(false,meaning.is_redirect_only?)
  end
  
  def test_variant
    meaning = Meaning.new("variant of 耄[mao4]")
    meaning.parse
    assert_equal("耄[mao4]",meaning.variant)
  end
  
  def test_see_redirect_reference
    meaning = Meaning.new("see 旮旯[ga1 la2]")
    meaning.parse
    expected_reference = "旮旯[ga1 la2]"
    assert_equal(expected_reference,meaning.reference)
  end
  
  # Gotcha!
  def test_see_redirect_false_positives
    meaning = Meaning.new("see you tomorrow")
    meaning.parse
    assert_equal(false,meaning.reference)
  end
  
  def test_strange_variant_with_space
    meaning = Meaning.new("variant of 按語 按语 [an4 yu3]")
    meaning.parse
    assert_equal("按語 按语 [an4 yu3]",meaning.variant)
  end
  
  def test_strange_variant_with_parenth
    meaning = Meaning.new("variant of 出 (classifier for plays or chapters of classical novels)")
    meaning.parse
    assert_equal("出 (classifier for plays or chapters of classical novels)",meaning.variant)
  end
  
  def test_
  
      #
    #variant of 璽|玺 ruler's seal
    #variant of 伾 or 丕
    #variant of 懈[xie4] and 邂[xie4] (old)
    #erhua variant of 紋縷|纹缕[wen2 lu:3]
    #variant of 薰陶 薰陶[xun1 tao2]
    #variant of 鉞|钺 battle-ax


end