class CEdictExporter

  # DESC: Exports contents of staging database to Sqlite file
  def export_staging_db_from_table(cards_table ="cards_staging")

    connect_db

    prt "Exporting MYSQL staging data to Sqlite"
    prt_dotted_line

    ## Drop previously created intermediate tables
    drop_export_tables

    ### PREPARE MYSQL SOURCE DATA
    #######################################

    ## Update group tag_count columns here; excludes invisible tags
    $cn.execute("UPDATE groups_staging SET tag_count = 0")
    $cn.execute("SELECT count(g.group_id) as cnt, g.group_id FROM groups_staging g, group_tag_link l, tags_staging t WHERE t.tag_id = l.tag_id AND t.visible = 1 AND t.force_off = 0 AND g.group_id = l.group_id GROUP BY g.group_id").each do | cnt, group_id |
      $cn.execute("UPDATE groups_staging SET tag_count = #{cnt} WHERE group_id = #{group_id}")
    end

    ## Create intermediate tables
    $cn.execute("CREATE TABLE cards DEFAULT CHARSET=utf8 SELECT card_id, headword_trad, headword_simp, headword_en, reading FROM #{cards_table}")
    $cn.execute("CREATE TABLE cards_html DEFAULT CHARSET=utf8 SELECT card_id, meaning_html AS meaning FROM #{cards_table}")
    $cn.execute("CREATE TABLE groups SELECT * FROM groups_staging")
    $cn.execute("CREATE TABLE tags SELECT tag_id, tag_name, description, editable, count, force_off FROM tags_staging")
    
    # Create FTS table & generate content
    $cn.execute("CREATE TABLE cards_search_content DEFAULT CHARSET=utf8 SELECT card_id, CONCAT(headword_trad, ' ', headword_simp, ' ', reading, ' ', reading_diacritic, ' ', meaning_fts) AS content, priority_word as ptag FROM #{cards_table}")
