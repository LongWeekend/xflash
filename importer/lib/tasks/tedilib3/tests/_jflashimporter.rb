require 'test/unit'

class JFlashImporterTest < Test::Unit::TestCase

  def test_romaji_conversion
    assert_equal("fuku", Importer.xfrm_to_romaji("ふく"))
    assert_equal("nyoro", Importer.xfrm_to_romaji("にょろ"))
    assert_equal("chakuchokuchuku", Importer.xfrm_to_romaji("ちゃくちょくちゅく"))
    assert_equal("teruteru坊主", Importer.xfrm_to_romaji("てるてる坊主"))
  end

  def test_merge_duplicate_entries

    #################################
    # String concatenation testing
    #################################
    new_array = []
    existing_array = []
    expected_array = []

    ## ------------------------------------------------------------------
    existing_array <<  {:all_tags=>["n", "abbr", "col"],
     :card_id=>"295",
     :headwords=>[{:headword=>"Ｍ", :tags=>[], :priority=>[]}],
     :readings=>
      [{:romaji=>"emu",
        :tags=>[],
        :reading=>"エム",
        :headword_ref=>nil,
        :priority=>[]}],
     :pos=>["n"],
     :meanings=>
      [{:lang=>[],
        :sense=>"letter 'M'",
        :pos=>[],
        :references=>[{:type=>"xref", :target=>"Ｓ"}],
        :cat=>["abbr"]},
       {:lang=>[], :sense=>"Mega", :pos=>[], :references=>[], :cat=>[]},
       {:lang=>[],
        :sense=>"masochist/masochistic",
        :pos=>[],
        :references=>[],
        :cat=>["col"]}],
     :jmdict_refs=>["2211550"],
     :common=>false,
     :cat=>["abbr", "col"]}

    new_array << {:all_tags=>["n", "abbr", "col", "jlpt1"],
     :headwords=>[{:headword=>"Ｍ", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"emu",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"エム",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[],
        :sense=>"letter 'M'",
        :references=>[{:type=>"xref", :target=>"Ｓ"}],
        :pos=>[],
        :cat=>["abbr"]},
       {:lang=>[], :sense=>"Mega", :references=>[], :pos=>[], :cat=>[]},
       {:lang=>[],
        :sense=>"masochist/masochistic",
        :references=>[],
        :pos=>[],
        :cat=>["col"]}],
     :jmdict_refs=>["2211550"],
     :cat=>["abbr", "col", "jlpt1"],
     :common=>false}

    expected_array << {:lang=>[],
     :all_tags=>["n", "abbr", "col", "jlpt1"],
     :card_id=>"295",
     :headwords=>[{:headword=>"Ｍ", :tags=>[], :priority=>[]}],
     :readings=>
      [{:romaji=>"emu",
        :tags=>[],
        :reading=>"エム",
        :headword_ref=>nil,
        :priority=>[]}],
     :pos=>["n"],
     :meanings=>
      [{:lang=>[],
        :sense=>"letter 'M'",
        :pos=>[],
        :references=>[{:type=>"xref", :target=>"Ｓ"}],
        :cat=>["abbr"]},
       {:lang=>[], :sense=>"Mega", :pos=>[], :references=>[], :cat=>[]},
       {:lang=>[],
        :sense=>"masochist/masochistic",
        :pos=>[],
        :references=>[],
        :cat=>["col"]}],
     :jmdict_refs=>["2211550"],
     :common=>false,
     :cat=>["abbr", "col", "jlpt1"]}

     ## ------------------------------------------------------------------
     existing_array <<  {:all_tags=>["n"],
      :card_id=>"3",
      :headwords=>[{:headword=>"ヽ", :tags=>[], :priority=>[]}],
      :readings=>
       [{:romaji=>"kurikaeshi",
         :tags=>[],
         :reading=>"くりかえし",
         :headword_ref=>nil,
         :priority=>[]}],
      :pos=>["n"],
      :meanings=>
       [{:lang=>[],
         :sense=>"repetition mark in katakana",
         :pos=>[],
         :references=>[],
         :cat=>[]}],
      :jmdict_refs=>["1000000"],
      :common=>false,
      :cat=>[]}

     new_array <<  {:all_tags=>["n", "exp"],
      :headwords=>[{:headword=>"ヽ", :tags=>[], :priority=>[]}],
      :pos=>["n", "exp"],
      :readings=>
       [{:romaji=>"kurikaeshi",
         :tags=>[],
         :headword_ref=>nil,
         :reading=>"くりかえし",
         :priority=>[]}],
      :meanings=>
       [{:lang=>[],
         :sense=>"repetition mark in katakana",
         :references=>[],
         :pos=>[],
         :cat=>[]}],
      :jmdict_refs=>["1000000"],
      :cat=>[],
      :common=>false}

     expected_array << {:lang=>[],
      :all_tags=>["n", "exp"],
      :card_id=>"3",
      :headwords=>[{:headword=>"ヽ", :tags=>[], :priority=>[]}],
      :readings=>
       [{:romaji=>"kurikaeshi",
         :tags=>[],
         :reading=>"くりかえし",
         :headword_ref=>nil,
         :priority=>[]}],
      :pos=>["n", "exp"],
      :meanings=>
       [{:lang=>[],
         :sense=>"repetition mark in katakana",
         :pos=>[],
         :references=>[],
         :cat=>[]}],
      :jmdict_refs=>["1000000"],
      :common=>false,
      :cat=>[]}

      ## ------------------------------------------------------------------
      existing_array << {:all_tags=>["n", "wasei"],
       :card_id=>"439",
       :headwords=>[{:headword=>"Ｖシネマ", :tags=>[], :priority=>[]}],
       :readings=>
        [{:romaji=>"buishinema",
          :tags=>[],
          :reading=>"ブイシネマ",
          :headword_ref=>nil,
          :priority=>[]}],
       :pos=>["n"],
       :meanings=>
        [{:lang=>[{:word=>"V-cinema", :language=>"wasei"}],
          :sense=>
           "film released direct-to-video (trademark of Toei Company) (cf. V-cinema)",
          :pos=>[],
          :references=>[],
          :cat=>[]}],
       :jmdict_refs=>["2451810"],
       :common=>false,
       :cat=>[]}

      new_array << {:all_tags=>["n", "wasei"],
       :headwords=>[{:headword=>"Ｖシネマ", :tags=>[], :priority=>[]}],
       :pos=>["n"],
       :readings=>
        [{:romaji=>"buishinema",
          :tags=>[],
          :headword_ref=>nil,
          :reading=>"ブイシネマ",
          :priority=>[]}],
       :meanings=>
        [{:lang=>[{:word=>"V-cinema", :language=>"wasei"}],
          :sense=>
           "film released direct-to-video (trademark of Toei Company) (cf. V-cinema)",
          :references=>[],
          :pos=>[],
          :cat=>[]}],
       :jmdict_refs=>["2451810"],
       :cat=>[],
       :common=>false}

      expected_array <<  {:lang=>[],
       :all_tags=>["n", "wasei"],
       :card_id=>"439",
       :headwords=>[{:headword=>"Ｖシネマ", :tags=>[], :priority=>[]}],
       :readings=>
        [{:romaji=>"buishinema",
          :tags=>[],
          :reading=>"ブイシネマ",
          :headword_ref=>nil,
          :priority=>[]}],
       :pos=>["n"],
       :meanings=>
        [{:lang=>[{:word=>"V-cinema", :language=>"wasei"}],
          :sense=>
           "film released direct-to-video (trademark of Toei Company) (cf. V-cinema)",
          :pos=>[],
          :references=>[],
          :cat=>[]}],
       :jmdict_refs=>["2451810"],
       :common=>false,
       :cat=>[]}

       ## ------------------------------------------------------------------
       existing_array << {:all_tags=>["abbr"],
        :lang=>[],
        :card_id=>"37770",
        :headwords=>[{:headword=>"ワーホリ", :tags=>[], :priority=>[]}],
        :pos=>[],
        :readings=>
         [{:romaji=>"waahori",
           :tags=>[],
           :headword_ref=>nil,
           :reading=>"ワーホリ",
           :priority=>[]}],
        :meanings=>
         [{:lang=>[],
           :sense=>"working holiday",
           :references=>[{:type=>"xref", :target=>"ワーキングホリデー"}],
           :pos=>[],
           :cat=>["abbr"]},
          {:lang=>[],
           :sense=>"person on a working holiday",
           :references=>[],
           :pos=>[],
           :cat=>[]}],
        :jmdict_refs=>["1960340", "ManuallyCompiledWordsEdictFormat.txt:1256"],
        :cat=>["abbr"],
        :common=>false}

       new_array << {:all_tags=>["Long_Weekend_Favorites"],
        :headwords=>[{:headword=>"ワーホリ", :tags=>[], :priority=>[]}],
        :pos=>[],
        :readings=>
         [{:romaji=>"waahori",
           :tags=>[],
           :headword_ref=>nil,
           :reading=>"ワーホリ",
           :priority=>[]}],
        :meanings=>
         [{:lang=>[],
           :sense=>"working holiday",
           :references=>[],
           :pos=>[],
           :cat=>[]}],
        :jmdict_refs=>["edict2-1.txt:4"],
        :cat=>["Long_Weekend_Favorites"],
        :common=>false}

       expected_array << 
       {:all_tags=>["abbr", "Long_Weekend_Favorites"],
        :lang=>[],
        :card_id=>"37770",
        :headwords=>[{:headword=>"ワーホリ", :tags=>[], :priority=>[]}],
        :pos=>[],
        :readings=>
         [{:romaji=>"waahori",
           :tags=>[],
           :headword_ref=>nil,
           :reading=>"ワーホリ",
           :priority=>[]}],
        :meanings=>
         [{:lang=>[],
           :sense=>"working holiday",
           :references=>[{:type=>"xref", :target=>"ワーキングホリデー"}],
           :pos=>[],
           :cat=>["abbr"]},
          {:lang=>[],
           :sense=>"person on a working holiday",
           :references=>[],
           :pos=>[],
           :cat=>[]}],
        :jmdict_refs=>
         ["1960340", "ManuallyCompiledWordsEdictFormat.txt:1256", "edict2-1.txt:4"],
        :cat=>["abbr", "Long_Weekend_Favorites"],
        :common=>false}

    (0..new_array.size-1).each do |idx|
      merged_entry, merged_occurred = JFlashImporter.merge_duplicate_entries(new_array[idx], existing_array[idx])
      ##pp merged_entry
      for i in 0..merged_entry[:meanings].size-1
        assert_equal(expected_array[idx][:meanings][i], merged_entry[:meanings][i], "Merged strings had problems (No #{i})!")
      end
      assert_equal(expected_array[idx][:cat], merged_entry[:cat], "Merged cat tags had problems (No #{i})!")
      assert_equal(expected_array[idx][:all_tags].sort, merged_entry[:all_tags].sort, "Merged cat tags had problems (No #{i})!")
    end

  end

  def test_get_inline_tags_from_sense
    senses_arr = []
    tags_expected_arr = []
    
    senses_arr << "to run (race, esp. horse)/to gallop/to canter (v1, vi)"
    tags_expected_arr << ["v1","vi"]

    senses_arr << "maid (n, vs)"
    tags_expected_arr << ["n","vs"]
    
    senses_arr << "help"
    tags_expected_arr << []
    
    senses_arr << "to soar / to fly (usu. 翔る. 翔ける v1 is unorthodox.) (v5r,vi)"
    tags_expected_arr << ["v5r","vi"]
    
    senses_arr << "to reflect / to reconsider (exp)"
    tags_expected_arr << ["exp"]

    # For each senses/expected combination, loop and compare results
    for i in 0..(senses_arr.size-1)
      result = JFlashImporter.get_inline_tags_from_sense(senses_arr[i])
      assert_equal(tags_expected_arr[i], result)
    end

  end

  def test_get_formatted_meanings

    edict2hashes = []
    expected_txt = []
    expected_htm = []

    edict2hashes << {:card_id=>"454",
     :jmdict_refs=>["edict2_20100316_utf8.txt:454,_testdata-edict2-jlpt.txt:2"],
     :headwords=>[{:headword=>"ああ", :tags=>[], :priority=>[]}],
     :pos=>["adv"],
     :lang=>[],
     :readings=>
      [{:romaji=>"aa",
        :headword_ref=>[],
        :tags=>[],
        :reading=>"ああ",
        :priority=>[]},
       {:romaji=>nil, :headword_ref=>[], :tags=>[], :reading=>nil, :priority=>[]}],
     :common=>nil,
     :meanings=>
      [{:cat=>[],
        :pos=>[],
        :lang=>[],
        :sense=>
         "like that (used for something or someone distant from both speaker and listener) / so (adv)",
        :references=>[]}],
     :cat=>["jlpt9"]}
     
    expected_txt << "like that (used for something or someone distant from both speaker and listener) / so (adv)"
    expected_htm << "like that (used for something or someone distant from both speaker and listener) / so <dfn>adv</dfn>"
    
    edict2hashes << {:jmdict_refs=>["2164820"],
     :headwords=>[{:headword=>"お座り", :tags=>[], :priority=>[]}],
     :pos=>["n","vs"],
     :lang=>[],
     :readings=>
      [{:romaji=>"osuwari",
        :headword_ref=>nil,
        :tags=>[],
        :reading=>"おすわり",
        :priority=>[]}],
     :common=>false,
     :meanings=>
      [{:tags=>["chn"], :lang=>[], :sense=>"sit down/sit up (n, vs)", :references=>[]},
       {:tags=>[], :lang=>[], :sense=>"Sit! (to a dog)", :references=>[]}],
     :cat=>[],
     :all_tags=>[]}
     
    expected_txt << "sit down / sit up (n, vs); Sit! (to a dog)"
    expected_htm << "<ol><li>sit down / sit up <dfn>n</dfn><dfn>vs</dfn></li><li>Sit! (to a dog)</li></ol>"
    
    edict2hashes << {:jmdict_refs=>["2197150"],
     :headwords=>[{:headword=>"×", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"batsu",
        :headword_ref=>nil,
        :tags=>[],
        :reading=>"ばつ",
        :priority=>[]},
       {:romaji=>"peke",
        :headword_ref=>nil,
        :tags=>[],
        :reading=>"ぺけ",
        :priority=>[]},
       {:romaji=>"peke",
        :headword_ref=>nil,
        :tags=>[],
        :reading=>"ペケ",
        :priority=>[]}],
     :common=>false,
     :meanings=>
      [{:pos=>[],
        :cat=>[],
        :lang=>[],
        :sense=>"x-mark (used to indicate an incorrect answer in a test, etc.)",
        :references=>[{:type=>"xref", :target=>"罰点"}]},
       {:pos=>["ukana"],
        :cat=>[],
        :sense=>"impossibility/futility/uselessness",
        :references=>[{:type=>"reading", :target=>["ペケ"]}]}],
     :cat=>[],
     :all_tags=>[]}

    expected_txt << "x-mark (used to indicate an incorrect answer in a test, etc.) (n); impossibility / futility / uselessness"
    expected_htm << "<ol><li>x-mark (used to indicate an incorrect answer in a test, etc.) <dfn>n</dfn></li><li>impossibility / futility / uselessness</li></ol>"

    edict2hashes << {:cat=>[],
     :jmdict_refs=>["1586730"],
     :common=>false,
     :headwords=>
      [{:headword=>"粗", :tags=>[], :priority=>[]},
       {:headword=>"荒", :tags=>[], :priority=>[]}],
     :all_tags=>["n", "pref"],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"ara",
        :headword_ref=>nil,
        :tags=>[],
        :reading=>"あら",
        :priority=>[]}],
     :meanings=>
      [{:cat=>[],
        :lang=>[],
        :pos=>[],
        :sense=>"leftovers (after filleting a fish)",
        :references=>[]},
       {:cat=>[], :lang=>[], :pos=>[], :sense=>"rice chaff", :references=>[]},
       {:cat=>[],
        :lang=>[],
        :pos=>["pref"],
        :sense=>"flaw (esp. of a person)/ rough/roughly",
        :references=>[]},
       {:cat=>[],
        :lang=>[],
        :pos=>[],
        :sense=>"crude/raw/natural/wild",
        :references=>[]}]}

    expected_txt << "leftovers (after filleting a fish) (n); rice chaff; flaw (esp. of a person) / rough / roughly (pref); crude / raw / natural / wild"
    expected_htm << "<ol><li>leftovers (after filleting a fish) <dfn>n</dfn></li><li>rice chaff</li><li>flaw (esp. of a person) / rough / roughly <dfn>pref</dfn></li><li>crude / raw / natural / wild</li></ol>"

    for i in 0..edict2hashes.size-1
      meanings_txt, meanings_html, meanings_fts = JFlashImporter.get_formatted_meanings(edict2hashes[i])
      assert_equal(expected_txt[i], meanings_txt)
      assert_equal(expected_htm[i], meanings_html)
    end
    
  end

  def test_xfrm_inline_tags_with_meaning

    prt "Testing parse of xforming tags with meaning"
    meaning_strs = []
    tags_array   = []
    expected_txt = []
    expected_htm = []
    expected_fts = []

    meaning_strs << "repetition of kanji (sometimes voiced)"
    tags_array << ["n"]
    expected_txt << "repetition of kanji (sometimes voiced) (n)"
    expected_htm << "repetition of kanji (sometimes voiced) <dfn>n</dfn>"
    expected_fts << "repetition of kanji"

    meaning_strs << "Sit! (to a dog)"
    tags_array << []
    expected_txt << "Sit! (to a dog)"
    expected_htm << "Sit! (to a dog)"
    expected_fts << "Sit!"

    for i in 0..meaning_strs.size-1
      mtxt, mfts, mhtm = JFlashImporter.xfrm_inline_tags_with_meaning(tags_array[i], meaning_strs[i], 1)
      assert_equal(expected_txt[i], mtxt, "Xformed text meaning was incorrect! #{i}")
      assert_equal(expected_fts[i], mfts, "Xformed full text meaning was incorrect! #{i}")
      assert_equal(expected_htm[i], mhtm, "Xformed HTML meaning was incorrect! #{i}")
    end
  end

  def test_import
    prt "Testing parse of JLPT Merge Data"
    parser = Edict2Parser.new("#{File.dirname(__FILE__)}/../testdata/edict2-1.txt")
    jflash_tags = JFlashImporter.get_existing_tags_by_type
    parser.set_tags(jflash_tags[:pos], jflash_tags[:cat], jflash_tags[:lang])
    results_data = parser.run
    importer = JFlashImporter.new(results_data, $options[:card_types]["DICTIONARY"])
    importer.set_sql_debug(true) ## Do not add to database!
    importer.import
  end

  def no_test_jlpt
    prt "Testing parse of JLPT Merge Data"
    parser = Edict2Parser.new("#{File.dirname(__FILE__)}/../edict2-jlpt.txt", 0,0, "jlpt9")
    jflash_tags = JFlashImporter.get_existing_tags_by_type
    parser.set_tags(jflash_tags[:pos], jflash_tags[:cat], jflash_tags[:lang])
    parser.set_warning_level("IGNORE")
    results_data = parser.run
    importer = JFlashImporter.new(results_data, $options[:card_types]["DICTIONARY"])
    importer.set_sql_debug(true) ## do not add to database!
    importer.set_skip_empty_meanings(true)  ## do not insert empty meanings
    importer.import
  end
  
  def no_test_data_dump
    prt "Testing parse of JLPT Merge Data"
    parser = Edict2Parser.new("#{File.dirname(__FILE__)}/../testdata/edict2-1.txt")
    jflash_tags = JFlashImporter.get_existing_tags_by_type
    parser.set_tags(jflash_tags[:pos], jflash_tags[:cat], jflash_tags[:lang])
    results_data = parser.run
    importer = JFlashImporter.new(results_data, $options[:card_types]["DICTIONARY"])
    importer.set_sql_debug(true)
    importer.import
  end

  def test_combine_and_uniq_arrays
    arr1 = ["1","a",nil,"",0]
    arr2 = ["2","a",nil,"ok",0]
    arr3 = [["1"],[nil,nil],"bug",0]

    result = Parser.combine_and_uniq_arrays(arr1,arr2,arr3)
    assert_equal(["1", "a", "", 0, "2", "ok", "bug"], result)

    arr4 = ["1","a",nil,"",0]
    result = Parser.combine_and_uniq_arrays(arr4)
    assert_equal(["1","a","",0], result)
  end

  def test_mysql_deserialise_ruby_object
    packed="BAh7DzoJbGFuZ1sAOg1hbGxfdGFnc1sAOgxjYXJkX2lkIgYzOg5oZWFkd29y
    ZHNbBnsIOg1oZWFkd29yZCII44O9Ogl0YWdzWwA6DXByaW9yaXR5WwA6DXJl
    YWRpbmdzWwZ7CjoLcm9tYWppIg9rdXJpa2Flc2hpOwpbADoMcmVhZGluZyIU
    44GP44KK44GL44GI44GXOhFoZWFkd29yZF9yZWYwOwtbADoIcG9zWwA6DW1l
    YW5pbmdzWwZ7CjsAWwA6CnNlbnNlIiByZXBldGl0aW9uIG1hcmsgaW4ga2F0
    YWthbmE7EFsGIgZuOg9yZWZlcmVuY2VzWwA6CGNhdFsAOhBqbWRpY3RfcmVm
    c1sGIgwxMDAwMDAwOgtjb21tb25GOxRbAA=="

    unpacked =  mysql_deserialise_ruby_object(packed)
    expected = {:all_tags=>[],
     :lang=>[],
     :card_id=>"3",
     :headwords=>[{:headword=>"ヽ", :tags=>[], :priority=>[]}],
     :pos=>[],
     :readings=>
      [{:romaji=>"kurikaeshi",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"くりかえし",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[],
        :sense=>"repetition mark in katakana",
        :references=>[],
        :pos=>["n"],
        :cat=>[]}],
     :jmdict_refs=>["1000000"],
     :cat=>[],
     :common=>false}

     assert_equal(unpacked, expected,"Deserialistion failed!!")
     ##pp edict2hash_unpacked

  end

  def test_get_existing_card_hash
    packed ="BAh7DToQam1kaWN0X3JlZnNbBiIMMTU0NDA2MDoIY2F0WwA6C2NvbW1vbkY6
    DmhlYWR3b3Jkc1sHewg6DWhlYWR3b3JkIhHkvZnmpa3nhKHjgY86CXRhZ3Nb
    ADoNcHJpb3JpdHlbAHsIOwkiEeS9mealreOBquOBjzsKWwA7C1sAOg1hbGxf
    dGFnc1sGIghhZHY6CHBvc1sGQBM6DXJlYWRpbmdzWwZ7CjoLcm9tYWppIg95
    b2d5b3VuYWt1OhFoZWFkd29yZF9yZWYwOwpbADoMcmVhZGluZyIX44KI44GO
    44KH44GG44Gq44GPOwtbADoNbWVhbmluZ3NbBnsKOglsYW5nWwA7BlsAOw1b
    ADoKc2Vuc2UiJ3VuYXZvaWRhYmx5L25lY2Vzc2FyaWx5L2luZXZpdGFibHk6
    D3JlZmVyZW5jZXNbAA=="
    expected = mysql_deserialise_ruby_object(packed)

    connect_db
    card_id = $cn.select_one("SELECT card_id FROM cards_staging WHERE headword = '余業無く'")["card_id"]
    card=JFlashImporter.get_existing_card_hash_optimised(card_id)

    # Remove card_ids on hashes, no longer included on DB updates!
    card.delete(:card_id)
    expected.delete(:card_id)

    assert_equal(expected, card, "Deserialised card hash does match!!")
  end

  def test_get_kana_only_duplicate_by_reading
    hw ="あいにく"
    result = JFlashImporter.get_kana_only_duplicate_by_reading_optimised(hw, $options[:card_types]['DICTIONARY'])
    expected = {:common=>true,
     :all_tags=>["adj-na", "adv", "n", "adj-no", "ukana", "common", "jlpt2"],
     :card_id=>"96381",
     :headwords=>
      [{:headword=>"生憎", :tags=>["common"], :priority=>[]},
       {:headword=>"合憎", :tags=>["ikanji"], :priority=>[]}],
     :readings=>
      [{:romaji=>"ainiku",
        :tags=>[],
        :reading=>"あいにく",
        :priority=>[],
        :headword_ref=>nil}],
     :pos=>["adj-na", "adv", "n", "adj-no"],
     :meanings=>
      [{:lang=>[],
        :sense=>"unfortunately/Sorry, but ...",
        :pos=>[],
        :references=>[],
        :cat=>["ukana", "common"]}],
     :jmdict_refs=>["1379210", "jlpt-voc-2.utf.txt:14"],
     :cat=>["ukana", "common", "jlpt2"]}
    
    assert_equal(result, expected, "Failed retrieving duplicate match for kana only headword #{hw}")
    ##pp result
  end

end