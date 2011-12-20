require 'test/unit'

class BigramEntryTest < Test::Unit::TestCase

  # Test non-failure on bad data
  def test_bad_input_blank
    entry = BigramEntry.new
    assert_equal(false, entry.parse_line(nil))
  end
  
  def test_throw_exception
    entry = BigramEntry.new
    assert_raise(EntryParseException) do
      entry.parse_line("8	工作	18904	6.89133239246213454")
    end
  end
  
  def test_fishy_line
    entry = BigramEntry.new
    assert_raise(EntryParseException) do
      entry.parse_line("8	工的	18904	3.39133239246213454")
    end
  end

  def test_ignore_comment
    entry = BigramEntry.new
    assert_equal(false, entry.parse_line("/* 序列号	双字组	频率	相互信息分值*/"))
  end

  # Tests that basic headword can be parsed

  def test_parse_headword
    entry = BigramEntry.new
    entry.parse_line("8	工作	18904	6.89133239246	213454")
    assert_equal("",entry.headword_trad)
    assert_equal("工作",entry.headword_simp)
  end

  # Must match headword_simp exactly
  def test_strict_match_criteria
    entry = BigramEntry.new
    entry.parse_line("8	工作	18904	6.89133239246	213454")
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("工作 工作 [gong1 zuo4] /job/work/construction/task/CL:個|个[ge4],份[fen4],項|项[xiang4]/")
    
    result = entry.default_match_criteria.call(cedict_entry,entry)
    assert(true,result)
  end

  def test_loose_match_criteria
    entry = BigramEntry.new
    entry.parse_line("8	工作	18904	6.89133239246	213454")
    
    cedict_entry_beg = CEdictEntry.new
    cedict_entry_beg.parse_line("工作人員 工作人员 [gong1 zuo4 ren2 yuan2] /staff/")
    cedict_entry_mid = CEdictEntry.new
    cedict_entry_mid.parse_line("人工作員 人工作员 [gong1 zuo4 ren2 yuan2] /staff/")
    cedict_entry_end = CEdictEntry.new
    cedict_entry_end.parse_line("人員工作 人员工作 [gong1 zuo4 ren2 yuan2] /staff/")
    no_match_entry = CEdictEntry.new
    no_match_entry.parse_line("工流 工流 [gong1 zuo4 liu2] /workflow/")

    # No match
    assert_equal(false,entry.loose_match_criteria.call(no_match_entry,entry))
    assert_equal(false,entry.default_match_criteria.call(no_match_entry,entry))

    # Partial HW match
    result = entry.loose_match_criteria.call(cedict_entry_beg,entry)
    assert_equal(true,result)
    result = entry.loose_match_criteria.call(cedict_entry_mid,entry)
    assert_equal(true,result)
    result = entry.loose_match_criteria.call(cedict_entry_end,entry)
    assert_equal(true,result)

    # Not exact match
    result = entry.default_match_criteria.call(cedict_entry_beg,entry)
    assert_equal(false,result)
    result = entry.default_match_criteria.call(cedict_entry_mid,entry)
    assert_equal(false,result)
    result = entry.default_match_criteria.call(cedict_entry_end,entry)
    assert_equal(false,result)
  end


end