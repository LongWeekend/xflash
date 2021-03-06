require 'test/unit'

class CEdictImporterTest < Test::Unit::TestCase

  def test_short_import
    parser = CEdictParser.new(Rails.root.join("data/cedict/test_cedict.u8").to_s)
    entries = parser.run
  
    importer = CEdictImporter.new
    importer.empty_staging_tables
    importer.import(entries)
  end
  
  def test_import
    # Run the parser
    parser = CEdictParser.new(Rails.root.join("data/cedict/cedict_ts.u8").to_s)
    entries = parser.run
    
    # Pass the parsed entries to the importer
    importer = CEdictImporter.new
    importer.empty_staging_tables
    importer.import(entries)
  end

  def test_tag_list_builder
    results = CEdictImporter.create_tags_hash_from_tags_data
    CEdictImporter.create_tags_staging(results)
  end
  
  # This guy shouldn't be in importer??  TODO - also needs to be fixed to accommodate more headwords
  def test_keyword_index_builder
    CEdictImporter.create_headword_index
  end
  
#  def test_headword_dupe_matcher
    # These are the headwords we just imported
#    headword_cache = {0=>{"旄"=>["6"],"旁邊兒"=>["5"],"方"=>["3"],"播放機"=>["1"],"斾"=>["4"],"攝像機"=>["2"]}}
  
#    importer = CEdictImporter.new({})
#    dupes = importer.get_duplicates_by_headword_reading("旁邊兒","pang2 bian1 r5", headword_cache, 0)
    
#    pp dupes
#  end

end