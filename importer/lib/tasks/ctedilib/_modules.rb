#------------------------------------------------------------------------------------------------------------#
#  888b     d888               888          888                   
#  8888b   d8888               888          888                   
#  88888b.d88888               888          888                   
#  888Y88888P888  .d88b.   .d88888 888  888 888  .d88b.  .d8888b  
#  888 Y888P 888 d88""88b d88" 888 888  888 888 d8P  Y8b 88K      
#  888  Y8P  888 888  888 888  888 888  888 888 88888888 "Y8888b. 
#  888   "   888 Y88..88P Y88b 888 Y88b 888 888 Y8b.          X88 
#  888       888  "Y88P"   "Y88888  "Y88888 888  "Y8888   88888P'
#------------------------------------------------------------------------------------------------------------#

#### DATABASE HELPER MODULE #####
module DatabaseHelpers

  # Create connection to DB in instance scope
  def connect_db
    breakpoint
    if !$cn
      ActiveRecord::Base.establish_connection (
         :adapter  => :mysql2,
         :database => $options[:mysql_name],
         :port     => $options[:mysql_port],
         :host     => $options[:mysql_host],
         :encoding => "utf8",
         :username => $options[:mysql_username],
         :password => $options[:mysql_password]
       )
       $cn = ActiveRecord::Base.connection()
    end
  end
  
  def get_random_filename
    # Create a random file name
    s = ""
    7.times { s << (65 + rand(26))  }
    "tedi3_" + s + ".sql"
  end

  def write_text_to_tmp_file(txt_blob)
    sql_tmp_fn = get_random_filename
    sql_tmp_file = File.open(sql_tmp_fn, 'w')
    sql_tmp_file.write(txt_blob)
    sql_tmp_file.close
    return sql_tmp_fn
  end

  def mysql_escape_str(txt)
    txt.gsub("'" , '\\\\\'')
  end
  
  # Return serialized object 
  def mysql_serialise_ruby_object(obj)
    return Base64.encode64(Marshal.dump(obj))
  end

  # Return original object 
  def mysql_deserialise_ruby_object(obj)
    return Marshal.load(Base64.decode64(obj))
  end

  def mysql_run_query_via_cli(txt_blob, db=$options[:mysql_name], username=$options[:mysql_username], pw=$options[:mysql_password])
    sql_tmp_fn = write_text_to_tmp_file(txt_blob)

    pw = (pw.size > 1 ? "-p #{pw} " : "")
    if username.nil?
      username = "-u root "
    else
      username = "-u #{username} "
    end

    # Run mysql from command line!
    prt "==== Opening Command Line ====\n" if $options[:verbose]
    cmd = "mysql -h localhost #{username} #{pw}--default_character_set utf8 #{db} < #{sql_tmp_fn}"
    prt "Executing: #{cmd}"
    if (!system(cmd))
      # Throw an exception here
      raise "MySQL returned an error message, I am throwing an exception"
    else
      # Delete tmp file
      File.delete(sql_tmp_fn)
    end

    prt "\n\n"
  end
  
  # Write text to file and run mysql from command line!
  def sqlite_run_query_via_cli(text_blob, dbfilepath)
    sql_tmp_fn = write_text_to_tmp_file(text_blob)
    sqlite_run_file_via_cli(sql_tmp_fn, dbfilepath)
    File.delete(sql_tmp_fn) # Delete tmp file
  end

  # Run existing sql file from command line!
  def sqlite_run_file_via_cli(filename, dbfilepath)
     prt "==== Opening Command Line ====\n" if $options[:verbose]
     cmd =  "#{$options[:sqlite_bin]} \"#{dbfilepath}\" < #{filename}"
     prt "Executing: #{cmd}"
     system(cmd)
     prt "\n\n"
  end
  
  # REINDEX
  def sqlite_reindex_tables(table_name_arr, dbfilepath)
    prt "==== Opening Command Line ====\n" if $options[:verbose]
    table_name_arr.each do |table|
      `#{$options[:sqlite_bin]} "#{dbfilepath}" 'REINDEX #{table};'`
    end
  end

  # VACUUM
  def sqlite_vacuum(dbfilepath)
    prt "==== Opening Command Line ====\n" if $options[:verbose]
    `#{$options[:sqlite_bin]} "#{dbfilepath}" 'VACUUM;'`
  end

  #
  # mysql_table_exists
  #
  def mysql_table_exists(table)
    return !$cn.select_one("SHOW TABLES LIKE '#{table}'").nil?
  end

  #
  # mysql_col_exists
  #
  def mysql_col_exists(table_col_str)
    tmp = table_col_str.split('.')
    table = tmp[0]
    col = tmp[1]
    return !$cn.select_one("SHOW COLUMNS FROM #{table} WHERE Field = '#{col}'").nil?
  end

  #
  # mysql_dump_tables_via_cli
  #
  def mysql_dump_tables_via_cli(table_array, tmp_outfile_sql, dbname)
    `mysqldump -uroot --compact --complete-insert --skip-quote-names --skip-extended-insert --no-create-info #{dbname} #{table_array.join(' ')} > #{tmp_outfile_sql}`
  end

  #
  # mysql_to_sqlite_converter
  #
  def mysql_to_sqlite_converter(filename)
    # Converts mysql escaped single quotes to sqlite escape single quotes using SED
    system!("sed \"s/\\\\\\'/\\'\\'/g\" #{filename} > #{filename}.2")
    system!("sed \'s/\\\\\\\"/\"/g\' #{filename}.2 > #{filename}.3")
    `cp #{filename}.3 #{filename}`
    File.delete("#{filename}.2")
    File.delete("#{filename}.3")
  end

  def empty_tables
    connect_db
    tickcount("Deleting old data (collections/scraps/revisions/taggings/tags/scrap_pages)") do
      $cn.execute("TRUNCATE TABLE collections")
      $cn.execute("TRUNCATE TABLE batch_jobs")
      $cn.execute("TRUNCATE TABLE scraps")
      $cn.execute("TRUNCATE TABLE revisions")
      $cn.execute("TRUNCATE TABLE taggings")
      $cn.execute("TRUNCATE TABLE links")
    end
    return true
  end

  def delete_incomplete(table)
    connect_db
    $cn.execute("DELETE FROM #{table} WHERE import_status <> #{$options[:statuses]["completed"]} and import_status <> #{$options[:statuses]["not_imported"]}")
    prt "Deleted incomplete import items from #{table}" if $options[:verbose]
    return true
  end

  def disable_keys(table)
    connect_db
    $cn.execute("ALTER TABLE #{table} DISABLE KEYS")
    return true
  end

  def enable_keys(table)
    connect_db
    $cn.execute("ALTER TABLE #{table} DISABLE KEYS")
  end

  def commit_imported_recs(table, import_id)
    $cn.execute("UPDATE #{table} SET import_status = #{$options[:statuses]["completed"]} WHERE import_status = #{$options[:statuses]["inserted"]} AND import_batch_id = #{import_id}")
  end

