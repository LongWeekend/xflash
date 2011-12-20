require 'test/unit'

class GroupImporterTest < Test::Unit::TestCase
  
  include DatabaseHelpers
  
  def setup
    # Clear out everything first, then import
    GroupImporter.empty_staging_tables
  end

  #=========================
  # TEST METHODS
  #=========================

  def test_import_groups
    importer = GroupImporter.new("test_group_config.yml")
    importer.import
  end
  
end