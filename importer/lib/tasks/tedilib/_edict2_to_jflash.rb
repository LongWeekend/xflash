########################################################################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#   --- Export to jflash (SQLite) ---
#  DESC: Imports edict2 entries into jflash 'cards_en_staging' table format
########################################################################################

####################################################################
# Parameters: data = Hash of edict2 data
def jflash_data_import(data, add_tags="", card_type="DICTIONARY", ptag_only=false)

  sql_insert_header = "INSERT INTO cards_staging (headword,alt_headword,headword_en,reading,meaning,meaning_html,meaning_fts,tags,card_type,ptag) VALUES "

  loop_count = 0
  sql_line_count = 0
  sql_line_total_count = 0
  buffered_lines = ""
  ja_master_sql_data = []
  en_master_sql_data = []
  cards_sql_arr = []
  tmp_fn = "jflash_vocab.sql"
  outf = File.open(tmp_fn, 'w')

  # Do we need a DB connection?
  @cn = jflash_import_db_connect(@@staging_db_name) if @cn.nil?
  
  # Get all existing entries and store the headword/reading/meaning/tag data
  existing_data = {}
  existing_data[card_type.to_i] = {}
  @cn.execute("SELECT card_id, headword, alt_headword, reading, meaning, romaji, tags, card_type FROM cards_staging").each do | card_id, headword, alt_headword, reading, meaning, romaji, tags, card_type_local |
    existing_data[card_type_local.to_i] = {} if !existing_data[card_type_local.to_i]
    existing_data[card_type_local.to_i][headword] = { :card_id => card_id, :headword => headword, :reading => reading, :meaning => meaning, :romaji => romaji, :tags => tags }
    if !alt_headword.nil?
      alt_headword.split(';').each do |alt_hw|
        existing_data[card_type_local.to_i][alt_hw] = { :card_id => card_id, :headword => alt_hw, :reading => reading, :meaning => meaning, :romaji => romaji, :tags => tags}
      end
    end
  end

  # Cache all existing tags in memory, so we can display existing tags, non-edict tag names
  existing_tags = {}
  @cn.execute("SELECT source_name, short_name FROM tags_staging WHERE source='edict'").each do | source_name, short_name |
    if source_name.index(",")
      # handle multiple source names
      source_name.split(",").each do |sn|
        existing_tags[sn] = short_name
      end
    else
      # handle single source name
      existing_tags[source_name] = short_name
    end
  end

  data.each do |headword,entry|
    loop_count+=1
    sql_line_count+=1
    readings_string = ""
    descriptions_arr = []
    descriptions_notags_arr = []
    html_descriptions_arr = []
    tags_arr = []
    pos_tags_arr = []
    tags = ""

    alt_english_text = ""
    curr_english_text = ""
    en_hw_tmp = ""
    ptag = false

    # 1- prep usages/tags/readings, add data to hashes
    entry[:usages].each do |usage|
      ptag = !usage[:tag_tags].index("common").nil?

      if (ptag_only && ptag) || (!ptag_only)
        # i - remove parenthetical strings
        readings_string = usage[:readings] if readings_string.gsub(@regexes[:tag_like], "") == ""
        
        # ii - merge all tag strings
        tags_arr << usage[:pos_tags].split(',') if usage[:pos_tags].length > 0
        tags_arr << usage[:lang_tags].split(',') if usage[:lang_tags].length > 0
        tags_arr << usage[:tag_tags].split(',') if usage[:tag_tags].length > 0
        
        # iii - keep pos tags separate
        pos_tags_arr << usage[:pos_tags].split(',') if usage[:pos_tags].length > 0
        
        # iv - create inline tags string 
        tags_inline = "(" + usage[:pos_tags].split(',').flatten.uniq.collect{|s| (existing_tags[s].nil? ? s : existing_tags[s]) }.join(", ").strip + ")"
        tags_inline_html = usage[:pos_tags].split(',').flatten.uniq.collect{|s| "<dfn>" + (existing_tags[s].nil? ? s : existing_tags[s]) + "</dfn>"}.join("")
        
        # v - prep descriptions
        tmp_desc = usage[:description].gsub(@regexes[:leading_trailing_slashes], "").gsub("'" , "''").gsub('  ', ' ').gsub('/', ' / ').strip
        descriptions_arr << tmp_desc + (pos_tags_arr.size > 0 ? " " + tags_inline : "")
        descriptions_notags_arr << tmp_desc
        html_descriptions_arr << tmp_desc + (pos_tags_arr.size > 0 ? " " + tags_inline_html : "")
        
        # vi - create a new EN HW if blank!
        en_hw_tmp = tmp_desc if en_hw_tmp.size < 1
      end
    end

    # 2- proceed if reading exists
    if !readings_string.empty?
      
      # 3 - filter tags and create string version
      if tags_arr.size > 0
        tags_arr = tags_arr.flatten.uniq
        tags_arr.delete("P")
      end
      # Add any additional tags from CLI - Not added to the inline tag block!
      if add_tags.size > 0
        tags_arr << add_tags
      end
      tags_arr.flatten.uniq!
      tags = tags_arr.join(", ").strip
      
      # 4- prep description strings (txt, ftx, html)
      descriptions_string = descriptions_arr.join("; ")
      fts_descriptions_string = remove_stop_words(descriptions_notags_arr.join("; "))

      # Create Ordered List if more than one meaning!
      if descriptions_arr.size > 1
        html_descriptions_string = "<ol>" + html_descriptions_arr.collect{|d| "<li>" + d +"</li>"}.join("") + "</ol>"
      else
        html_descriptions_string = html_descriptions_arr.join("")
      end
      ja_headword = headword.gsub(@regexes[:tag_like], "").strip

      # 5 - prep EN headword (guess which one to use)
      en_headword = en_hw_tmp.strip
      en_headword = en_headword.match(@regexes[:first_english_token])[0] if en_headword.length > 25
      en_headword = en_headword.to_s[0,1].capitalize + en_headword[1, en_headword.length]
      en_headword.strip!

      # 6 - Duplicate Check!

      # Check for duplicates by comparing HEADWORD + READING against existing (compares readings one by one)
      # Scoped by card_types, so duplicate can exist across card types!
      entry_exists = false
      existing_entries = []

      if existing_data[card_type.to_i][ja_headword]
        possible_match = existing_data[card_type.to_i][ja_headword]
        possible_match[:reading].split(';').each do |r|
          if !readings_string.split(';').index(r).nil?
            existing_entries <<  possible_match
            entry_exists = true
          end
        end
      end

      # 7 - Merge if exists
      # If already exists, add unique tags to existing entry  tags on existing entry if this is already in the DB
      if entry_exists

        extra_tags_arr = []

        # Use new entry's tags if tag not found in existing entry
        existing_entries.each do |existing_entry|

          #puts "-------------Entry Exists!-------------"
          #puts "#{existing_entry[:id]}. #{existing_entry[:headword]} -- #{existing_entry[:reading]}"
          #puts "   OLD: #{existing_entry[:meaning]}\n   NEW: #{descriptions_string}\n"

          tags_arr.flatten.each do |tag|
            if existing_entry[:tags].split(',').index(tag).nil?
              extra_tags_arr << tag
              #puts "   + TAG: #{tag}"
            end
          end
          extra_tags_arr << existing_entry[:tags]
          new_tags_string = extra_tags_arr.flatten.uniq.join(", ")

          # USE new description IF old one is CONTAINED in new one
          # Perform downcased /stripped string comparison
          if !descriptions_string.strip.downcase.index(existing_entry[:meaning].strip.downcase).nil?
            cards_sql_arr << "UPDATE cards_staging SET headword_en='#{en_headword}', meaning='#{descriptions_string}', meaning_html='#{html_descriptions_string}', meaning_fts='#{fts_descriptions_string}', tags='#{new_tags_string}' WHERE card_id = #{existing_entry[:card_id]};"
            #puts "   - Using new description"

          # At least ADD new tags to existing ones if applicable
          elsif extra_tags_arr.size > 0
            cards_sql_arr << "UPDATE cards_staging SET tags='#{new_tags_string}' WHERE card_id = #{existing_entry[:card_id]};"
            #puts "   - Adding new tag to existing description"
          end

        end
      
      # 8 - Add to sql buffer if entry is new
      else
        cards_sql_arr << sql_insert_header + " ('#{ja_headword}','#{entry[:other_headwords]}','#{en_headword}','#{readings_string}','#{descriptions_string}','#{html_descriptions_string}', '#{fts_descriptions_string}', '#{tags}', #{card_type}, #{(ptag ? "1" : "0")});"
      end
      
      # 9 - Add newly inserted entry to sql buffer

      # 10 - flush sql buffer
      if sql_line_count >= @options[:import_page_size] or loop_count == data.length
        #puts ">>>  #{loop_count} -- Just prepared  #{sql_line_count} JE & EJ Vocab entries at #{Time.now})" #unless @options[:silent]
        outf.write(cards_sql_arr.join("\n").to_s + "\n\n")
        cards_sql_arr = []
        sql_line_count = 0
      end
    end

  end
  outf.close
  
  # Execute in mysql via CLI
  mysql_cli_file_import(@@staging_db_name, "root", "", tmp_fn)
  File.delete(tmp_fn)

end