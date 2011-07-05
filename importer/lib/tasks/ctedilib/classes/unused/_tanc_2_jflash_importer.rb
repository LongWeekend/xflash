#### TANAKA CORPUS TO JFLASH IMPORTER #####
class Tanc2JFlashImporter < Importer

  # DESC: We don't call 'super' b/c our insertion flow is more complex (2 bulk importer objs!)
  def import

    # Empty tables are a requirement of this importer
    self.class.empty_staging_tables

    tickcount("Tanaka Corpus to JFlash Importer") do

      # If you do not have the reading column yet, you need to update your local database
      # reading VARCHAR 100 NULL
      $cn.execute("ALTER TABLE idx_sentences_by_keyword_staging ADD COLUMN reading VARCHAR(100) DEFAULT NULL;") if !mysql_col_exists("idx_sentences_by_keyword_staging.reading")

      # We are so kewl, we use two bulk importers at once!
      bulkSQL = BulkSQLRunner.new(@config[:data].size, @config[:data].size) ## Buffer for example sentence entries
      bulkSQLIdx = BulkSQLRunner.new(0, 50000) ## Buffer for keyword index entries
      @insert_keyword_sql = "INSERT INTO idx_sentences_by_keyword_staging (sentence_id, sense_number, segment_number, keyword, reading, keyword_type, checked) VALUES (%s, %s, %s, \'%s\', \'%s\', \'%s\', %s);"
      sql_loop_count = 0

      tickcount("Bulk inserting example sentences") do
        @config[:data].each do |rec|
          sql_loop_count = sql_loop_count+1
          bulkSQL.add("INSERT INTO sentences_staging (sentence_id, sentence_ja, sentence_en, checked, tanc_en_id, tanc_ja_id) VALUES (#{sql_loop_count}, \'#{mysql_escape_str(rec[:japanese])}\', \'#{mysql_escape_str(rec[:translated])}\', #{ (rec[:checked] ? 1:0) }, #{(rec[:tanc_en_id])},  #{(rec[:tanc_ja_id])});")
          segment_number = 0
          rec[:references].each do |r|
            segment_number = segment_number+1 ## identifies each segment of the sentence
            sense_number = (r[:sense_number] == "" ? "0" : r[:sense_number].to_i)
            checked = (r[:checked]? 1:0)
            bulkSQLIdx.add(@insert_keyword_sql % [sql_loop_count, sense_number, segment_number, mysql_escape_str(r[:index_word]), mysql_escape_str(r[:reading]), $options[:tanc_keyword_idx_types]['INDEX_WORD'], checked]) if r[:index_word] != ""
            ## MMA 8/7/2010 - we changed this implementation to put the reaading on the same row in the table, so idx_types can probably be removed in the future
            ### KEEPING THIS OUT FOR NOW ###  PCH 2010-06-12
            ### bulkSQLIdx.add(@insert_keyword_sql % [sql_loop_count, sense_number, segment_number, mysql_escape_str(r[:reading]), $options[:tanc_keyword_idx_types]['READING'], checked]) if r[:reading] != ""
            ### bulkSQLIdx.add(@insert_keyword_sql % [sql_loop_count, sense_number, segment_number, mysql_escape_str(r[:sentence_word]), $options[:tanc_keyword_idx_types]['SENTENCE_WORD'], checked]) if r[:sentence_word] != ""
          end
        end
      end

      tickcount("Bulk inserting card linkages") do
        bulkSQLIdx.flush
      end
    end

  end

  def self.empty_staging_tables
    connect_db
    prt "Removing all data from JFlash Import sentence staging tables (sentences_staging, idx_sentences_by_keyword_staging, card_sentence_link)"
    $cn.execute("TRUNCATE TABLE card_sentence_link")
    $cn.execute("TRUNCATE TABLE sentences_staging")
    $cn.execute("TRUNCATE TABLE idx_sentences_by_keyword_staging")
  end

  #### DESC: Creates index of sentences for JFlash/iPhone
  def self.create_jflash_index

    connect_db
    # Loop in blocks, so we get feedback between each query
    bulkSQL = BulkSQLRunner.new(0, 50000)
    
    tickcount("Inserting linkages into [card_sentence_link]") do
      prt "Be patient!"

      get_linkages_sql = "SELECT card_id, sentence_id, sense_number FROM cards_staging c JOIN idx_sentences_by_keyword_staging e ON e.keyword = c.headword WHERE ((c.reading = e.reading) OR e.reading = '')"
      $cn.execute(get_linkages_sql).each do | card_id, sentence_id, sense_number |
        bulkSQL.add("INSERT INTO card_sentence_link (card_id, sentence_id, sense_number) values (#{card_id}, #{sentence_id}, #{sense_number});")
      end

      # This is ghetto but it has to be this way because otherwise the query takes FOREVER
      get_linkages_sql = "SELECT card_id, sentence_id, sense_number FROM cards_staging c JOIN idx_sentences_by_keyword_staging e ON e.keyword = c.alt_headword WHERE ((c.reading = e.reading) OR e.reading = '')"
      $cn.execute(get_linkages_sql).each do | card_id, sentence_id, sense_number |
        bulkSQL.add("INSERT INTO card_sentence_link (card_id, sentence_id, sense_number) values (#{card_id}, #{sentence_id}, #{sense_number});")
      end
      
      bulkSQL.flush
    end
  end

  def self.pare_down_linkages
    connect_db

    prt "Updating checked values for card_tag_link..."

    # Add a should_show column if necessary - older versions of the database don't have this yet - eventually this will be dead code MMA 8/7/2010
    $cn.execute("ALTER TABLE card_sentence_link ADD COLUMN should_show TINYINT DEFAULT 1;") if !mysql_col_exists("card_sentence_link.should_show")

    # Add a checked column if necessary
    $cn.execute("ALTER TABLE card_sentence_link ADD COLUMN checked TINYINT DEFAULT 0;") if !mysql_col_exists("card_sentence_link.checked")
    $cn.execute("UPDATE card_sentence_link l, sentences_staging s SET l.checked = s.checked WHERE l.sentence_id = s.sentence_id")
    prt "Finished updating table with ckeced values"

    # Loop in blocks, so we get feedback between each query
    bulkSQL = BulkSQLRunner.new(0, 50000)
    
    # Now we have to make decisions about what to pare out and what to keep
    card_id_results = $cn.execute("SELECT card_id FROM card_sentence_link GROUP BY card_id")
    i = 0
    card_id_results.each do |card_rec|
      i = i + 1
      # init
      card_id = card_rec[0]
      total_count = 0
      checked_count = 0
      unchecked_count = 0

      # Get the sentence counts for each card
      results = $cn.execute("SELECT checked,count(sentence_id) as count FROM card_sentence_link WHERE card_id = %s GROUP BY checked" % card_id)
      results.each do |result|
        type = result[0].to_i
        count = result[1].to_i
        if (type == 0)
          unchecked_count = count
        else
          checked_count = count
        end
      end
      total_count = checked_count + unchecked_count

      # Tell me how we're doing
      if ((i % 5000) == 0) 
        prt "Looped through %s records" % i
      end

      # Now find out how many there are, only do something if more than 10
      if total_count > 10
        if checked_count > 10
          # That's a lot
          num_to_delete = total_count - unchecked_count - 10
          bulkSQL.add("UPDATE card_sentence_link SET should_show = 0 WHERE card_id = %s AND checked = 0;" % card_id)
          bulkSQL.add("UPDATE card_sentence_link SET should_show = 0 WHERE card_id = %s AND checked = 1 LIMIT %s;" % [card_id, num_to_delete.to_s]);
        elsif
          # Delete out some of the ones that are unchecked
          num_to_delete = total_count - (10 - checked_count)
          bulkSQL.add("UPDATE card_sentence_link SET should_show = 0 WHERE card_id = %s AND checked = 0 LIMIT %s;" % [card_id, num_to_delete.to_s]);
        end
      end  #if more than 10 sentences
    end  #card_id loop
    
    prt "Writing out SQL"
    bulkSQL.flush
    
    $cn.execute("ALTER TABLE card_sentence_link DROP COLUMN checked")
  end


  def self.export_staging_db

    connect_db
    sql_tmp_out_fn = "tmp_jflash_sqlite_dump.sql"
    File.delete(sql_tmp_out_fn) if File.exist?(sql_tmp_out_fn)

    prt "Exporting MYSQL staging data to Sqlite"
    prt_dotted_line

    # Reset target tables
    $cn.execute("DROP TABLE IF EXISTS sentences ")
    $cn.execute("CREATE TABLE sentences SELECT sentence_id, sentence_ja, sentence_en, checked FROM sentences_staging")

    prt "\n\nExporting tables to temporary file"
    prt_dotted_line

    mysql_dump_tables_via_cli(["sentences", "card_sentence_link"], sql_tmp_out_fn, $options[:mysql_name])
    mysql_to_sqlite_converter(sql_tmp_out_fn)

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS sentences;\\
    DROP TABLE IF EXISTS card_sentence_link;\\
    \\
    CREATE TABLE sentences (sentence_id INTEGER PRIMARY KEY  NOT NULL , sentence_ja TEXT, sentence_en TEXT, checked BOOL);\\
    CREATE TABLE card_sentence_link (card_id NOT NULL, sentence_id INTEGER NOT NULL, should_show INTEGER, sense_number INTEGER);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"EX_DB\", \"1.1\", \"Example Sentence Data\");\\
    \\
    DROP INDEX IF EXISTS card_sentence_link_card_id;\\
    CREATE INDEX card_sentence_link_card_id ON card_sentence_link(card_id ASC);\\
    \\
    DROP INDEX IF EXISTS card_sentence_link_sentence_id;\\
    CREATE INDEX card_sentence_link_sentence_id ON card_sentence_link(sentence_id ASC);\\
    \\
    DROP INDEX IF EXISTS card_sentence_link_should_show;\\
    CREATE INDEX card_sentence_link_should_show ON card_sentence_link(should_show ASC);\\
    \\
    END TRANSACTION;\\
    BEGIN TRANSACTION;\\
    \\"

    prepend_text_to_file(sqlite_prepare_db_statements, sql_tmp_out_fn)
    append_text_to_file("END TRANSACTION;", sql_tmp_out_fn)
    sqlite_run_file_via_cli(sql_tmp_out_fn, $options[:sqlite_file_path][:jflash_ex])
   # File.delete(sql_tmp_out_fn)

    # Reindex tables in Sqlite
    prt "Reindexing & Compacting SQLite file"
    prt_dotted_line
    sqlite_reindex_tables(["card_sentence_link", "sentences"], $options[:sqlite_file_path][:jflash_ex])
    sqlite_vacuum($options[:sqlite_file_path][:jflash_ex])

    prt "Done Exporting to Sqlite\n"

  end

end
