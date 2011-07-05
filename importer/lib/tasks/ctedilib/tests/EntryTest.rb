require 'test/unit'

class EntryTest < Test::Unit::TestCase

  # This should work for all entries
  def test_check_pos_tag
    assert_equal(true,Entry.is_pos_tag?("VS"))
    assert_equal(false,Entry.is_pos_tag?("foobar"))
  end

end