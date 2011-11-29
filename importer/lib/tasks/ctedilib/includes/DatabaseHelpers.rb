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
  
  def last_inserted_id
    connect_db
    $cn.execute("SELECT LAST_INSERT_ID()").each do |last_id|
      return last_id[0]
    end
    return false
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
  
    # ACCEPTS: query options hash, block to process caching
  # RETURNS: hash of cached rows as set by block
  # REQUIRES: block to return a obj
  def cache_sql_query(options, &block)
    connect_db
    cache_data = {}
    cnt = 0
    options[:where].gsub!(/^WHERE/)
    options[:where] = (options[:where].length > 0 ? "WHERE #{options[:where]}": "")
    tickcount("Caching Query") do
      results = $cn.select_all("SELECT #{options[:select]} FROM #{options[:from]} #{options[:where]}")
      results.each do |sqlrow|
        block.call(sqlrow, cache_data)
        cnt = noisy_loop_counter(cnt, results.size)
      end
    end
    prt "Cached #{cnt} SQL records\n\n"
    return cache_data
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