#    $cn.execute("ALTER TABLE cards_search_content ADD COLUMN headword_reading varchar(100)")

    # Remove non-visible tags - MMA 11.30.2011 -- is this still used? TODO
    $cn.execute("DELETE FROM tags WHERE force_off=1")
    $cn.execute("ALTER TABLE tags DROP force_off")
   
    # TOTAL HACK for starred words... unfortunately there's a problem in MySQL trying to insert 0 on an autoincrement field
    $cn.execute("UPDATE group_tag_link l, tags s SET l.tag_id = 0 WHERE (l.tag_id = s.tag_id AND s.tag_name = 'My Starred Words')")
    $cn.execute("UPDATE tags SET tag_id = 0 WHERE tag_name = 'My Starred Words'")
   
    prt "\n\nExporting tables to temporary file"
    prt_dotted_line

    ### EXPORT TO SQLITE
    #######################################

    sqlite_create_core
    sqlite_create_cards
    sqlite_create_fts

    prt_dotted_line
    prt "Export complete\n"

  end

  # DESC: PREPARE AND DUMP THE CORE DATABASE
  def sqlite_create_core
    sql_tmp_out_fn = "tmp_cflash_sqlite_dump.sql"
    File.delete(sql_tmp_out_fn) if File.exist?(sql_tmp_out_fn) # delete old tmp files
    mysql_dump_tables_via_cli(["tags", "groups", "card_tag_link", "group_tag_link"], sql_tmp_out_fn, $options[:mysql_name])

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS card_tag_link;\\
    CREATE TABLE card_tag_link (tag_id INTEGER,card_id INTEGER, id INTEGER);\\
    \\
    DROP TABLE IF EXISTS group_tag_link;\\
    CREATE TABLE group_tag_link (group_id INTEGER NOT NULL , tag_id INTEGER NOT NULL );\\
    \\
    DROP TABLE IF EXISTS groups;\\
    CREATE TABLE groups (group_id INTEGER PRIMARY KEY NOT NULL, group_name VARCHAR NOT NULL, description VARCHAR, owner_id INTEGER NOT NULL  DEFAULT 0, tag_count INTEGER NOT NULL  DEFAULT 0, recommended INTEGER DEFAULT 0 );\\
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
    DROP INDEX IF EXISTS user_history_level;\\
    CREATE INDEX user_history_level ON user_history(user_id,card_level);\\
    \\
    DROP INDEX IF EXISTS user_history_unique;\\
    CREATE UNIQUE INDEX user_history_unique ON user_history(card_id,user_id);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"USER_DB\", \"1.0\", \"Core Database\");\\
    \\
    END TRANSACTION;\\
    BEGIN TRANSACTION;\\
    \\"

    mysql_to_sqlite_converter(sql_tmp_out_fn)
    prepend_text_to_file(sqlite_prepare_db_statements, sql_tmp_out_fn)
    append_text_to_file("END TRANSACTION;", sql_tmp_out_fn)
    sqlite_run_file_via_cli(sql_tmp_out_fn, $options[:sqlite_file_path][:jflash_user])
    File.delete(sql_tmp_out_fn)

    # Reindex tables in Sqlite
    prt "Reindexing & Compacting SQLite file"
    prt_dotted_line
    sqlite_reindex_tables(["card_tag_link_tag_id", "group_tag_link_group_id", "user_history_card", "card_level"], $options[:sqlite_file_path][:jflash_user])
    sqlite_vacuum($options[:sqlite_file_path][:jflash_user])

    prt "Done Exporting to Sqlite\n"
  end

  # DESC: PREPARE AND DUMP THE CARDS DATABASE
  def sqlite_create_cards
    sql_tmp_out_fn = "tmp_cflash_cards_sqlite_dump.sql"
    File.delete(sql_tmp_out_fn) if File.exist?(sql_tmp_out_fn) # delete old tmp files
    mysql_dump_tables_via_cli(["cards", "cards_html"], sql_tmp_out_fn, $options[:mysql_name])

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS cards;\\
    CREATE TABLE cards (card_id INTEGER PRIMARY KEY, headword_trad TEXT, headword_simp TEXT, headword_en TEXT, reading TEXT);\\
    \\
    DROP TABLE IF EXISTS cards_html;\\
    CREATE TABLE cards_html (card_id INTEGER PRIMARY KEY, meaning TEXT);\\
    \\
    DROP INDEX IF EXISTS cards_card_id;\\
    CREATE INDEX cards_card_id ON cards (card_id ASC);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"CF_CARD_DB\", \"1.0\", \"Chinese Flash Cards Database (READ ONLY)\");\\
    \\
    END TRANSACTION;\\
    BEGIN TRANSACTION;\\
    \\"

    mysql_to_sqlite_converter(sql_tmp_out_fn)
    prepend_text_to_file(sqlite_prepare_db_statements, sql_tmp_out_fn)
    append_text_to_file("END TRANSACTION;", sql_tmp_out_fn)
    sqlite_run_file_via_cli(sql_tmp_out_fn, $options[:sqlite_file_path][:jflash_cards])

    # delete tmp files
    File.delete(sql_tmp_out_fn)

    # Reindex tables in Sqlite
    prt "Reindexing & Compacting SQLite file"
    prt_dotted_line
    sqlite_reindex_tables(["cards_card_id"], $options[:sqlite_file_path][:jflash_cards])
    sqlite_vacuum($options[:sqlite_file_path][:jflash_cards])

    prt "Done Exporting to Sqlite\n"
  end

  # DESC: PREPARE AND DUMP THE FTS DATABASE
  def sqlite_create_fts
    # Clean up any old dump files
    fts_tmp_out_fn = "tmp_cflash_sqlite_dump_fts.sql"
    File.delete(fts_tmp_out_fn) if File.exist?(fts_tmp_out_fn) # delete old tmp files

    # Dump tables to file, with as little extra crap as possible!
    mysql_dump_tables_via_cli(["cards_search_content"], fts_tmp_out_fn, $options[:mysql_name])

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS cards_search_content;\\
    CREATE VIRTUAL TABLE cards_search_content using FTS3(card_id, ptag, content);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"FTS_DB\", \"1.0\", \"Full Text Search Database (READ ONLY)\");\\
    \\
    END TRANSACTION;\\
    BEGIN TRANSACTION;\\
    \\"

    mysql_to_sqlite_converter(fts_tmp_out_fn)
    prepend_text_to_file(sqlite_prepare_db_statements, fts_tmp_out_fn)
    append_text_to_file("END TRANSACTION;", fts_tmp_out_fn)
    sqlite_run_file_via_cli(fts_tmp_out_fn, $options[:sqlite_file_path][:jflash_fts])
    File.delete(fts_tmp_out_fn)

    prt "Reindexing & Compacting SQLite file"
    prt_dotted_line
    sqlite_vacuum($options[:sqlite_file_path][:jflash_fts])

    prt "Done Exporting to Sqlite\n"
  end

  # DESC: Drops tables created for export to SQLite
  def drop_export_tables
    connect_db
    prt "Dropping mySQL interim export tables (cards, cards_html, tags, groups, cards_search_content)\n\n"
    $cn.execute("DROP TABLE IF EXISTS cards")
    $cn.execute("DROP TABLE IF EXISTS cards_html")
    $cn.execute("DROP TABLE IF EXISTS tags")
    $cn.execute("DROP TABLE IF EXISTS groups")
    $cn.execute("DROP TABLE IF EXISTS cards_search_content")
  end
  
end