end

#### IMPORTER HELPER MODULE #####
module ImporterHelpers
  
  def get_pinyin_unicode_for_reading(readings="")
    ## TODO: Think about the tone-5
    ## http://en.wikipedia.org/wiki/Pinyin#Tones  
    # Only runs if the reading actually has something
    if (readings.strip().length() > 0)
      # Variable to persist the final result.
      result = ""
      # Loop through the individual readings.
      readings.split($delimiters[:cflash_readings]).each do | reading |
        
        # Just to get the tone in string (even if it should be a number)
        tone = ""
        tone << reading.slice(reading.length()-1)
        
        if (tone.match($regexes[:pinyin_tone]))
          found_diacritic = false
          # Get the reading without the number (tone)
          reading = reading.slice(0, reading.length()-1)
          
          vocals = reading.scan($regexes[:vocal])
          num_of_vocal = vocals.length
           
          vocal = ""
          if (num_of_vocal == 1)
            # Take the vocal, directly if there is only 1 vocal.
            vocal = vocals[0]
          else
            vocal = reading.scan($regexes[:diacritic_vowel1])[0]
            
            vocal = reading.scan($regexes[:diacritic_vowel2])[0] unless vocal
            if (vocal)
              # Get the "o" in the 'ou' scan.
              vocal = vocal[0].chr()
            end
            
            # If everything else fails, get the second vocal.
            vocal = vocals[1] unless vocal
          end
          
          if ((vocal) && (vocal.strip().length() > 0))
            diacritic = get_unicode_for_diacritic(vocal, tone)
            result << reading.sub(vocal, diacritic)
          end                    
        else
          # Give the feedback if we dont know what to do
          # This should be a very rare cases. (Throw an exception maybe?)
          puts "There is no tone: %s defined for pinyin reading" % tone
        end
      end
      return result
    end

    # Back with nothing if there is no reading supplied
    return ""
  end
  
  def get_unicode_for_diacritic(vocal, tone)
    the_vocal_sym = (vocal + tone).to_sym()
    return [$chinese_reading_unicode[the_vocal_sym]].pack('U*')
  end
  
  def fix_unicode_for_tone_3(pinyin)
    # GSUB accepts hashes on Ruby 1.9 but not 1.8.  We have it categorized in in additions as hash_gsub
    return pinyin.hash_gsub(/[ăĕĭŏŭ]/,{'ă'=>'ǎ','ĕ'=>'ě','ĭ'=>'ǐ','ŏ'=>'ǒ','ŭ'=>'ǔ'})
  end

  def prt_dotted_line(txt="")
    prt "---------------------------------------------------------------------#{txt}"
  end
  
  # <cf_style>Rockin it!</cf_style> - count run time of  bounded block and output it
  def tickcount(id="", verbose=$options[:verbose], tracking=false)
    from = Time.now
    prt "\nSTART: " + (id =="" ? "Anonymous Block" : id) + "\n" if verbose
    yield
    to = Time.now
    # track time stats?
    if tracking
      $ticks = {} if !$ticks
      if !$ticks[id]
        $ticks[id] = {}
        $ticks[id][:times] = 1
        $ticks[id][:total] = Float(to-from)
      else
        $ticks[id][:times] = $ticks[id][:times] + 1
        $ticks[id][:total] = ( ($ticks[id][:total] + Float(to-from)) / $ticks[id][:times] )
      end
      $ticks[id][:last] = {:from => from, :to => to}
    end
    if verbose
      prt "END: " + (id =="" ? "Anonymous Block" : id) + " time taken: #{(to-from).to_s} s"
      prt_dotted_line
    end
    return true
  end
  
  # Sourced from ThinkingSphinx pluing by Pat Allan (http://freelancing-god.github.com)
  # A fail-fast and helpful version of "system"
  def system!(cmd)
    unless system(cmd)
      raise <<-SYSTEM_CALL_FAILED
  The following command failed:
    #{cmd}

  This could be caused by a PATH issue in the environment of Ruby.
  Your current PATH:
    #{ENV['PATH']}
