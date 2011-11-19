require 'test/unit'

class GetPinyinUnicodeTest < Test::Unit::TestCase


  def test_pinyin_similarities_1
    reading = "ài dai5"
    pinyin = "àidāi"
    result = pinyin.is_similar_pinyin?(reading)
    assert_equal(result, true)
  end
  
end