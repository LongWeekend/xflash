##################################################
# TEDI 3.0
# "An exercise in meta-programming!"
##################################################
#Features:
#	Rule based matching/scrubbing/extraction
#	Block timing
#	CLI feedback messages
#	Error logging to file
#	Counting / Analysis Modes
#	Bulk Inserts (via CLI)
#	Inline Inserts (via Ruby)
#	SQL command buffering (using iterators)
#	Storage of results by 
##################################################

load File.dirname(__FILE__) + "/tedilib3/_includes.rb"

namespace :tedi3 do

  include DatabaseHelpers
  include ImporterHelpers
  
  ##############################################################################
  desc "Run all unit tests"
  task :test_all => :environment do
    $options[:verbose] = false
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    Dir[File.dirname(__FILE__) +"/tedilib3/tests/_*.rb"].each do |file| 
      require file 
    end
    # Test Suite Runs automagically before exit!
  end

  ##############################################################################
  desc "Run all unit tests (REQUIRES: test=[lower case name of unit test])"
  task :test => :environment do
    $options[:verbose] = false
    get_cli_debug # Enable/disable debug 
    
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    # Add each test class here
    load File.dirname(__FILE__) + "/tedilib3/tests/_" + get_cli_attrib("class",true).gsub(/Test$/,"").downcase + ".rb"
    # Runs automagically before exit
    
  end

  ##############################################################################
  desc "Run all unit tests (REQUIRES: class=[case sensitive test class name] test=[test method name])"
  task :test_one => :environment do
    $options[:verbose] = false
    get_cli_debug # Enable/disable debug
    
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load File.dirname(__FILE__) + "/tedilib3/tests/_" + get_cli_attrib("class",true).gsub(/Test$/,"").downcase + ".rb"

    test_name = get_cli_attrib("test",true)
    class_name = get_cli_attrib("class",true)
    test_suite = Test::Unit::TestSuite.new("TEDi3 Single Test Runner")
    test_class = class_name.constantize
    test_suite << test_class.new(test_name.downcase)
    Test::Unit::UI::Console::TestRunner.run(test_suite) 
  end

  
  ##############################################################################
  desc "One Step jFlash Import (ACCEPTS: src=edict2_src_utf8.txt)"
  task :go_jflash => :environment do

    get_cli_debug # Enable/disable debug 

    prt "\n"
    prt_dotted_line
    prt "Running One Step jFlash Import"
    prt_dotted_line("\n")

=begin
    JFlashImporter.drop_export_tables
    JFlashImporter.empty_staging_tables

    # Import from source data files
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/#{get_cli_source_file} card_type=DICTIONARY --trace")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/ManuallyCompiledWordsEdictFormat.txt card_type=DICTIONARY --trace")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/ManuallyCompiledWordsEdictFormatAsWords.txt card_type=WORD --trace")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/KanaLists.txt card_type=KANA --trace")

    ## import JLPT words by headword only (only merges)
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-1.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt1")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-2.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt2")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-3.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt3")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-4.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt4")

    ## Try rematching left over JLPT words with old source file
    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-1.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-2.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-3.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-4.utf.txt_unmatched.txt src=jlpt_all_edict.txt")

    ## Now reimport JLPT rematches
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-1.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt1")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-2.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt2")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-3.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt3")
    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-4.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt4")
    JFlashImporter.humanise_inline_tags_in_table("cards_staging")
    # Match REL 1.0  to v 1.1 card ids
    system!("rake tedi3:match_rel1_ids reset=true")

    JFlashImporter.normalise_to_jflash_v1_ids
    JFlashImporter.add_jlpt_tags
    JFlashImporter.delete_child_tags                # cleans out any child links in tags_staging, tag_group_link
    JFlashImporter.add_tag_links                    # cleans card_tag_link first

    # DO NOT USE THIS ONE NOW
    # JFlashImporter.limit_tag_size                   # ASSUMES delete_child_tags has been called
    # USE THIS ONE INSTEAD
    JFlashImporter.create_size_limited_tags_based_on_rel1
