require 'test/unit'

class TagImporterTest < Test::Unit::TestCase
  
  def test_import_800_small
    configuration = TagConfiguration.new("file_800_config.yml", "tag_800_test_file_small")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    # Asserting the number of result with the fixed number 
    # of how many result it should be based on the test file.
    assert_equal(results.length, 43)
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_800_advanced_words
    configuration = TagConfiguration.new("file_800_config.yml", "tags_800_advance")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end

=begin  
  def test_800_fail
    test_file_path = File.dirname(__FILE__) + "/../../../../data/cedict/tags/test_800+800020100915-rare_cases.csv"
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file)
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
=end
  
  def test_import_system_tags
    # For starred words
    configuration = TagConfiguration.new("system_tags.yml", "starred")
    importer = TagImporter.new(nil, configuration)
    importer.import()
    
    # For LWE's Favourite
    configuration = TagConfiguration.new("system_tags.yml", "lwe_favs")
    importer = TagImporter.new(nil, configuration)
    importer.import()
  end
  
  def test_import_beg_chinese
     configuration = TagConfiguration.new("beg_chinese_config.yml", "beg_chinese_lesson_1")

     test_file_path = File.dirname(__FILE__) + configuration.file_name
     parser = BookListParser.new(test_file_path)
     results = parser.run()

     importer = TagImporter.new(results, configuration)
     importer.import()
  end
  
  def test_import_colloquial_chinese
     configuration = TagConfiguration.new("colloqial_chinese_config.yml", "colloquial_chinese_lesson_1")

     test_file_path = File.dirname(__FILE__) + configuration.file_name
     parser = BookListParser.new(test_file_path)
     results = parser.run()

     importer = TagImporter.new(results, configuration)
     importer.import()
  end
  
  def test_import_npcr
    configuration = TagConfiguration.new("npcr_config.yml", "npcr_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_pcr
    configuration = TagConfiguration.new("pcr_config.yml", "pcr_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_pimsleur
    configuration = TagConfiguration.new("pimsleur_config.yml", "pimsleur1_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()

    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_schaums
    configuration = TagConfiguration.new("schaums_config.yml", "schaums_direction")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_frequency
    configuration = TagConfiguration.new("frequency_config.yml", "frequency_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()
    
    importer = TagImporter.new(results, configuration)
    importer.import()
  end
  
  def test_import_hsk
    configuration = TagConfiguration.new("hsk_config.yml", "hsk_4")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = HSKParser.new(test_file_path)
    results = parser.run()
    breakpoint
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
  def test_import_ic
    configuration = TagConfiguration.new("integrated_chinese_config.yml", "ic_intro_numbers")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()
    breakpoint
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
  def test_import_ic_combined
    configuration = TagConfiguration.new("integrated_chinese_combined_config.yml", "ic_1")

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = BookListParser.new(test_file_path)
    results = parser.run()
    breakpoint
    
    importer = TagImporter.new(results, configuration)
    importer.import()    
  end
  
end