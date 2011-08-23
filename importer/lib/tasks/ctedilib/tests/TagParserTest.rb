require 'test/unit'

class TagParserTest < Test::Unit::TestCase
  
  def test_800_small
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file, "tag_800_test_file_small")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    # Asserting the number of result with the fixed number 
    # of how many result it should be based on the test file.
    assert_equal(results.length, 42)
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
  
  def test_800_advanced_words
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file, "tags_800_advance")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
  
  def test_800_intermediate_words
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file, "tags_800_intermediate")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
  
  def test_800_beginner_words
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file, "tags_800_beginner")
    
    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
  
  def test_800_fail
    test_file_path = File.dirname(__FILE__) + "/../../../../data/cedict/tags/test_800+800020100915-rare_cases.csv"
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file)
    
    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
  
end