=end    
    # Generate SQL queries to update the phone
    JFlashImporter.create_dead_card_id_sql("dead_card_ids.sql")
    JFlashImporter.create_card_tag_link_diff_sql("card_tag_link_diff.sql")
    JFlashImporter.create_tag_diff_sql("tag_diff.sql")
    JFlashImporter.normalise_to_jflash_v1_ids("cards_staging_humanised")
#    JFlashImporter.separate_romaji_readings
    JFlashImporter.export_staging_db_from_table("cards_staging_humanised")
  end

  
  ##############################################################################
  desc "Output files for phone"
  task :create_phone_sql => :environment do
    JFlashImporter.create_dead_card_id_sql("dead_card_id_sql.txt")
    JFlashImporter.create_card_tag_link_diff_sql("card_tag_link_diff.sql")
    JFlashImporter.create_tag_diff_sql("tag_diff_sql.txt")
  end

  ##############################################################################
  desc "Match jFlash REl 1.0 to staging IDs"
  task :match_rel1_ids => :environment do

    get_cli_debug # Enable/disable debug 
    num_recs = get_cli_attrib("num_recs")
    off_set = get_cli_attrib("off_set")
    debug_key = get_cli_attrib("debug_print_key")

    mig = JFlashMigration.new()
    mig.set_debug_print_key(debug_key) if debug_key
    mig.set_dry_run if get_cli_attrib("dry_run")

    JFlashMigration.remove_migration_results_table if get_cli_attrib("reset")

    if !off_set.nil? and !num_recs.nil?
      prt "\nStarting to merge #{num_recs} card_ids starting at record #{off_set}"
      prt_dotted_line("\n")
      mig.set_run_range(num_recs, off_set)
    end

    mig.run

  end
  ##############################################################################
  desc "Matches 1.1 tag IDs to 1.0 tag IDs - destructive!"
  task :match_rel1_tag_ids => :environment do
    get_cli_debug
    JFlashImporter.match_rel1_tag_ids
  end

  ##############################################################################
  desc "Dumps dead card IDs to a SQL file (ACCEPTS: output_filename=foo.sql)"
  task :create_dead_card_id_file => :environment do
    get_cli_debug
    fn = get_cli_attrib("output_filename")
    JFlashImporter.create_dead_card_id_sql(fn)
  end

  ##############################################################################
  desc "Diffs card_tag_link tables and dumps to SQL (ACCEPTS: output_filename=foo.sql)"
  task :create_card_tag_link_diff_file => :environment do
    get_cli_debug
    fn = get_cli_attrib("output_filename", true)
    JFlashImporter.create_card_tag_link_diff_sql(fn)
  end

  ##############################################################################
  desc "Diffs tag tables and dumps to SQL (ACCEPTS: output_filename=foo.sql)"
  task :create_tag_diff_file => :environment do
    get_cli_debug
    fn = get_cli_attrib("output_filename")
    JFlashImporter.create_tag_diff_sql(fn)
  end
  
  ##############################################################################
  desc "Collates entries from secondary file (ACCEPTS: umatched=jlpt-voc-4.utf.txt_unmatched.txt src=jlpt_all_edict.txt)"
  task :collate_umatched_jlpt => :environment do

    get_cli_debug # Enable/disable debug 

    new_fn = $options[:data_file_rel_path]+"/"+get_cli_source_file
    umatched_fn = $options[:data_file_rel_path]+"/"+get_cli_attrib("unmatched",true)

    prt "\nStarting to merge jlpt orphaned entries with secondary file"
    prt_dotted_line("\n")
    parser = Edict2Parser.new(umatched_fn)

    # Call custom run method to gather 'src' file entries from another file 'src2'
    parser.run_collate_unmatched_jlpt(new_fn, umatched_fn)

  end

  ##############################################################################
  desc "Tedi3 Tanaka Corpus to JFlash importer (ACCEPTS: src=tanc_examples20100523.utf.txt)"
  task :tanc2jflash => :environment do

    get_cli_debug # Enable/disable debug

    prt "\nRunning Tanaka Corpus Import"
    prt_dotted_line("\n")

