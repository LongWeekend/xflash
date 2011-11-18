##################################################
# CTEDI 1.0
##################################################

namespace :ctedi do
  
  ##############################################################################
  desc "Run all unit tests"
  task :test_all => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    include RakeHelpers
    include DebugHelpers
    get_cli_debug
    
    # Require all the tests we want the runner to run
    Dir[File.dirname(__FILE__) +"/ctedilib/tests/*.rb"].each do |file| 
      require file 
    end
    # Test Suite Runs automagically before exit!
  end

  ##############################################################################
  desc "Run all tests in one test file (REQUIRES: class=TestClassName (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_class => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    include RakeHelpers
    include DebugHelpers
    
    get_cli_debug
    
    # Load the test
    load File.dirname(__FILE__) + "/ctedilib/tests/" + get_cli_attrib("class",true) + ".rb"
    # Runs automagically before exit
    
  end

  ##############################################################################
  desc "Run specific unit test (REQUIRES: class=TestClassName test=method_to_test) (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_one => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    include RakeHelpers
    include DebugHelpers
    
    get_cli_debug
    
    # Load the test & run - by running 1, the test runner doesn't run any others (convention?)
    load File.dirname(__FILE__) + "/ctedilib/tests/" + get_cli_attrib("class",true) + ".rb"
    test_name = get_cli_attrib("test",true)
    class_name = get_cli_attrib("class",true)
    test_suite = Test::Unit::TestSuite.new("CTEDI Single Test Runner")
    test_class = class_name.constantize
    test_suite << test_class.new(test_name.downcase)
    Test::Unit::UI::Console::TestRunner.run(test_suite) 
  end

  ##############################################################################
  desc "cFlash CEDICT Parse & Import"
  task :import => :environment do
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    
    include RakeHelpers
    include DebugHelpers
    
    get_cli_debug
    
    # Parse
    prt "\nCEDICT Parse - Initial Flatfile Parse"
    prt_dotted_line
    parser = CEdictParser.new(File.dirname(__FILE__) + "/../../data/cedict/cedict_ts.u8")
    entries = parser.run
    
    prt "\nCEDICT Parse - Pass 2 (Merge 'reference-only' Entries: %s reference, %s variant)" % [parser.reference_only_entries.count, parser.variant_only_entries.count]
    prt_dotted_line
    parser.merge_references_into_base_entries(entries, parser.reference_only_entries)
    parser.merge_references_into_base_entries(entries, parser.variant_only_entries)
    
    # Cross-reference the variants
    prt "\nCEDICT Parse - Pass 3 (Cross-Referencing %d Erhua Variants)" % [parser.erhua_variant_entries.count]
    prt_dotted_line
    muxed_base_entries = parser.add_variant_entries_into_base_entries(entries, parser.erhua_variant_entries)
    muxed_erhua_entries = parser.add_base_entries_into_variant_entries(parser.erhua_variant_entries, entries)
    
    prt "\nCEDICT Parse - Pass 4 (Cross-Referencing %d Variants)" % [parser.variant_entries.count]
    prt_dotted_line
    muxed_base_entries = parser.add_variant_entries_into_base_entries(muxed_base_entries, parser.variant_entries)
    muxed_variant_entries = parser.add_base_entries_into_variant_entries(parser.variant_entries, entries)
    
    # Now combine the 3 types of entries -- they're all valid
    entries = muxed_base_entries + muxed_variant_entries + muxed_erhua_entries
    
    # Import
    prt "\nBeginning CEDICT Import"
    prt_dotted_line
    importer = CEdictImporter.new
    importer.empty_staging_tables
    importer.import(entries)
    
    prt "\nParse & Import Finished"
    prt_dotted_line
  end

  ##############################################################################
  desc "cFlash Group & Tag Importer"
  task :tag_import => :environment do
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    include RakeHelpers
    include DebugHelpers
    
    get_cli_debug
    
    # Import groups and match tags within them
    prt "\nBeginning Group & Tag Import"
    prt_dotted_line
    importer = GroupImporter.new("cflash_group_config.yml")
    importer.empty_staging_tables
    importer.import
    
    prt "\nImport Finished"
    prt_dotted_line
  end

  ##############################################################################
  desc "cFlash SQLite Exporter"
  task :export => :environment do
    load File.dirname(__FILE__)+'/ctedilib/_includes.rb'
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    include ImporterHelpers

    exporter = CEdictExporter.new
    exporter.export_staging_db_from_table("cards_staging")
  end

end
#------------------------------------------------------------------------------------------------------------#
