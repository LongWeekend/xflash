require 'test/unit'

class TagImporterTest < Test::Unit::TestCase
  
  include DatabaseHelpers
  
  def setup
    # Clear out everything first, then import
    TagImporter.tear_down_all_tags
  end

  #=========================
  # TEST METHODS
  #=========================

  def test_import_starred_tag
    # For starred words
    configuration = TagConfiguration.new("system_tags.yml", "starred")
    importer = TagImporter.new(nil, configuration)
    importer.import

    # My Starred Words should also be editable
    $cn.execute("SELECT tag_id, editable from tags_staging WHERE tag_name LIKE 'My Starred Words'").each do |rec|
      assert_equal(1, rec[0])
      assert_equal(1, rec[1])
    end
  end
    
  def test_import_lwe_favs
    # For LWE's Favourite - get them parsed
    configuration = TagConfiguration.new("system_tags.yml", "lwe_favs")
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    
    parser = WordListParser.new(test_file_path)
    entries = parser.run('CSVEntry')
    assert_equal(13,entries.count)
    importer = TagImporter.new(entries, configuration)
    matched_records_arr = importer.import
    
    # LWE should be editable
    $cn.execute("SELECT tag_id, editable from tags_staging WHERE tag_name LIKE 'Long Weekend Favorites'").each do |tag_id, editable|
      assert_equal(1, editable)
      assert_equal(1, tag_id) # We already added starred words as ID = 0
    end
    
    # LWE should have 13 cards
    $cn.execute("SELECT count(*) as count from card_tag_link WHERE tag_id = '1'").each do |tag_count_rec|
      assert_equal(13, tag_count_rec[0])
    end
  end
  
  def test_import_800_small
    configuration = TagConfiguration.new("file_800_config.yml", "tag_800_test_file_small")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('CSVEntry')
    
    # Asserting the number of result with the fixed number 
    # of how many result it should be based on the test file.
    assert_equal(43, results.length)
    
    importer = TagImporter.new(results, configuration)
    importer.import

    # There should be 39 associated cards now -- 4 of the cards can't be matched by the importer (2 unknown x 2 dupes)
    $cn.execute("SELECT count(*) as count from card_tag_link WHERE tag_id = '%s'" % importer.tag_id).each do |tag_count_rec|
      assert_equal(39, tag_count_rec[0])
    end
  end
  
  def test_fuzzy_matching_on_yi_or_bu_sound_change
    hsk_entry = HSKEntry.new
    hsk_entry.parse_line('309,6,"不料","bu2 liao4","unexpectedly; to one\'s surprise"')
    hsk_entry2 = HSKEntry.new
    hsk_entry2.parse_line('4256,5,"一辈子","yi2 bei4 zi5","(for) a lifetime"')
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("不料 不料 [bu4 liao4] /unexpectedly/to one's surprise/")
    cedict_entry.id = 200  # We need a non-negative ID for this not to fail
    cedict_entry2 = CEdictEntry.new
    cedict_entry2.parse_line("一輩子 一辈子 [yi1 bei4 zi5] /(for) a lifetime/")
    cedict_entry2.id = 200  # We need a non-negative ID for this not to fail

    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([cedict_entry, cedict_entry2])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([hsk_entry, hsk_entry2], configuration, cache)
    
    # Returns the number of matched entries
    importer.import
    assert_equal(2,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
  def test_simplified_only_matching
    book_entry = BookEntry.new
    book_entry.parse_line('台風	台风	tai2 feng1	/typhoon/')
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("颱風 台风 [tai2 feng1] /hurricane/typhoon/")

    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([cedict_entry])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([book_entry], configuration, cache)
    
    # Returns the number of matched entries
    importer.import
    assert_equal(1,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
  def test_headword_only_matching
    bigram_entry = BigramEntry.new
    bigram_entry.parse_line("6	问题	19992	8.50211672358	174715")
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("問題 问题 [wen4 ti2] /question/problem/issue/topic/CL:個|个[ge4]/")
    cedict_entry.id = 3

    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([cedict_entry])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([bigram_entry], configuration, cache)

    # Returns the number of matched entries
    importer.import
    assert_equal(1,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
  def test_headword_only_dupes
    bigram_entry = BigramEntry.new
    bigram_entry.parse_line("6	问题	19992	8.50211672358	174715")
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("問題 问题 [wen4 ti2] /question/problem/issue/topic/CL:個|个[ge4]/")
    cedict_entry.id = 3
    cedict_entry_2 = CEdictEntry.new
    cedict_entry_2.parse_line("問題 问题 [wen4 ti2] /question/problem/issue/topic/CL:個|个[ge4]/")
    cedict_entry_2.id = 4

    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([cedict_entry, cedict_entry_2])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([bigram_entry], configuration, cache)

    # Returns the number of matched entries
    importer.import
    assert_equal(0,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(1,importer.cards_multiple_found)
  end

  def test_surname_problem
    book_entry = BookEntry.new
    book_entry.parse_line('文	文	wen2	/language/script/written language/')
    bogus_entry = CEdictEntry.new
    bogus_entry.parse_line("文 文 [Wen2] /surname Wen/")
    bogus_entry.id = 2
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("文 文 [wen2] /language/culture/writing/formal/literary/gentle/(old) classifier for coins/Kangxi radical 118/")
    cedict_entry.id = 3

    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([bogus_entry,cedict_entry])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([book_entry], configuration, cache)
    
    # Returns the number of matched entries
    importer.import
    assert_equal(1,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
  def test_surname_problem_2
    csv_entry = CSVEntry.new
    csv_entry.parse_line('19,"0337","白","bái ","B","(VS)","white"')
    bogus_entry = CEdictEntry.new
    bogus_entry.parse_line("白 白 [Bai2] /surname Bai/")
    bogus_entry.id = 2
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("白 白 [bai2] /white/snowy/pure/bright/empty/blank/plain/clear/to make clear/in vain/gratuitous/free of charge/reactionary/anti-communist/funeral/to stare coldly/to write wrong character/to state/to explain/vernacular/spoken lines in opera/")
    cedict_entry.id = 3
    
    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([bogus_entry,cedict_entry])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([csv_entry], configuration, cache)
    
    # Returns the number of matched entries
    importer.import
    assert_equal(1,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
  # I introduced a bug where non-headword matches were still matching!  Yipe!  This confirms the fix
  def test_custom_csv_entry_matching_criteria
    csv_entry = CSVEntry.new
    csv_entry.parse_line('1425,"0795","約","yuē ","B","(VA)","to make an appointment"')
    bogus_entry = CEdictEntry.new
    bogus_entry.parse_line("曰 曰 [yue1] /to speak/to say/")
    bogus_entry.id = 2
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("約 约 [yue1] /to make an appointment/to invite/approximately/pact/treaty/to economize/to restrict/to reduce (a fraction)/concise/")
    cedict_entry.id = 3
    
    # Now create a mock cache & pass it to the importer
    cache = EntryCache.new([bogus_entry,cedict_entry])
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([csv_entry], configuration, cache)
    
    # Returns the number of matched entries
    importer.import
    assert_equal(1,importer.cards_matched)
    assert_equal(0,importer.cards_not_found)
    assert_equal(0,importer.cards_multiple_found)
  end
  
end