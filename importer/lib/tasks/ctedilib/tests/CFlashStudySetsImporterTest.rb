require 'test/unit'

class CFlashStudySetsImporterTest < Test::Unit::TestCase
  
  def test_test   
     importer = GroupImporter.new("cflash_group_config.yml")
     importer.run()
  end

end