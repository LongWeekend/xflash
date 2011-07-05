#-----------------------------------------------------------------------------------------------------#
#  JFlash NameSpace
#  DESC: Creates tag links in LWE format from words already imported into 'cards_staging'
#-----------------------------------------------------------------------------------------------------#

# REQUIRES:
# kradfile ... http://www.csse.monash.edu.au/~jwb/kradinf.html
# kanjidic ... http://www.csse.monash.edu.au/~jwb/kanjidic_doc.html
# juman ... http://www433.elec.ryukoku.ac.jp/~yokomizo/ntool/install.html
# CLI: 'iconv' & 'sed'
# RUBY: 'nokogiri'

namespace :jflash do

  ### CONFIGURATION OPTIONS ###
  @@staging_db_name = "jflash_import"
  ##@@sqlite_bin = "/usr/bin/sqlite3"    ### This Sqlite version does not have FTS Module compiled by default
  @@sqlite_bin = "~/sqlite-3.6.21/sqlite3"  ###
  @@jflash_db_file_loc = "/Users/pchapman/Documents/Long Weekend Design/jFlashXcodeBranch/sql/jFlash.db"
  @@MAX_CARDS_PER_TAG = 10000
  ### CONFIGURATION OPTIONS ###

  # Card type definitions, taken from jFlash Source Code
  # NB: in jFlash these constants prepended with 'CARD_TYPE_'
  @@card_types = {
    'WORD' => 0,
    'KANA' => 1,
    'KANJI' => 2,
    'DICTIONARY' => 3,
    'SENTENCE' => 4
  }

  # System Tag IDs
  @@SYSTEM_TAGS = { 
    'LWE_FAVORITES' => 124,
    'BAD_DATA' => 160
  }

  ##############################################################################
  desc "jFlash Task: Run Batch Import (ACCEPTS: file=edict2_src_utf8.txt )"
  task :go => :environment do
    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)
    tmp_outfile_sql = "tmp_jflash_sqlite_dump.sql"

    if ENV.include?("file") && ENV['file'].size > 0
      puts "Running jFlash Rake Import Tasks"
      puts "------------------------------------\n\n"
      system!("rake jflash:empty_tables")
      system!("rake jflash:import src=./data/jflash_import_words/#{ENV['file']} merge_similar=false")
      system!("rake jflash:import src=./data/jflash_import_words/ManuallyCompiledWordsEdictFormat.txt card_type=DICTIONARY merge_similar=true")
      system!("rake jflash:import src=./data/jflash_import_words/KanaLists.txt card_type=KANA merge_similar=false")
      system!("rake jflash:import src=./data/jflash_import_words/jlpt1_edict.txt card_type=DICTIONARY add_tags=jlpt1 merge_similar=true")
      system!("rake jflash:import src=./data/jflash_import_words/jlpt2_edict.txt card_type=DICTIONARY add_tags=jlpt2 merge_similar=true")
      system!("rake jflash:import src=./data/jflash_import_words/jlpt3_edict.txt card_type=DICTIONARY add_tags=jlpt3 merge_similar=true")
      system!("rake jflash:import src=./data/jflash_import_words/jlpt4_edict.txt card_type=DICTIONARY add_tags=jlpt4 merge_similar=true")
      system!("rake jflash:jlpt_tags")
      system!("rake jflash:clean_edict_readings")
      system!("rake jflash:add_tags")
      system!("rake jflash:limit_set_size")
      system!("rake jflash:add_romaji")
      system!("rake jflash:export")
    else
      puts "\nSpecify an EDICT2 source file to import using file=xxxx, to !\n\n"
    end

  end
  
  ##############################################################################
  desc "jFlash Task: Export to Sqlite"
  task :export => :environment do

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)
    tmp_outfile_sql = "tmp_jflash_sqlite_dump.sql"
    
    puts "Copy staging tables for export to Sqlite"
    puts "------------------------------------\n\n"

    ## Drop previously created intermediate tables
    @cn.execute("DROP TABLE IF EXISTS cards")
    @cn.execute("DROP TABLE IF EXISTS cards_html")
    @cn.execute("DROP TABLE IF EXISTS tags")
    @cn.execute("DROP TABLE IF EXISTS groups")
    @cn.execute("DROP TABLE IF EXISTS cards_search_content")

    @cn.execute("UPDATE cards_staging SET meaning_html = meaning WHERE meaning_html IS NULL")

    ## Code for updating group tag_count column here, exclude invisible tags
    @cn.execute("UPDATE groups_staging SET tag_count = 0")
    @cn.execute("SELECT count(g.group_id) as cnt, g.group_id FROM groups_staging g, group_tag_link l, tags_staging t WHERE t.tag_id = l.tag_id AND t.visible = 1 AND t.force_off = 0 AND g.group_id = l.group_id GROUP BY g.group_id").each do | cnt, group_id |
      @cn.execute("UPDATE groups_staging SET tag_count = #{cnt} WHERE group_id = #{group_id}")
    end

    ## Create new intermediate tables
    @cn.execute("CREATE TABLE cards SELECT * FROM cards_staging")
    @cn.execute("CREATE TABLE tags SELECT * FROM tags_staging")
    @cn.execute("CREATE TABLE groups SELECT * FROM groups_staging")
    @cn.execute("CREATE TABLE cards_search_content SELECT * FROM cards_staging")
    @cn.execute("CREATE TABLE cards_html SELECT * FROM cards_staging")

    ## Drop unnecessary cols from intermediate table
    @cn.execute("ALTER TABLE cards DROP alt_headword")
    @cn.execute("ALTER TABLE cards DROP meaning")
    @cn.execute("ALTER TABLE cards DROP meaning_html")
    @cn.execute("ALTER TABLE cards DROP meaning_fts")
    @cn.execute("ALTER TABLE cards DROP tags")
    @cn.execute("ALTER TABLE cards DROP ptag")

    ## Drop unnecessary cols from intermediate table
    @cn.execute("ALTER TABLE cards_html DROP card_type")
    @cn.execute("ALTER TABLE cards_html DROP headword")
    @cn.execute("ALTER TABLE cards_html DROP alt_headword")
    @cn.execute("ALTER TABLE cards_html DROP headword_en")
    @cn.execute("ALTER TABLE cards_html DROP reading")
    @cn.execute("ALTER TABLE cards_html DROP romaji")
    @cn.execute("ALTER TABLE cards_html DROP meaning")
    @cn.execute("ALTER TABLE cards_html DROP meaning_fts")
    @cn.execute("ALTER TABLE cards_html DROP tags")
    @cn.execute("ALTER TABLE cards_html DROP ptag")

    @cn.execute("ALTER TABLE cards_html CHANGE COLUMN meaning_html meaning varchar(5000)")
    @cn.execute("ALTER TABLE cards_search_content ADD COLUMN content varchar(5000)")
    @cn.execute("UPDATE cards_search_content SET content = CONCAT(headword, ' [ ', reading, ' / ', romaji, ' / ',  REPLACE(romaji, \" \", \"\"),' ] ', meaning_fts);")

    ## Drop unnecessary cols from intermediate table
    @cn.execute("ALTER TABLE cards_search_content DROP card_type")
    @cn.execute("ALTER TABLE cards_search_content DROP headword")
    @cn.execute("ALTER TABLE cards_search_content DROP alt_headword")
    @cn.execute("ALTER TABLE cards_search_content DROP headword_en")
    @cn.execute("ALTER TABLE cards_search_content DROP reading")
    @cn.execute("ALTER TABLE cards_search_content DROP romaji")
    @cn.execute("ALTER TABLE cards_search_content DROP meaning")
    @cn.execute("ALTER TABLE cards_search_content DROP meaning_html")
    @cn.execute("ALTER TABLE cards_search_content DROP meaning_fts")
    @cn.execute("ALTER TABLE cards_search_content DROP tags")

    # Remove non-visible tags
    @cn.execute("DELETE FROM tags WHERE visible=0 OR force_off=1")

    ## Drop unnecessary cols from intermediate table
    @cn.execute("ALTER TABLE tags DROP force_off")
    @cn.execute("ALTER TABLE tags DROP source_name")
    @cn.execute("ALTER TABLE tags DROP short_name")
    @cn.execute("ALTER TABLE tags DROP source")
    @cn.execute("ALTER TABLE tags DROP parent_tag")
    @cn.execute("ALTER TABLE tags CHANGE COLUMN visible editable int(11)")
    @cn.execute("UPDATE tags SET editable = 0 WHERE tag_id <> #{@@SYSTEM_TAGS['BAD_DATA']} AND tag_id <> #{@@SYSTEM_TAGS['LWE_FAVORITES']}")

    puts "\n\nExporting tables to temporary file"
    puts "------------------------------------\n\n"
    File.delete(tmp_outfile_sql) if File.exist?(tmp_outfile_sql) # delete old tmp files

    # Dump with as little extra crap as possible!
    `mysqldump -uroot --compact --complete-insert --skip-quote-names --skip-extended-insert --no-create-info #{@@staging_db_name} cards cards_html tags groups card_tag_link group_tag_link cards_search_content > #{tmp_outfile_sql}` # dump tables to file

    puts "Cleaning up temporary file for sqlite compatibility"
    puts "----------------------------------------------------\n\n"

    # Replace \' with '' and  \" with " (Sqlite escape sequence) - using system!() b/c backticks caused issues!
    system!("sed \"s/\\\\\\'/\\'\\'/g\" #{tmp_outfile_sql} > #{tmp_outfile_sql}.2")
    system!("sed \'s/\\\\\\\"/\"/g\' #{tmp_outfile_sql}.2 > #{tmp_outfile_sql}.3")

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS card_tag_link;\\
    CREATE TABLE card_tag_link (tag_id INTEGER,	card_id INTEGER, id INTEGER);\\
    \\
    DROP TABLE IF EXISTS cards;\\
    CREATE TABLE cards (card_id INTEGER PRIMARY KEY, card_type TEXT, headword TEXT, headword_en TEXT, reading TEXT, romaji TEXT);\\
    \\
    DROP TABLE IF EXISTS cards_html;\\
    CREATE TABLE cards_html (card_id INTEGER PRIMARY KEY, meaning TEXT);\\
    \\
    DROP TABLE IF EXISTS cards_search_content;\\
    CREATE VIRTUAL TABLE cards_search_content using FTS3(card_id, content, ptag INTEGER NOT NULL DEFAULT 0);\\
    \\
    DROP TABLE IF EXISTS group_tag_link;\\
    CREATE TABLE group_tag_link (group_id INTEGER NOT NULL , tag_id INTEGER NOT NULL );\\
    \\
    DROP TABLE IF EXISTS groups;\\
    CREATE TABLE groups (group_id INTEGER PRIMARY KEY NOT NULL, group_name VARCHAR NOT NULL,owner_id INTEGER NOT NULL  DEFAULT 0, tag_count INTEGER NOT NULL  DEFAULT 0, recommended INTEGER DEFAULT 0 );\\
    \\
    DROP TABLE IF EXISTS last_state;\\
    CREATE TABLE last_state (card_id  NOT NULL , user_id  NOT NULL , tag_id  NOT NULL ,  current_index INTEGER DEFAULT 0,  first_load INTEGER DEFAULT 0,  app_running INTEGER);\\
    INSERT INTO last_state VALUES ('124068', '1', '111', '0', '1', null);\\
    \\
    DROP TABLE IF EXISTS tag_user_card_levels;\\
    CREATE TABLE tag_user_card_levels (tag_id INTEGER,  user_id INTEGER,  card_level_1_count INTEGER,  card_level_2_count INTEGER,  card_level_3_count INTEGER,  card_level_4_count INTEGER,  card_level_5_count INTEGER);\\
    \\
    DROP TABLE IF EXISTS tags;\\
    CREATE TABLE tags (tag_id INTEGER PRIMARY KEY AUTOINCREMENT, tag_name TEXT, description TEXT, editable INTEGER DEFAULT 1, count INTEGER NOT NULL  DEFAULT 0);\\
    \\
    CREATE TABLE IF NOT EXISTS users (user_id INTEGER PRIMARY KEY ON CONFLICT REPLACE, nickname TEXT NOT NULL , avatar_image_path TEXT NOT NULL , date_created DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP );\\
    \\
    DROP TABLE IF EXISTS user_history;\\
    CREATE TABLE user_history (card_id INTEGER, timestamp TIMESTAMP, user_id INTEGER, right_count INTEGER DEFAULT 0, wrong_count INTEGER DEFAULT 0, created_on TIMESTAMP, card_level INTEGER);\\
    \\
    DROP INDEX IF EXISTS card_tag_link_card_id;\\
    CREATE INDEX card_tag_link_card_id ON card_tag_link (card_id ASC);\\
    \\
    DROP INDEX IF EXISTS card_tag_link_tag_id;\\
    CREATE INDEX card_tag_link_tag_id ON card_tag_link (tag_id ASC);\\
    \\
    DROP INDEX IF EXISTS group_tag_link_group_id;\\
    CREATE INDEX group_tag_link_group_id ON group_tag_link (group_id ASC);\\
    \\
    DROP INDEX IF EXISTS user_history_card;\\
    CREATE INDEX user_history_card ON user_history(card_id,user_id,card_level);\\
    \\
    DROP INDEX IF EXISTS card_level;\\
    CREATE INDEX card_level ON user_history (card_level ASC);\\
    \\
    DROP INDEX IF EXISTS cards_card_id;\\
    CREATE INDEX cards_card_id ON cards (card_id ASC);\\
    \\
    DROP INDEX IF EXISTS user_history_level;\\
    CREATE INDEX user_history_level ON user_history(user_id,card_level);\\
    \\
    DROP INDEX IF EXISTS user_history_unique;\\
    CREATE UNIQUE INDEX user_history_unique ON user_history(card_id,user_id);\\
    \\
    END TRANSACTION;\\
    \\
    BEGIN TRANSACTION;\\
    \\"
    
    ## Prepend SQLite drop/creates to current file 
    ## NO WHITE SPACE ALLOWED AT START OF NEW LINE
    `sed -e '1i\\
#{sqlite_prepare_db_statements}' #{tmp_outfile_sql}.3 > #{tmp_outfile_sql}.sqlite`

    # Add end trans statement
    ## NO WHITE SPACE ALLOWED AT START OF NEW LINE
    `sed -e '$a\\
END TRANSACTION;' #{tmp_outfile_sql}.sqlite > #{tmp_outfile_sql}.sqlite0`

    # Overwrite so don't have too many temp files
    `mv #{tmp_outfile_sql}.sqlite0 #{tmp_outfile_sql}.sqlite`

    # delete tmp files
    File.delete(tmp_outfile_sql)
    File.delete("#{tmp_outfile_sql}.2")
    File.delete("#{tmp_outfile_sql}.3")

    # Run on the jFlash DB file
    puts "Running on SQLite"
    puts "----------------------------------------------------\n\n"
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" < #{tmp_outfile_sql}.sqlite`
    # `~/sqlite-3.6.21/sqlite3 "/Users/pchapman/Documents/Long Weekend Design/jFlashXcodeBranch/sql/jFlash.db" < tmp_jflash_sqlite_dump.sql.sqlite`

    puts "\nReindexing & Compacting SQLite file"
    puts "----------------------------------------------------\n\n"
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'REINDEX card_tag_link_tag_id;'`
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'REINDEX group_tag_link_group_id;'`
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'REINDEX user_history_card;'`
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'REINDEX card_level;'`
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'REINDEX cards_card_id;'`
    `#{@@sqlite_bin} "#{@@jflash_db_file_loc}" 'VACUUM;'`

  end

  ##############################################################################
  desc "jFlash Task: Create a Sqlite Mini Version as per rules"
  task :minify => :environment do
    load_library()

    # Retain JLPT 3&4 / All Kana / LWE Favourites / Onomatopeia / Common Words
    tag_ids_to_keep_arr = [94,95,124,201,204,138,42,617,618] ### WARNING these last two tag ids are generated and can change!!
    tag_ids_to_keep_list = tag_ids_to_keep_arr.join(", ")

    # Copy the source file
    new_fn= "#{@@jflash_db_file_loc}_minify.db"
    `cp '#{@@jflash_db_file_loc}' '#{new_fn}'`

    # Collate SQL commands
    sql = "\\
    DELETE FROM cards WHERE card_id NOT IN (SELECT card_id FROM card_tag_link WHERE tag_id IN (#{tag_ids_to_keep_list}));\\
    DELETE FROM cards_html WHERE card_id NOT IN (SELECT card_id FROM card_tag_link WHERE tag_id IN (#{tag_ids_to_keep_list}));\\
    DELETE FROM cards_search_content WHERE card_id NOT IN (SELECT card_id FROM card_tag_link WHERE tag_id IN (#{tag_ids_to_keep_list}));\\
    DELETE FROM card_tag_link WHERE tag_id NOT IN (#{tag_ids_to_keep_list});\\
    DELETE FROM tags WHERE tag_id NOT IN (#{tag_ids_to_keep_list});\\
    DELETE FROM group_tag_link WHERE tag_id NOT IN (#{tag_ids_to_keep_list});\\
    DELETE FROM groups WHERE group_id NOT IN (SELECT DISTINCT group_id FROM group_tag_link);\\
    UPDATE tags SET count = 0;\\
    UPDATE tags SET count = (SELECT count(tag_id) FROM card_tag_link WHERE card_tag_link.tag_id = tags.tag_id);\\
    ALTER TABLE cards_search_content RENAME TO cards_search_content_OLD;\\
    CREATE VIRTUAL TABLE cards_search_content using FTS3(card_id, content, ptag INTEGER NOT NULL DEFAULT 0);\\
    INSERT INTO cards_search_content (card_id, content, ptag) SELECT card_id, content, ptag FROM cards_search_content_OLD;\\
    DROP TABLE cards_search_content_OLD;
    VACUUM;\\"
    sql = sql.gsub("\\","").gsub("\n","")

    # Run SQL commands via CLI
    `#{@@sqlite_bin} "#{new_fn}" '#{sql}'`

  end

  ##############################################################################
  desc "jFlash Task: Run SQL command file against #{@@staging_db_name} mysql db"
  task :sql_file => :environment do
    load_library()
    if ENV.include?("file") && ENV['file'].size > 0
      puts "importing file specified, here goes nothing!"
      mysql_cli_file_import(@@staging_db_name, "root", "", ENV['file'])
    else
      puts "Please specify a SQL file to import using file=xxxx"
    end
  end
  
  ##############################################################################
  desc "Empty jFlash Import All Tables (except for 'tags_staging')"
  task :empty_tables => :environment do
    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    ## NB: the 'tags' table is improted manulaly from Npedia, and added to manually
    @cn.execute("TRUNCATE TABLE cards_staging")
    @cn.execute("TRUNCATE TABLE card_tag_link")
    puts "jFlash tables truncated (cards_staging, card_tag_link)"
  end

  ##############################################################################
  desc "Adds JLPT tags to lower levels to increase set size (ie. JLPT1 = JLPT1+2+3+4)"
  task :jlpt_tags => :environment do
    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)
    @cn.execute("UPDATE cards_staging SET tags = concat('jlpt3, ',tags) WHERE tags like '%jlpt4%' AND tags not like '%jlpt3%'")
    @cn.execute("UPDATE cards_staging SET tags = concat('jlpt2, ',tags) WHERE tags like '%jlpt3%' AND tags not like '%jlpt2%'")
    @cn.execute("UPDATE cards_staging SET tags = concat('jlpt1, ',tags) WHERE tags like '%jlpt2%' AND tags not like '%jlpt1%'")
    puts "Additional JLPT tags prepended to existing JLPT cards"
  end

  ##############################################################################
  desc "EDICT2 to JFlash Importer, ACCEPTS src={source file path} | from={start line} | to={max line} | card_type={WORD,DICTIONARY,KANA,KANJI} | add_tags={CSV of tags to add to ALL entries} | ptag_only={true|false : add only common words}"
  task :import => :environment do
    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    add_tags = ""
    ptag_only = false

    if ENV.include?("merge_similar") && ENV['merge_similar'] == 'true'
      @options[:merge_similar] = true
    else
      @options[:merge_similar] = false
    end
    
    # Add jFlash specific tags to the good tags list
    @cn.execute("SELECT source_name, tag_name FROM tags_staging WHERE source='jflash'").each do | source_name, tag_name |
      if source_name.index(",")
        # handle multiple source names
        source_name.split(",").each do |sn|
          @good_tags[:tag]<< sn
        end
      else
        # handle single source name
        @good_tags[:tag]<< source_name
      end
    end
    @good_tags[:tag].uniq.flatten

    # Use this option to specify WORD or DICTIONARY (SENTENCE not yet implemented!!)
    if ENV.include?("card_type") && ENV['card_type']
      card_type = @@card_types[ENV['card_type'].upcase]
      if card_type.nil?
        puts "Error, card type not recognised! See source for valid card types."
        break
      end
    else
      card_type = @@card_types['DICTIONARY']
    end

    # Use this option to add tags to imported words
    if ENV.include?("add_tags") && ENV['add_tags']
      add_tags = ENV['add_tags'].downcase.split(',').collect {|s| s.strip }.join(", ").strip
    end
    
    # Use this option to add tags to imported words
    if ENV.include?("ptag_only") && ENV['ptag_only']
      ptag_only = (ENV['ptag_only'].downcase == "true" ? true : false)
    end
    
    # SENTENCE card type (i.e. Tanaka Corpus or similar format, NOT yet implemented!!)
    results = process_edict("extract", get_cli_start_point, get_cli_break_point)
    jflash_data_import(results[:data], add_tags, card_type, ptag_only)

    unless @options[:silent]
      puts "Completed jFlash Import"
      #puts "new headwords: " + results[:data].length.to_s unless results[:data].nil?
      #puts "new usages: " + results[:count].to_s unless results[:count].nil?
    end

  end

  ##############################################################################
  desc "jFlash Task: Add Tags"
  task :add_tags => :environment do

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    @cn.execute("TRUNCATE TABLE card_tag_link")
    puts "Truncated card_tag_link table"

    tag_by_name_arr = {}
    data_en = nil
    # Note, we match on 'source name' column values
    tags = @cn.execute("SELECT tag_id, source_name FROM tags_staging WHERE source_name <> '' ORDER BY tag_id")

    tickcount("Caching Tags") do
      tags.each do |tag_id,source_name|

        if source_name.index(",")
          # handle multiple source names
          source_name.split(",").each do |sn|
            tag_by_name_arr[sn] = { :tag_id => tag_id }
          end
        else
          # handle single source name
          tag_by_name_arr[source_name] = { :tag_id => tag_id }
        end

      end
    end

    tickcount("Selecting Cards") do
      data_en = @cn.execute("SELECT card_id, tags FROM cards_staging")
    end

    # Empty the table
    @cn.execute("TRUNCATE TABLE card_tag_link")

    # this is not optimsied for batches, but it only takes 7 seconds for 21,000 recs
    tickcount("Looping n Inserting") do
      data_en.each do |card_id, tags|
        tags.split(',').each do |tag|
          vector = tag_by_name_arr[tag.strip]
          if vector.nil?
            tag_strip = tag.strip
            # Add missing tag to stack
            puts "Added missing tag: #{tag}"
            @cn.insert("INSERT INTO tags_staging (tag_name, description, source_name, source) values ('#{tag_strip}', '', '#{tag_strip}', 'edict')")
            the_tag = @cn.execute("SELECT tag_id, tag_name, source FROM tags_staging WHERE tag_name = '#{tag_strip}'")
            curr_tag_id = nil
            the_tag.each do |tag_id,name,source|
              tag_by_name_arr[name] = { :tag_id => tag_id }
              curr_tag_id = id
            end
          else
            curr_tag_id = vector[:tag_id]
          end
          ## Uses Uniq Compound Idx:
          ## CREATE UNIQUE INDEX card_tag_link_uniq ON card_tag_link (`tag_id`, `card_id`);
          @cn.insert("INSERT INTO card_tag_link (tag_id, card_id) values (#{curr_tag_id}, #{card_id}) ON DUPLICATE KEY UPDATE tag_id = #{curr_tag_id}")
        end
      end
    end

    data = @cn.execute("SELECT t.tag_name, l.tag_id, count(l.card_id) as cnt FROM card_tag_link l INNER JOIN tags_staging t ON l.tag_id = t.tag_id GROUP BY l.tag_id ORDER BY cnt desc")
    @cn.execute("UPDATE tags_staging SET visible = 0 WHERE tag_id <> #{@@SYSTEM_TAGS['LWE_FAVORITES']}")
    puts "\nSummary of tag associations added..."
    puts "==========================================================================="
    data.each do |tag_name, tag_id, cnt|
      if cnt.to_i > 6
        @cn.execute("UPDATE tags_staging SET visible = 1 WHERE tag_id = #{tag_id}")
        puts "#{tag_id}\t\t#{cnt}\t\t#{tag_name}\t\t\t\t\t#{(cnt.to_i < 5 ? '** non-visible**' : '' )}"
      end
    end
    puts "==========================================================================="

  end

  ##############################################################################
  desc "jFlash Task: Add Romaji, ACCEPTS force=(true|false : regenerates existing romaji, sentences)"
  task :add_romaji => :environment do

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    data = nil
    forced = (ENV.include?("force") && ENV['force'] == 'true'? true : false)
    tickcount("Selecting Cards") do
      # JUMAN won't handle multiple readings, so ignore readings containing a comma
      sql_cond = (forced ? "" : "WHERE (romaji is NULL OR romaji = '' OR romaji = 'NULL') ")
      data = @cn.execute("SELECT card_id, headword, meaning, reading, romaji FROM cards_staging #{sql_cond}")
    end

    utf_src_fn = "juman_tmp_src.utf"
    euc_src_fn = "juman_tmp_src.euc"
    euc_out_fn = "juman_tmp_out.euc"
    utf_out_fn = "juman_tmp_out.utf"
    tmp_sql_fn = 'tmp_sql_updates.sql'
    separated_reading_data = []
    multi_reading_separated_reading_data = []
    bad_readings = []
    existing_data = {}

    tickcount("Processing Reading Separation Data (using Juman morphological analyser)") do

      # NB: You must have JUMAN and ICONV installed for this to work.
      #     ICONV comes default on most UNIX systems
      #     JUMAN is avaiable here: http://www433.elec.ryukoku.ac.jp/~yokomizo/ntool/install.html

      # create src file 'euc_src_fn'
      utf_src_outf = File.open(utf_src_fn, 'w')
      puts "Creating temporary kana readings file"
      data.each do |card_id, headword, meaning, reading, romaji|
        if !reading.index(",")
          # These are for JUMAN conversion
          utf_src_outf.write("[#{card_id}]#{reading}\t#{headword}\n")
          existing_data[card_id] = { :headword => headword, :reading => reading, :romaji => romaji }
        else
          # These will be converted without splitting
          multi_reading_separated_reading_data << { :card_id => card_id, :reading => reading }
        end
      end
      utf_src_outf.close

      # Init empty files, ICONV/JUMAN don't seem to do this??
      File.open(euc_out_fn,'w'){ |f| f.write('') }
      File.open(utf_out_fn,'w'){ |f| f.write('') }

      # convert UTF8 src to EUC with ICONV at CLI
      # ... make sure your path is correct!
      puts "/sw/bin/iconv -f UTF-8 -t EUCJP #{utf_src_fn} > #{euc_src_fn}"
      `/sw/bin/iconv -f UTF-8 -t EUCJP #{utf_src_fn} > #{euc_src_fn}`
      # NB: Inline conversions using Kconv were unreliable, so we use ICONV

      # execute JUMAN at CLI
      # ... make sure your path is correct!
      puts "/usr/local/bin/juman -e < #{euc_src_fn} > #{euc_out_fn}"
      `/usr/local/bin/juman -e < #{euc_src_fn} > #{euc_out_fn}`

      # convert EUC output to UTF8 with ICONV at CLI
      # ... make sure your path is correct!
      puts "/sw/bin/iconv -f EUCJP -t UTF-8 #{euc_out_fn} > #{utf_out_fn}"
      `/sw/bin/iconv -f EUCJP -t UTF-8 #{euc_out_fn} > #{utf_out_fn}`

      # Read in juman results in utf8 format, delete tmp files
      lines = File.open(utf_out_fn, 'r')
      File.delete(utf_src_fn)
      File.delete(euc_src_fn)
      File.delete(euc_out_fn)

      separated_reading_from_reading = ""
      separated_reading_from_hw = ""
      debug_lines = ""
      line_count = 0
      entry_count = 1
      curr_card_id = 0
      curr_section = "reading"
      
      lines.each do |line| 
        debug_lines = debug_lines + line
        
        # Change mode and skip (tab delimits reading from headword)
        if line.scan(/^\t \t \t/).size > 0
          curr_section = "headword"

        # Process the line data
        elsif line != "EOS\n"

          # Split on spaces, and get the second item in array
          data_pos1 = line.split(' ')[0].to_s.strip.strip
          data_pos2 = line.split(' ')[1].to_s.strip.strip
          data_pos4 = line.split(' ')[3].to_s.strip.strip
          id_pattern_match = data_pos1.match(/\[(\d+)\]/)
          if id_pattern_match
            curr_card_id = id_pattern_match[1]
          end
            
          # Detect particle HA and transliterate into WA
          # EX OUTPUT:  は は は 助詞 9 副助詞 2 * 0 * 0 NIL
          if data_pos1 == "は" && data_pos2 == "は" && data_pos4 == "助詞"
            data_pos1 = "わ" # sub in WA for particle HA
          end

          # Skip　additional info lines returned by Juman
          if data_pos1 != "@" && data_pos1 != "/" && data_pos1 != "\\"
            # Add to recompiled string, skip first entry, it's the Card ID da-yo!
            if line_count > 0
              if curr_section == "reading"
                separated_reading_from_reading = separated_reading_from_reading + data_pos2 + " "
              elsif curr_section == "headword"
                separated_reading_from_hw = separated_reading_from_hw + data_pos2 + " "
              end
            end
            line_count+=1
          end
        
        else

          # Add to stack if entry is divisible
          if line_count > 2 || forced || existing_data[curr_card_id][:romaji].nil? || existing_data[curr_card_id][:romaji] == ""
            if curr_card_id != ""
              #puts "kana: " + separated_reading_from_reading 
              #puts "hw:" + separated_reading_from_hw

              if separated_reading_from_reading.gsub(' ', '') == separated_reading_from_hw.gsub(' ', '')
                # If they match, use JUMAN reading
                tmp_reading = separated_reading_from_hw
              else
                # If they don't match, use the original reading and kill the spaces!
                ###puts separated_reading_from_reading.gsub(' ', '') + " --------DID NOT MATCH--------- " + separated_reading_from_hw.gsub(' ', '')
                tmp_reading = separated_reading_from_reading
              end

              # Do not add if reading contains kanji still (a bad conversion!)
              if !tmp_reading.match(@regexes[:all_common_kanji])
                separated_reading_data << { :card_id => curr_card_id, :reading => tmp_reading }
              else
                separated_reading_data << { :card_id => curr_card_id, :reading => "" }
                bad_readings << { :card_id => curr_card_id, :reading => tmp_reading }
              end
            end
          end

          # Clear loop tracking
          separated_reading_from_reading = ""
          separated_reading_from_hw = ""
          curr_section = "reading"
          debug_lines = ""
          line_count = 0
          useful_line_count = 0
          entry_count+=1
        end

      end
    end

    loop_count = 0
    buffered_lines =""
    tmp_fn = 'tmp_sql_updates.sql'
    outf = File.open(tmp_fn, 'w')

    puts "Card IDs Failing Juman Converison" if bad_readings.length > 0
    bad_readings.each do |line|
      puts line[:card_id].to_s 
    end
    
    # Include kana conversion library
    include Kana2rom
    max_recs =separated_reading_data.size + multi_reading_separated_reading_data.size
    tickcount("Looping n Updating Romaji from Juman") do
      [separated_reading_data, multi_reading_separated_reading_data].each do |data_source|
        data_source.each do |line|
          card_id=line[:card_id]
          reading=line[:reading]

          #Convert to nice romaji string
          romaji_str = Kana2rom::kana2rom(Kana2rom::kata2hira(reading.to_s))

          if !romaji_str.index("x").nil?
            # try reconverting without spaces!
            new_reading = reading.to_s.gsub(" ","")
            new_romaji_str = Kana2rom::kana2rom(Kana2rom::kata2hira(new_reading))
            if new_romaji_str.index("x").nil?
             reading = new_reading
             romaji_str = new_romaji_str
            else
              puts "Dubious romaji conversion detected: " + reading + " >>> " + romaji_str + "." 
            end
          end

          # Make sure commas are followed by precisely one space
          romaji_str.gsub(/(,[\s]?)/, ', ')

          # Escape single quotes since we are using the mysql command line
          romaji_str.gsub!("'" , "\\\\\'")

          if !romaji_str.nil?
            buffered_lines = (buffered_lines == "" ? "" : buffered_lines) + "UPDATE cards_staging SET romaji = \'#{romaji_str}\' WHERE card_id = #{card_id};\n"
            loop_count+=1
          end

          # Flush buffer every 1000 records
          if loop_count%1000==0 || loop_count == max_recs
            puts "#{loop_count} cards processed"
            outf.write(buffered_lines)
            buffered_lines = ""
          end

        end
      end
    end
    outf.close

    # Execute in mysql via CLI
    mysql_cli_file_import(@@staging_db_name, "root", "", tmp_fn)
    File.delete(utf_out_fn)
    File.delete(tmp_fn)

  end

  ##############################################################################
  desc "jFlash Tool: Clean readings & romaji with P tags in them (selects first reading marked with a P tag)"
  task :clean_edict_readings => :environment do
    
    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)
    data = nil

    tickcount("Selecting Cards") do
      # Only select WORD or DICTIONARY cards, as these can come from EDICT 
      data = @cn.execute("SELECT card_id, reading, romaji FROM cards_staging WHERE (reading LIKE '%(%' OR reading LIKE '%;%' OR reading LIKE '%/%') AND (card_type = #{@@card_types['WORD']} OR card_type = #{@@card_types['DICTIONARY']})")
    end

    tickcount("Cleaning & Updating") do
      data.each do |card_id, reading, romaji|
        clean_reading = ""
        clean_romaji = ""
        clean_reading_count  = 0

        # Replace semi-colons & slashes inside parentheses with commas
        new_reading = ""
        ins = false
        reading.each_char { |s| 
          ins = true if s=="("
          ins = false if ins && s==")"
          new_reading  = new_reading + (ins && s==";" ? ", "  : s).strip
        }
        new_reading = new_reading.gsub(' / ', ', ').gsub('/', ', ').gsub(';', ', ')
        reading_arr = new_reading.split(',')
      
        # return maximum 3 readings
        reading_arr.each do |r|
          clean_reading_count +=1
          clean_reading = clean_reading + (clean_reading == "" ? "" : ", ").strip + r.gsub("'" , '\\\\\'')
          break if clean_reading_count > 2
        end

        # Remove tags, add a * to the first PTAG only! => 
        clean_reading = clean_reading.sub('(P)', '※') if clean_reading_count > 1
        clean_reading.gsub!(@regexes[:tag_like],'')
        @cn.execute("UPDATE cards_staging SET reading = '#{clean_reading}' WHERE card_id = #{card_id}")
      end
    end
  end

  ##############################################################################
  desc "jFlash Task: Divide tag relationships in tables tags_staging/card_tag_links greater than @@MAX_CARDS_PER_TAG into into smaller sets"
  task :limit_set_size => :environment do

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    #--- Make sure tag counts are up to date! ----
    @cn.execute("UPDATE tags_staging SET count = 0")
    @cn.execute("UPDATE tags_staging t SET count = (SELECT count(tag_id) FROM card_tag_link cl WHERE cl.tag_id = t.tag_id)")

    # For tags exceeding maximum set size (10,000) ... create additional tags (eg. Noun 1, Noun 2) and reassign
    unless @options[:silent]
      puts "\n\nCarving up large sets into smaller groups of sets!"
      puts "----------------------------------------------------\n\n"
    end
    
    if !mysql_col_exists("card_tag_link.tmpid")
      puts "Adding temporary id to card_tag_link"
      @cn.execute("ALTER TABLE card_tag_link ADD COLUMN tmpid int(11) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (tmpid);") # add tmpid column
    end
    @cn.execute("DELETE FROM group_tag_link WHERE tag_id IN (SELECT tag_id FROM tags_staging WHERE parent_tag = 0)") # Delete all non-parent tag group link recs
    @cn.execute("DELETE FROM tags_staging WHERE parent_tag = 0") # Delete all non-parent tags!
    @cn.execute("SELECT tag_name, tag_id, count, description FROM tags_staging WHERE count > #{@@MAX_CARDS_PER_TAG}").each do | tag_name, tag_id, count, description |
      tags_needed = (count.to_i - (count.to_i % @@MAX_CARDS_PER_TAG)) / @@MAX_CARDS_PER_TAG + (count.to_i % @@MAX_CARDS_PER_TAG > 0 ? 1 : 0)
      puts "\nTag: #{tag_name} (#{count})\nTags Needed: #{tags_needed}" unless @options[:silent]

      # get parent folder for adding group_tag_link
      parent_group_id_arr=[]
      @cn.execute("SELECT group_id FROM group_tag_link WHERE tag_id = #{tag_id}").each do |group_id|
        parent_group_id_arr << group_id
      end

      (2..tags_needed).each do |counter|
        ## Added "%02d" without testing closely!
        new_child_tag_id = @cn.insert("INSERT INTO tags_staging (tag_name, description, source, parent_tag, visible) VALUES ('#{tag_name} #{"%02d" % counter}', '(cont) #{description}', 'jflash-importer', 0, 1)")
        ### Add group_tag_link for each association of the parent (it appears where the parent does!)
        parent_group_id_arr.each do |group_id|
          @cn.insert("INSERT INTO group_tag_link (group_id, tag_id) VALUES (#{group_id}, #{new_child_tag_id})")
        end
        limit_num_recs = (counter < tags_needed ? @@MAX_CARDS_PER_TAG : count.to_i - (@@MAX_CARDS_PER_TAG * (tags_needed-1)) )
        limit_offset = @@MAX_CARDS_PER_TAG #(counter-1) * @@MAX_CARDS_PER_TAG
        puts "SELECT tmpid FROM card_tag_link WHERE tag_id = #{tag_id} LIMIT #{limit_num_recs} OFFSET #{limit_offset}" unless @options[:silent]
        cntrec=0
        puts "----------------------------------\nNew Tag ID #{new_child_tag_id}" unless @options[:silent]
        @cn.execute("SELECT tmpid FROM card_tag_link WHERE tag_id = #{tag_id} LIMIT #{limit_offset}, #{limit_num_recs}").each do | tmpid |
          cntrec +=1
          # loop madly updating each card_tag_link.tag_id
          @cn.execute("UPDATE card_tag_link SET tag_id = #{new_child_tag_id} WHERE tmpid = #{tmpid}")
        end
        puts "Looped thru updater loop #{cntrec} times"
        # update child tag count
        new_count = @cn.select_one("SELECT count(tag_id) as cnt FROM card_tag_link WHERE tag_id = #{new_child_tag_id}")["cnt"]
        puts "New tag cnt: #{new_count}\nUPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{new_child_tag_id}" unless @options[:silent]
        @cn.execute("UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{new_child_tag_id}")
      end
      # update parent tag count (should be 10,000)
      new_count = @cn.select_one("SELECT count(tag_id) as cnt FROM card_tag_link WHERE tag_id = #{tag_id}")["cnt"]
      unless @options[:silent]
        puts ""
        puts "Orig tag cnt: #{new_count}"
        puts "UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{tag_id}"
        puts ""
        puts ""
      end
      @cn.execute("UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{tag_id}")
    end

    # remove tmpid column
    puts "Removing temporary id column"
    @cn.execute("ALTER TABLE card_tag_link DROP tmpid") # drop tmpid column

  end

  ##############################################################################
  desc "jFlash Task: Import English Words and match to entry in import DB - with / without tags (ACCEPTS: file=en_import_words.txt)"
  task :en_words => :environment do

    if !ENV.include?('file')
      puts "\n\nError, source file not found!\n"
      exit
    end

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    out = ""
    line_count = 0
    existing_data = {}
    existing_eng_headwords = {}
    existing_eng_words = {}
    possible_matches = {}
    no_matches = []
    data = nil

    # cache all cards
    tickcount("Selecting Existing Cards") do
      data = @cn.execute("SELECT card_id, headword, headword_en, meaning, reading, romaji FROM cards_staging")
    end

    # open out file
    outf = File.open(ENV['file'] + "_out.txt", 'w')

    data.each do |card_id, headword, headword_en, meaning, reading, romaji|
      eng_str = headword_en.gsub(@regexes[:tag_like], "").gsub("[\(|\)]","").strip

      # headword wise matching
      if existing_eng_headwords.include?(headword_en)
        #add to existing subarray
        existing_eng_headwords[headword_en] << card_id
      else
        # create subarray and add
        existing_eng_headwords[headword_en] = []
        existing_eng_headwords[headword_en] << card_id
      end
      
      # word-wise matching
      eng_str.split(' ').each do |word|
        if existing_eng_words.include?(word)
            #add to existing subarray
            existing_eng_words[word] << card_id
          else
            # create subarray and add
            existing_eng_words[word] = []
            existing_eng_words[word] << card_id
        end
      end
      
      existing_data[card_id] = { :headword => headword, :headword_en => headword_en, :reading => reading, :romaji => romaji, :meaning => meaning }
    end

    existing_eng_words.each do |word|
      existing_eng_words[word].uniq! if !existing_eng_words[word].nil?
    end
    
    existing_eng_headwords.each do |word|
      existing_eng_headwords[word].uniq! if !existing_eng_headwords[word].nil?
    end
    
    lines = File.open(ENV['file'], 'r')

    lines.each do |line| 
      line_count+=1
      headword = line[0..line.index(" ")-1].strip

      # init array in hash
      if possible_matches[headword].nil?
        possible_matches[headword] = [] 
      end

      if existing_eng_headwords.include?(headword)
        # some debug
        existing_eng_headwords[headword].each do |card_id|
          outf.write(line + existing_data[card_id.to_s][:headword] + " " + existing_data[card_id.to_s][:meaning] )
        end
        possible_matches[headword] << existing_eng_headwords[headword]
      elsif existing_eng_words.include?(headword)
        # some debug
        existing_eng_words[headword].each do |card_id|
          outf.write(line + existing_data[card_id.to_s][:headword_en] + " " + existing_data[card_id.to_s][:meaning] )
        end

        possible_matches[headword] << existing_eng_words[headword]
      else
        puts "Did not match: #{line}"
        no_matches << line
      end
    end
    outf.close

    puts "Lines read: #{line_count}"
    puts "Not Matched: #{no_matches.size.to_s}"

    outf = File.open(ENV['file'] + "_not_matched.txt", 'w')
    outf.write(no_matches.join(""));
    outf.close
  end

  ##############################################################################
  desc "jFlash Task: Import Kanjidic Entries into staging database (REQUIRES: kdic=kanjidic2_20100312.xml krad=kradfile.txt)"
  task :kanjidic => :environment do

    ### EG:
    #### rake jflash:kanjidic kdic='data/kanjidic2_20100312.xml' krad='data/kradfile_combined_utf8.txt' --trace
    ###
    
    require 'nokogiri'

    load_library()
    @cn = jflash_import_db_connect(@@staging_db_name)

    if !ENV.include?('kdic') || !ENV.include?('krad')
      puts "\n\nError, source files not found!\n"
      exit
    end

    # Get file and parse XML
    xml_file = File.open(ENV['kdic'], 'r')
    doc = Nokogiri::XML(xml_file,nil,'UTF-8')
    xml_file.close

    krad_lines = File.open(ENV['krad'], 'r')
    krad_data = {}
    krad_lines.each do |line|
      kd = line.split(" : ")
      krad_data[ kd[0] ] = kd[1].gsub(' ',',')
    end
    krad_lines.close
    puts "kRad data #{krad_data.length}"

    # Write outfile
    tmp_fn = "kanjidic_import.sql"
    outf = File.open(tmp_fn, 'w')

    missing_components = []

    # Search for nodes by css
    sql_lines_arr_kanji = []
    sql_lines_arr_readings = []
    sql_lines_arr_meanings = []
    line_count = 0
    tags = doc.css('kanjidic2 character')
    tags.each do |tag|

      line_count +=1
      #puts "--------------------------------------------------------"

      kanji = tag.css('literal').first.text
      #puts "kanji: #{kanji}"

      radical = tag.css('radical rad_value[@rad_type = "classical"]').first.text
      #puts "radical: #{radical}"

      frequency = tag.css("misc freq").text
      frequency = 0 if frequency.empty? || frequency.nil?
      #puts "freq: #{frequency}"

      grade = tag.css("misc grade").text
      grade = 0 if grade.empty? || grade.nil?
      #puts "grade: #{grade}"

      jlpt = tag.css("misc jlpt").text
      jlpt = 0 if jlpt.empty? || jlpt.nil?
      #puts "jlpt: #{jlpt}"

      stroke_count = tag.css("misc stroke_count").text
      #puts "stroke_count: #{stroke_count}"
      
      if krad_data[kanji].nil?
        missing_components << kanji
        compononents = ""
      else
        components = krad_data[kanji].strip
      end
      #puts "components: #{components}"

      # readings
      readings = []
      tag.css('reading_meaning rmgroup reading').each do |reading|
        #readings << { :reading => reading.text, :reading_type => reading['r_type'] }
        #puts "reading: #{reading.text} / #{reading['r_type']}"
        sql_lines_arr_readings << "INSERT INTO kanji_readings_staging (kanji, reading_type, reading) VALUES \n ('#{kanji}', '#{reading['r_type'].gsub("'" , '\\\\\'')}', '#{reading.text}');"
      end
      
      # meanings
      meanings = []
      tag.css('reading_meaning rmgroup meaning').each do |meaning|
        lang = (meaning['m_lang'].nil? ? "en" : meaning['m_lang'] )
        #meanings << { :meaning => meaning.text, :language => lang }
        #puts "meaning: #{meaning.text} / #{lang}"
        sql_lines_arr_meanings << "INSERT INTO kanji_meanings_staging (kanji, meaning, language) VALUES \n ('#{kanji}', '#{meaning.text.gsub("'" , '\\\\\'')}', '#{lang}-#{line_count}');"
      end

      # nanori
      nanoris = []
      tag.css('reading_meaning nanori').each do |nanori|
        nanoris << nanori.text
      end
      nanori = nanoris.join(', ')
      #puts "nanoris: #{nanoris}"
      
      xml_tag = tag.to_xml(:encoding => 'UTF-8')
      xml_tag.gsub!("'" , '\\\\\'')

      # Add to array
      sql_lines_arr_kanji << "INSERT INTO kanji_staging (kanji, radical, stroke_count, jlpt, grade, frequency, components, nanori, xml) VALUES \n ('#{kanji}', #{radical}, #{stroke_count}, #{jlpt}, #{grade}, #{frequency}, '#{components}', '#{nanori}', '#{xml_tag}');"
      puts "#{line_count} lines processed" if line_count%500 == 0 || line_count == tags.length

    end

    # Write arrays to file
    puts "Writing tmp file"
    outf.write(sql_lines_arr_kanji.join("\n").to_s + "\n")
    outf.write(sql_lines_arr_readings.join("\n").to_s + "\n")
    outf.write(sql_lines_arr_meanings.join("\n").to_s + "\n")
    outf.close

    # How many are missing (952!)
    puts missing_components.length

    mysql_cli_file_import(@@staging_db_name, "root", "", tmp_fn)
    File.delete(tmp_fn)

  end

end
#----------------------------------------------------------------------------#