#    Tanc2JFlashImporter.empty_staging_tables
#    results_data = TancParser.new($options[:data_file_rel_path] +"/"+ get_cli_source_file, get_cli_start_point, get_cli_break_point, get_cli_tags).run
#    importer = Tanc2JFlashImporter.new(results_data, $options[:card_types]['SENTENCE'])
#    importer.import
#    Tanc2JFlashImporter.create_jflash_index
    Tanc2JFlashImporter.pare_down_linkages
    Tanc2JFlashImporter.export_staging_db

  end

  ##############################################################################
  desc "Tedi3 Edict to JFlash Importer, ACCEPTS src={source file path} | from={start line} | to={max line} | card_type={WORD,DICTIONARY,KANA,KANJI}"
  task :edict2jflash => :environment do

    get_cli_debug # Enable/disable debug

    # Parse EDICT2 source file
    parser = Edict2Parser.new(get_cli_source_file, get_cli_start_point, get_cli_break_point, get_cli_tags)
    
    # Pass in the JFlash tag lists
    jflash_tags = JFlashImporter.get_existing_tags_by_type
    parser.set_tags(jflash_tags[:pos], jflash_tags[:cat], jflash_tags[:lang])

    parser.set_warning_level("IGNORE")
    results_data = parser.run

    importer = JFlashImporter.new(results_data, get_cli_card_type)
    importer.set_skip_empty_meanings(get_cli_attrib("skip_empty_meanings",false,true)) # Skip empty meanings
    ##  importer.set_sql_debug(true)
    importer.import
    
    ## Dump skipped entries to CON
    skipped = importer.get_skipped_meanings

    # UNCHECKED CODE: Log unmatchable JLPT words to text files
    skipped_txt = ""
    skipped.each do|s|
      skipped_txt = skipped_txt+"#{s[:headwords].first[:headword]} [#{s[:readings].first[:reading]}] /\n"
    end
    if skipped_txt != ""
      outf = File.open($options[:data_file_rel_path]+"/"+get_cli_source_file.split('/').last + "_unmatched.txt", 'w')
      outf.write(skipped_txt)
      outf.close
    end

  end
  
  ##############################################################################
  desc "Imports Kanjidic XML file into jFlash Staging Database (REQUIRES: kdic='data/kanjidic2_20100312.xml' krad='data/kradfile_combined_utf8.txt')"
  task :kanjidic2jflash => :environment do

    if !ENV.include?('kdic') || !ENV.include?('krad')
      prt "\n\nError, source files not found!\n"
      exit
    end

    kdic_importer = Kanjidic2JFlashImporter.new($options[:data_file_rel_path]+"/"+ENV['kdic'], $options[:data_file_rel_path]+"/"+ENV['krad'])
    kdic_importer.run
    
  end
  
  ##############################################################################
  desc "JMDict Importer (ACCEPTS: file=jmdict.xml)"
  task :jmdict => :environment do
  ##############################################################################

    # Enable/disable debug 
    get_cli_debug

    # Parse EDICT2 source file
    results_data = JMDictParser.new(get_cli_source_file).run

    # Cache exiting cards into hash
    existing_data = JFlashImporter.get_existing_entries
    
    # Cache existing tags in memory
    existing_tags = JFlashImporter.get_existing_tags

    ## Test Run Code 
    inner_loop_proc = Proc.new do |line|
      prt line + " (from inner loop)"
    end
    
    outer_loop_proc = Proc.new do |line, results| 
      prt line + " (from outer loop)"
      prt results.to_s
    end
    
    inner_chunking_proc = Proc.new do |line| 
      arr = line.split(' ')
      [arr[0], arr[1]]
    end
    
    sql_command_header = "headword,alt_headword,headword_en,reading,meaning,meaning_html,tags"
    Importer.new(results_data, sql_command_header, inner_loop_proc, outer_loop_proc, inner_chunking_proc).run
    
  end

end
#------------------------------------------------------------------------------------------------------------#
