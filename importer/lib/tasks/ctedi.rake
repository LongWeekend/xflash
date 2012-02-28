##################################################
# CTEDI 1.0
##################################################

namespace :ctedi do
  
  ##############################################################################
  desc "Run all unit tests"
  task :test_all => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    get_cli_debug
    
    # Require all the tests we want the runner to run
    Dir[Rails.root.join("lib/ctedilib/tests/*.rb").to_s].each do |file| 
      require file
    end
    # Test Suite Runs automagically before exit!
  end

  ##############################################################################
  desc "Run all tests in one test file (REQUIRES: class=TestClassName (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_class => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    
    get_cli_debug
    
    # Load the test
    load Rails.root.join(("lib/ctedilib/tests/"+ get_cli_attrib("class",true) + ".rb")).to_s
    # Runs automagically before exit
    
  end

  ##############################################################################
  desc "Run specific unit test (REQUIRES: class=TestClassName test=method_to_test) (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_one => :environment do
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    
    get_cli_debug
    
    # Load the test & run - by running 1, the test runner doesn't run any others (convention?)
    load Rails.root.join("lib/ctedilib/tests/" + get_cli_attrib("class",true) + ".rb").to_s
    test_name = get_cli_attrib("test",true)
    class_name = get_cli_attrib("class",true)
    test_suite = Test::Unit::TestSuite.new("CTEDI Single Test Runner")
    test_class = class_name.constantize
    test_suite << test_class.new(test_name.downcase)
    Test::Unit::UI::Console::TestRunner.run(test_suite) 
  end

  ##############################################################################
  desc "cFlash CEDICT Diff Parse & Import"
  task :diff_import => :environment do
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    
    get_cli_debug

    # Get the name of the dictionary to diff
    prt "\nCEDICT Diff Parse (1) - Initial Difference file parsing"
    prt_dotted_line
    diff_parser = DiffParser.new(get_cli_attrib("file", true), "config.yml")
    line_hash = diff_parser.run

    # Get the base of the entire cards library.
    prt "\nCEDICT Diff Parse (2) - Get all the existing cards object from database"
    prt_dotted_line
    base = EntryCache.new.card_entries_array

    # We could search the DB and add these easily.
    prt "\nCEDICT Diff Parse (3) - Added line parsing"
    prt_dotted_line
    added_lines = line_hash[:added]
    added_parser = CEdictParser.new(added_lines)
    new_entries = added_parser.run
    prt "\nResult : %d line(s) has been added in the new file.\nNew base-entries: %d" % [added_lines.count, new_entries.count]

    added_obj_count = new_entries.count + added_parser.reference_only_entries.count + added_parser.variant_only_entries.count + added_parser.variant_entries.count + added_parser.erhua_variant_entries.count

    prt "\nCEDICT Diff Parse (4) - (Merge 'reference-only' Entries: %s reference, %s variant to the new entries)" % [added_parser.reference_only_entries.count, added_parser.variant_only_entries.count]
    prt_dotted_line    
    added_parser.merge_references_into_base_entries(new_entries, added_parser.reference_only_entries)
    added_parser.merge_references_into_base_entries(new_entries, added_parser.variant_only_entries)
    
    # These two are categorised as 'changed'/'updated'
    prt "\nCEDICT Diff Parse (5) - (Merge 'reference-only' Entries: %s reference, %s variant to the existing entries)" % [added_parser.reference_only_entries.count, added_parser.variant_only_entries.count]
    prt_dotted_line
    added_reference_entries = added_parser.merge_references_into_base_entries(base, added_parser.reference_only_entries)
    added_variant_entries = added_parser.merge_references_into_base_entries(base, added_parser.variant_only_entries)
    
    entries = new_entries + base
    prt "\nCEDICT DIff Parse (6) - (Cross-Referencing %d Variants to both existing entries and new entries)" % [added_parser.variant_entries.count]
    prt_dotted_line
    muxed_base_entries_with_new_variant = added_parser.add_variant_entries_into_base_entries(base, added_parser.variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.variant_entries)
    muxed_variant_entries = added_parser.add_base_entries_into_variant_entries(added_parser.variant_entries, entries)
    
    prt "\nCEDICT DIff Parse (7) - (Cross-Referencing %d Erhua Variants to both existing entries and new entries)" % [added_parser.erhua_variant_entries.count]
    prt_dotted_line
    muxed_base_entries_with_new_erhua = added_parser.add_variant_entries_into_base_entries(base, added_parser.erhua_variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.erhua_variant_entries)
    muxed_erhua_entries = added_parser.add_base_entries_into_variant_entries(added_parser.erhua_variant_entries, entries)
    
    # We could search the DB and remove these easily.
    prt "\nCEDICT Diff Parse (8) - Removed line parsing"
    prt_dotted_line
    removed_lines = line_hash[:removed]
    removed_parser = CEdictParser.new(removed_lines)
    removed_entries = removed_parser.run
    prt "\nResult : %d line(s) has been removed in the new file.\nRemoved base-entries: %d" % [removed_lines.count, removed_entries.count]
    
    ### On the removal of the reference, only check against the exisiting entries on the db. There is no need in checking to the base which gets removed (removed_entries),
    ### Because it gets removed anyway. This is a slightly different from the 'add' section above.
    prt "\nCEDICT Diff Parse (9) - (Un-Merge 'reference-only' Entries: %s reference, %s variant from the existing entries)" % [removed_parser.reference_only_entries.count, removed_parser.variant_only_entries.count]
    prt_dotted_line
    # These two are getting updated as well as the reference is unmerged
    removed_reference_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.reference_only_entries)
    removed_variant_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.variant_only_entries)

    prt "\nCEDICT Diff Parse (10) - (Cross-Referencing %d Variants and %d Erhua Variants to the existing entries for removal)" % [removed_parser.variant_entries.count, removed_parser.erhua_variant_entries.count]
    prt_dotted_line    
    # These two are getting updated cause somewhere in their meaning has changed, cause some of them is getting removed.
    muxed_base_entries_with_removed_variant = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.variant_entries)
    muxed_base_entries_with_removed_erhua = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.erhua_variant_entries)

    ## Actually cross reference between the removed and added. 
    ## If either one is crossed, meaning that they should be in 'changed' section.
    prt "\nCEDICT Diff Parse (11) - (Cross-Referencing %d Added base entries and %d Removed Base entries for changed-entries)" % [new_entries.count, removed_entries.count]   
    prt_dotted_line    
    updated_entries = diff_parser.cross_reference_added_and_removed(new_entries, removed_entries)
    prt "\nResult: %d has cross reference and put on the changed-entries section." % [updated_entries.count]
    
    ## These are added
    added = new_entries + muxed_variant_entries + muxed_erhua_entries
    
    ## These are changed
    changed = added_reference_entries + added_variant_entries + 
              removed_reference_entries + removed_variant_entries +
              muxed_base_entries_with_new_variant + muxed_base_entries_with_new_erhua +
              muxed_base_entries_with_removed_variant + muxed_base_entries_with_removed_erhua
    
    ## This are deleted
    removed = removed_entries + removed_parser.variant_only_entries + removed_parser.reference_only_entries + removed_parser.variant_entries + removed_parser.erhua_variant_entries

    prt "\nCEDICT Diff Parse (RESULT)\nAdded   : %d\nRemoved : %d\nUpdated : %d\n" % [added.count, removed.count, changed.count + updated_entries.count]
    prt_dotted_line
    #debugger
    
    ## Last Step would be write all of those result on a file
    diff_parser.update_data_with(added.count, (changed.count + updated_entries.count), removed.count)
    diff_parser.dump


  end

  ##############################################################################
  desc "cFlash CEDICT Parse & Import (First time only)"
  task :import => :environment do
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    
    get_cli_debug
    
    # Get the filename to load (the dictionary filename)
    full_path_importfile =  Rails.root.join("data/cedict/" + get_cli_attrib("file", true)).to_s
    
    # Parse
    prt "\nCEDICT Parse - Initial Flatfile Parse"
    prt_dotted_line
    parser = CEdictParser.new(full_path_importfile)
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
    muxed_base_entries = parser.add_variant_entries_into_base_entries(entries, parser.variant_entries)
    muxed_variant_entries = parser.add_base_entries_into_variant_entries(parser.variant_entries, entries)
    
    # Now combine the 3 types of entries -- they're all valid
    entries = entries + muxed_variant_entries + muxed_erhua_entries
    
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
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    
    get_cli_debug

    tag_name = get_cli_attrib("config_file")
    if tag_name.nil?
      tag_name = "cflash_group_config.yml"
    end

    # If the user passes anything to the dry_run CLI attrib, make it a dry run
    dry_run = (get_cli_attrib("dry_run").nil? == false)
    
    # Import groups and match tags within them
    prt "\nBeginning Group & Tag Import"
    prt_dotted_line
    GroupImporter.empty_staging_tables
    importer = GroupImporter.new(tag_name)
    importer.import(dry_run)
    
    prt "\nImport Finished"
    prt_dotted_line
  end

  ##############################################################################
  desc "cFlash SQLite Exporter"
  task :export => :environment do
    load Rails.root.join("lib/ctedilib/_includes.rb").to_s
    include RakeHelpers
    include DebugHelpers
    include DatabaseHelpers
    include ImporterHelpers

    exporter = CEdictExporter.new
    exporter.export_staging_db_from_table("cards_staging")
  end

end
#------------------------------------------------------------------------------------------------------------#
