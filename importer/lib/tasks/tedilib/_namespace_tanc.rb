#----------------------------------------------------------------------------#
#  Tanaka Corpus NameSpace
#----------------------------------------------------------------------------#
namespace :tanc do
  
  desc "Tanaka Corpus Importer, ACCEPTS src={source file path} | from={start line} | to={max line}"
  task :import => :environment do
    load_library(true)
    empty_tables if get_cli_empty_tables
    results = process_tanc("extract", get_cli_start_point, get_cli_break_point)
    import_tanc_data(results[:data])
  end

  namespace :analyse do
    desc "Tanaka Corpus Multipurpose Line Scanner: counts and displays matched lines, ACCEPTS rex=\"/{your regex}/\" | rex=\"{your string}\""
    task :scan => :environment do
      load_library
      @counted = scan_source_file("tanc")
      puts "---------------------------------------------------"
      puts "counted: " + @counted.to_s
    end
  end

end
#----------------------------------------------------------------------------#