SYSTEM_CALL_FAILED
    end
  end

  ## Append text to file using sed
  def append_text_to_file(text, filename)
    `sed -e '$a\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end

  ## Prepend text to file using sed
  def prepend_text_to_file(text, filename)
    `sed -e '1i\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end

  # "puts" clone that outputs nothing when verbose mode is false!
  def prt(str)
    puts(str) if $options[:verbose]
  end

  # exit quickly
  def ex
    exit
  end
  
  # Removes string and any duplicate spaces
  def replace_no_gaps(str, replace, with)
    return str.gsub(replace, with).gsub(/ +/, ' ').strip
  end

  def exit_with_error(error, dump_me=nil)
    puts "ERROR! " + error
    pp dump_me if dump_me
    exit
  end
  
  # Fetch "to" command line or set to default
  def get_cli_break_point
    if ENV.include?("to") && ENV['to'] && ENV['to'].to_i > 0
      return ENV['to'].to_i
    else
      return $options[:default_break_point]
    end
  end

  # Empty tables or not
  def get_cli_empty_tables
    return ( ENV.include?("kill") && ENV['kill'] )
  end

  # Silent or Not
  def get_silent
    return ( ENV.include?("silent") && ENV['silent'] )
  end

  # Fetch "start" from command line or set to default
  def get_cli_start_point
    if ENV.include?("from") && ENV['from'] && ENV['from'].to_i > 0
      return ENV['from'].to_i
    else
      return 1
    end
  end

  # Fetch "type" from command line or set to default
  def get_cli_type
    if ENV.include?("type") && ENV['type']
      return ENV['type'].to_s
    else
      return ""
    end
  end

  # Fetch "force" command from or set default
  def get_cli_forced
    if ENV.include?("force") && ENV['force']
      return true
    else
      return false
    end
  end

  # Fetch regex from command line or set to default
  def get_cli_regex
    if ENV.include?("rex")
      if ENV['rex'].scan(/\/.+\//)
        rex = Regexp.new ENV['rex'].scan(/\/(.+)\//).to_s
      else
        rex = ENV['rex']
      end
    else
      rex = $regexes[:antonym]
    end
    return rex
  end

  # Get debug directive from command line
  def get_cli_debug
    if ENV.include?("debug")
      if ENV["debug"] == "false" || ENV["debug"] == "0"
        $options[:verbose] = false
      else
        $options[:verbose] = true
      end
    else
      # default is on!
      $options[:verbose] = true
    end
  end

  # Get card type from command line
  def get_cli_card_type
    if ENV.include?("card_type") && ENV['card_type']
      card_type = $options[:card_types][ENV['card_type'].upcase]
      if card_type.nil?
        puts "Error, card type not recognised! See source for valid card types."
        exit
      end
    else
      card_type = $options[:card_types]['DICTIONARY']
    end
    return card_type.to_i
  end

  # Get extra tags specified at the command line
  def get_cli_tags
    if ENV.include?("add_tags") && ENV['add_tags']
      return ENV['add_tags'].downcase.split(',').collect {|s| s.strip }
    else
      return nil
    end
  end
  
  # Loop counter to count aloud for you!
  def noisy_loop_counter(count, max=0, every=1000, item_name="records", atomicity=1)
    count +=1
    if count % every == 0 || (max > 0 && count == max)
      prt "Looped #{count/atomicity} #{item_name}" if count%atomicity == 0 ## display count based on atomicity
    end
    return count
  end

  # Returns source file name specified at CLI or dies with error
  def get_cli_source_file
    if !ENV.include?("src") || ENV['src'].size < 1
      exit_with_error("Source file not found.", ENV)
    else
      return ENV['src'].to_s
    end
  end

  # Returns specified attrib from command, dies with error if fail_if_undefined == true
  def get_cli_attrib(attrib, fail_if_undefined=false, bool=false)
    if ENV.include?(attrib)
      if bool
        return (ENV[attrib] ==0 || ENV[attrib] == "true" ? true : false)
      else
        return ENV[attrib]
      end
    elsif fail_if_undefined
      exit_with_error("Command line attribute not found #{attrib} !", ENV) if fail_if_undefined
    end
  end

end