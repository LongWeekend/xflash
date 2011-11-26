require 'test/unit'

class TagImporterTest < Test::Unit::TestCase
  
  include DatabaseHelpers
  
  def setup
    # Clear out everything first, then import
    TagImporter.tear_down_all_tags
  end

  def test_caching
    #TODO: get this number on the spot from cards_staging
    # The total number of entries (currently) -- make sure we have them all
    assert_equal(98314,$card_entries.count)
    
    # Total number of cards that are duplicates
    #SELECT SUM(count) FROM (SELECT headword_simp, count(*) as count FROM cards_staging GROUP BY headword_simp ORDER BY count DESC) as dupes WHERE count > 1
    #3622
    assert_equal((98314 - 3622),$card_entries_by_headword[:simp].count)

    # Number of headwords that have duplicates
    #SELECT COUNT(headword_simp) FROM (SELECT headword_simp, count(*) as count FROM cards_staging GROUP BY headword_simp ORDER BY count DESC) as dupes WHERE count > 1
    #1714
    
    #SELECT SUM(count) FROM (SELECT headword_trad, count(*) as count FROM cards_staging GROUP BY headword_trad ORDER BY count DESC) as dupes WHERE count > 1
    #3069
    assert_equal((98314 - 3069),$card_entries_by_headword[:trad].count)
    
    #SELECT COUNT(headword_trad) FROM (SELECT headword_trad, count(*) as count FROM cards_staging GROUP BY headword_trad ORDER BY count DESC) as dupes WHERE count > 1
    #1470
  end

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
    importer.import
    
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

    # There should be 40 associated cards now -- 3 of the cards can't be matched by the importer
    $cn.execute("SELECT count(*) as count from card_tag_link WHERE tag_id = '%s'" % importer.tag_id).each do |tag_count_rec|
      assert_equal(40, tag_count_rec[0])
    end
    
  end
      
  def test_import_beg_chinese
     configuration = TagConfiguration.new("beg_chinese_config.yml", "beg_chinese_lesson_1")

     test_file_path = File.dirname(__FILE__) + configuration.file_name
     parser = WordListParser.new(test_file_path)
     results = parser.run('BookEntry')

     importer = TagImporter.new(results, configuration)
     importer.import
  end
  
  def test_import_colloquial_chinese
     configuration = TagConfiguration.new("colloqial_chinese_config.yml", "colloquial_chinese_lesson_1")

     test_file_path = File.dirname(__FILE__) + configuration.file_name
     parser = WordListParser.new(test_file_path)
     results = parser.run('BookEntry')

     importer = TagImporter.new(results, configuration)
     importer.import
  end
  
  def test_import_npcr
    configuration = TagConfiguration.new("npcr_config.yml", "npcr_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_pcr
    configuration = TagConfiguration.new("pcr_config.yml", "pcr_1_5")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_pimsleur
    configuration = TagConfiguration.new("pimsleur_config.yml", "pimsleur1_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_schaums
    configuration = TagConfiguration.new("schaums_config.yml", "schaums_asking_for_directions")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_frequency
    configuration = TagConfiguration.new("frequency_config.yml", "frequency_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_hsk
    configuration = TagConfiguration.new("hsk_config.yml", "hsk_4")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('HSKEntry')
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
  def test_import_ic
    configuration = TagConfiguration.new("integrated_chinese_config.yml", "ic_intro_numbers")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
  def test_import_ic_combined
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = WordListParser.new(test_file_path)
    results = parser.run('BookEntry')
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
  def test_simplified_only_matching
    book_entry = BookEntry.new
    book_entry.parse_line('台風	台风	tai2 feng1	/typhoon/')
    cedict_entry = CEdictEntry.new
    cedict_entry.parse_line("颱風 台风 [tai2 feng1] /hurricane/typhoon/")

    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")
    importer = TagImporter.new([book_entry], configuration)
    
    # Now create a mock cache
    cache = EntryCache.new([cedict_entry])
    importer.entry_cache = cache
    
    # Returns the number of matched entries
    assert_equal(1,importer.import)
  end
  
end