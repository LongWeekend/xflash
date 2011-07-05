require 'test/unit'

class Tanc2JFlashImporterTest < Test::Unit::TestCase

  def test_parse

    parser = TancParser.new("#{File.dirname(__FILE__)}/../testdata/tanc-1.txt")
    results_arr = parser.run

    ids_found = false
    index_word_found = false
    sentence_word_found = false
    reading_found = false

    results_arr.each do |r|
      ids_found = !!(r[:tanc_ja_id] and r[:tanc_en_id])
      r[:references].each do |ref|
        index_word_found = (ref[:index_word] and ref[:index_word] != "")
        sentence_word_found = !ref[:sentence_word].nil?
        reading_found = !ref[:reading].nil?
      end

      assert_equal(true, ids_found)
      assert_equal(Fixnum, r[:tanc_en_id].to_i.class) ## is a number
      assert_equal(Fixnum, r[:tanc_ja_id].to_i.class) ## is a number
      assert_equal(true, reading_found)
      assert_equal(true, sentence_word_found)
      assert_equal(true, index_word_found)
      assert_equal(0, r[:translated].scan($regexes[:all_common_kanji_and_kana]).size) ## Enure no jpn characters
    end

  end

  def test_extractor_methods
    line_a = "A: あら、申し訳ございません。	Oh, I'm sorry. [F]#ID=1579_4983"

    result = TancParser.get_gender_tag(line_a)
    assert_equal("F",result, "Gender tag not extracted correctly!")

    result = TancParser.clean_gender_tag(line_a)
    assert_equal("A: あら、申し訳ございません。	Oh, I'm sorry. #ID=1579_4983", result, "Gender tag not cleaned correctly")
    
    line_b = "おい[01] おい[01] 先生 え[01] 嗚呼{ああ} マジ[01]~ 大丈夫{だいじょうぶ} 休講 に 為る(する){したら}"
    result = TancParser.quality_check_marker_found?(line_b)
    assert_equal(true, result, "Quality check marker not found in sentence")

    line_b = "留守[02]~"
    result = TancParser.quality_check_marker_found?(line_b)
    assert_equal(true, result, "Quality check marker not found in ref!")
  end
  
  #Make sure that tildes are getting properly removed so we have all headwords to work with
  def test_tilde_remover
    parser = TancParser.new("#{File.dirname(__FILE__)}/../testdata/tanc-1.txt")
    line_b = "試験 結果発表~ も 恙無い{つつがなく}~ 終わる{終わって} 当面[01]{当面の} 視点 が 自然[02]{自然と} 夏休み に 集まる{集まって} 来る(くる){くる} でしょう{でしょ}"
    references_array = line_b.split($delimiters[:tanc_refs_array])
    processed_references_array = []
    references_array.each do |ref|
      data = parser.class.process_reference(ref)
      processed_references_array << data if !data.empty?
    end
    assert_equal("結果発表",processed_references_array[1][:index_word],"Tilde remover not working")
    assert_equal("恙無い",processed_references_array[2][:index_word],"Tilde remover not working")
  end
  

  def test_get_tanc_identifiers
    line_a = "私たちがそこへ行くかどうかを決めるのは君の責任だ。	It is up to you to decide whether we will go there or not.#ID=1524_4935"
    expected = ["1524","4935"]
    result = TancParser.get_tanc_identifiers(line_a)
    assert_equal(result, expected, "TANC IDs were not extracted right!")
  end

end