require 'test/unit'

class TagImporterTest < Test::Unit::TestCase
  
  def test_import_800_small
    configuration = TagConfiguration.new("file_800_config.yml", "tag_800_test_file_small")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    # Asserting the number of result with the fixed number 
    # of how many result it should be based on the test file.
    assert_equal(results.length, 42)
    
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
    importer = TagsBaseImporter.new(nil, configuration)
    importer.import()
    
    # For LWE's Favourite
    configuration = TagsBaseConfiguration.new("system_tags.yml", "lwe_favs")
    importer = TagImporter.new(nil, configuration)
    importer.import()
  end
  
  def test_import_beg_chinese
     configuration = TagConfiguration.new("file_books_config.yml", "beg_chinese_lesson_1")

      test_file_path = File.dirname(__FILE__) + configuration.file_name
      parser = BookListParser.new(test_file_path)
      results = parser.run()

      importer = TagImporter.new(results, configuration)
      importer.import()
  end
  
end