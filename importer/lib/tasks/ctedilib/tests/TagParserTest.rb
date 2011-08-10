require 'test/unit'

class TagParserTest < Test::Unit::TestCase
  
  # Try test
  def try_test
    test_file_path = File.dirname(__FILE__) + "/../../../../data/cedict/tags/test_800+800020100915.csv"
    parser = CSVParser.new(test_file_path)
    results = parser.run()
    
    # Asserting the number of result with the fixed number 
    # of how many result it should be based on the test file.
    assert_equal(results.length, 42)
    
    test_configuration_file = File.dirname(__FILE__) + "/../../../../config/tags_config/file_800_config.yml"
    configuration = TagsBaseConfiguration.new(test_configuration_file)
    
    importer = Tags800WordsImporter.new(results)
    importer.import()
  end
  
end