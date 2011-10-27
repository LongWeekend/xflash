require 'test/unit'

class CFlashStudySetsImporterTest < Test::Unit::TestCase
  
  def test_import_groups_and_tags  
     importer = GroupImporter.new("cflash_group_config.yml")
     importer.run()
  end

end