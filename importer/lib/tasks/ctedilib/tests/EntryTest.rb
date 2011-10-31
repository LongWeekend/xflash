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
  
end