##################################################
# CTEDI 1.0
##################################################

namespace :ctedi do
  
  ##############################################################################
  desc "Run all unit tests"
  task :test_all => :environment do
    load File.dirname(__FILE__) + "/ctedilib/_options.rb"
    load File.dirname(__FILE__) + "/ctedilib/_modules.rb"
    load File.dirname(__FILE__) + "/ctedilib/_additions.rb"
    load File.dirname(__FILE__) + "/ctedilib/_includes.rb"
    $options[:verbose] = false
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    Dir[File.dirname(__FILE__) +"/ctedilib/tests/*.rb"].each do |file| 
      require file 
    end
    # Test Suite Runs automagically before exit!
  end

  ##############################################################################
  desc "Run all tests in one test file (REQUIRES: class=TestClassName (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_class => :environment do
    load File.dirname(__FILE__) + "/ctedilib/_options.rb"
    load File.dirname(__FILE__) + "/ctedilib/_modules.rb"
    load File.dirname(__FILE__) + "/ctedilib/_additions.rb"
    load File.dirname(__FILE__) + "/ctedilib/_includes.rb"
    $options[:verbose] = false
    get_cli_debug # Enable/disable debug 
    
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    # Add each test class here
    load File.dirname(__FILE__) + "/ctedilib/tests/" + get_cli_attrib("class",true) + ".rb"
    # Runs automagically before exit
    
  end

  ##############################################################################
  desc "Run specific unit test (REQUIRES: class=TestClassName test=method_to_test) (note: if your test class includes 'Test' at the end, you need it here!))"
  task :test_one => :environment do
    load File.dirname(__FILE__) + "/ctedilib/_options.rb"
    load File.dirname(__FILE__) + "/ctedilib/_modules.rb"
    load File.dirname(__FILE__) + "/ctedilib/_additions.rb"
    load File.dirname(__FILE__) + "/ctedilib/_includes.rb"
    $options[:verbose] = false
    get_cli_debug # Enable/disable debug
    
    require 'test/unit'
    require 'test/unit/ui/console/testrunner'
    load File.dirname(__FILE__) + "/ctedilib/tests/" + get_cli_attrib("class",true) + ".rb"

    test_name = get_cli_attrib("test",true)
    class_name = get_cli_attrib("class",true)
    test_suite = Test::Unit::TestSuite.new("CTEDI Single Test Runner")
    test_class = class_name.constantize
    test_suite << test_class.new(test_name.downcase)
    Test::Unit::UI::Console::TestRunner.run(test_suite) 
  end

  
  ##############################################################################
  desc "One Step cFlash Import (ACCEPTS: src=edict2_src_utf8.txt)"
  task :go_cflash => :environment do

    get_cli_debug # Enable/disable debug 

    prt "\n"
    prt_dotted_line
    prt "Running One Step Import"
    prt_dotted_line("\n")

    exporter = CEdictExporter.new
    importer = CEdictImporter.new
    exporter.drop_export_tables
    importer.empty_staging_tables

    # Import from source data files
#    system!("rake ctedi:edict2jflash src=#{$options[:data_file_rel_path]}/#{get_cli_source_file} card_type=DICTIONARY --trace")
#    system!("rake ctedi:edict2jflash src=#{$options[:data_file_rel_path]}/ManuallyCompiledWordsEdictFormat.txt card_type=DICTIONARY --trace")
#    system!("rake ctedi:edict2jflash src=#{$options[:data_file_rel_path]}/ManuallyCompiledWordsEdictFormatAsWords.txt card_type=WORD --trace")
#    system!("rake ctedi:edict2jflash src=#{$options[:data_file_rel_path]}/KanaLists.txt card_type=KANA --trace")

    ## import JLPT words by headword only (only merges)
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-1.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt1")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-2.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt2")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-3.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt3")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-4.utf.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt4")

    ## Try rematching left over JLPT words with old source file
#    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-1.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
#    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-2.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
#    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-3.utf.txt_unmatched.txt src=jlpt_all_edict.txt")
#    system!("rake tedi3:collate_umatched_jlpt unmatched=jlpt-voc-4.utf.txt_unmatched.txt src=jlpt_all_edict.txt")

    ## Now reimport JLPT rematches
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-1.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt1")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-2.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt2")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-3.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt3")
#    system!("rake tedi3:edict2jflash src=#{$options[:data_file_rel_path]}/jlpt-voc-4.utf.txt_rematched.txt card_type=DICTIONARY skip_empty_meanings=true add_tags=jlpt4")

#    JFlashImporter.humanise_inline_tags_in_table("cards_staging")
    # Match REL 1.0  to v 1.1 card ids
#    system!("rake tedi3:match_rel1_ids reset=true")

#    CFlashImporter.add_jlpt_tags
#    CFlashImporter.delete_child_tags                # cleans out any child links in tags_staging, tag_group_link
#    CFlashImporter.add_tag_links                    # cleans card_tag_link first

    exporter.export_staging_db_from_table("cards_staging")
  end

  

  ##############################################################################
  desc "CEdict Parser/Importer, ACCEPTS src={source file path} | from={start line} | to={max line} | card_type={WORD,DICTIONARY,KANA,KANJI}"
  task :parse_cedict_file => :environment do
    load File.dirname(__FILE__) + "/ctedilib/_includes.rb"

    get_cli_debug # Enable/disable debug

    # Parse EDICT source file
    parser = CEdictParser.new(get_cli_source_file, get_cli_start_point, get_cli_break_point, get_cli_tags)
    
    # Pass in the JFlash tag lists
#    jflash_tags = JFlashImporter.get_existing_tags_by_type
#    parser.set_tags(jflash_tags[:pos], jflash_tags[:cat], jflash_tags[:lang])

#    parser.set_warning_level("IGNORE")
    results_data = parser.run

    importer = CFlashImporter.new(results_data, get_cli_card_type)
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
  
end
#------------------------------------------------------------------------------------------------------------#
