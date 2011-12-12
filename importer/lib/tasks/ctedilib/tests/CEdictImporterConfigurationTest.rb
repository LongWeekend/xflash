require 'test/unit'

class CEdictImporterConfigurationTest < Test::Unit::TestCase
  
  def test
    new_dict_file = "test_diff_cedict_new.u8"
    configuration = CEdictImporterConfiguration.new("config.yml", new_dict_file)
    
    configuration.get_diff_result_with_previous_file
    configuration.dump
  
    assert_equal(1, 1)
  end
  
end