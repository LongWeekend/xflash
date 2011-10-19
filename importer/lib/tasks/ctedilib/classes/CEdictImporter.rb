#### CEdict IMPORTER #####
class CEdictImporter < CEdictBaseImporter

  # DESC: Removes all data from import staging tables (should be run before calling import)
  def empty_staging_tables
    connect_db
    prt "Removing all data from CFlash Import staging tables (cards_staging, card_tag_link)\n\n"
    $cn.execute("TRUNCATE TABLE cards_staging") 
    $cn.execute("TRUNCATE TABLE cards_html") if mysql_table_exists("cards_html")
    $cn.execute("TRUNCATE TABLE card_tag_link") if mysql_table_exists("card_tag_link")
  end

  # RETURNS: Existing cards and adds them into a hash
  def cache_existing_cards(table ="cards_staging", where ="")
    lookup = self.cache_sql_query( { :select => "card_id, headword_trad", :from => table, :where => where } ) do | sqlrow, cache_data |
      # We are not taking data from multiple sources
      card_type = 0
      cache_data[card_type] = {} if !cache_data[card_type]
      # Store rows in hash, deserialise stored Ruby Obj
      cache_data[card_type][sqlrow['headword_trad']] = [] if !cache_data[card_type][sqlrow['headword_trad']]
      cache_data[card_type][sqlrow['headword_trad']] << sqlrow['card_id']
    end
    return lookup
  end

  # DESC: Caches staging database tag data
  def cache_tag_data
    $shared_cache[:pos_tag_human_readings] = {}
    $shared_cache[:pos_tag_inhuman_readings] = {}
    connect_db
    results = $cn.select_all("SELECT tag_id, short_name, source_name FROM tags_staging WHERE source = 'edict'")
    tickcount("Caching Existing EDICT tags") do
      results.each do |sqlrow|
        $shared_cache[:pos_tag_human_readings][sqlrow['source_name']] = { :humanised => sqlrow['short_name'], :id => sqlrow['tag_id'] }
        if !sqlrow['short_name'].nil?
          sqlrow['short_name'].split(',').each do |sname|
            $shared_cache[:pos_tag_inhuman_readings][sname] = { :inhumanised => sname, :id => sqlrow['tag_id'] }
          end
        end
      end
    end
  end

  # DESC: Overridden base class import method
  def import

    # Cache exiting cards into hashes from DB table
    existing_card_lookup = cache_existing_cards("cards_staging")

    # MERGE_NEW Counters
    merge_counter = 0
    new_counter = 0
    
    # Call 'super' method to process loop for us
    super do |cedict_rec|
      meanings_txt = ""
      meanings_fts = ""
      meanings_html = ""

      return_sql_arr = []
      cn_headword_trad = cedict_rec.headword_trad
      cn_headword_simp = cedict_rec.headword_simp
      en_headword = ""
      
      @update_entry_sql = "UPDATE cards_staging SET headword_en='%s', meaning='%s', meaning_html='%s',meaning_fts='%s', tags='%s', cedict_hash = '%s' WHERE card_id = %s;"
      @update_tags_sql  = "UPDATE cards_staging SET meaning = '%s', meaning_html = '%s', tags='%s',cedict_hash = '%s' WHERE card_id = %s;"
      @insert_entry_sql = "INSERT INTO cards_staging (headword_trad,headword_simp,headword_en,reading,reading_diacritic,meaning,meaning_html,meaning_fts,classifier,tags,referenced_cards,is_reference_only,is_variant,is_erhua_variant,is_proper_noun,variant,cedict_hash) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s',%s,'%s',%s,%s,%s,%s,%s,%s,'%s');"

      # Processing flags
      duplicate_exists = false

      # 1 - Generate EN headword
      if cedict_rec.meanings.size>0
        en_headword = self.class.xfrm_extract_en_headword(cedict_rec.meanings.first[:meaning].strip)
      end

      # 2 - Duplicate check by Headword & Readings
      duplicates_arr = get_duplicates_by_headword_reading(cn_headword_trad, cedict_rec.pinyin, existing_card_lookup, @config[:entry_type])

      # 3 - Merge with duplicates
      if duplicates_arr.size > 0
        # LOOP through each possible duplicate and go
        duplicates_arr.each do |dupe|

          # Merge existing, format meaning variously, do tags and refs
          merged_entry, meaning_strings_merged = merge_duplicate_entries(cedict_rec, dupe)
          meanings_txt, meanings_html, meanings_fts = get_formatted_meanings(merged_entry)
        
          all_tags_list = Parser.combine_and_uniq_arrays(merged_entry.all_tags).join($delimiters[:jflash_tag_coldata])

          # Serialise for storage in DB
          serialised_cedict_rec = mysql_serialise_ruby_object(merged_entry)

          # Remove embedded card_id from hash 
          merged_entry_card_id = merged_entry.id.to_i
          merged_entry.set_id(-1)

          if meaning_strings_merged
            # UPDATE HEADWORD_EN, MEANINGS & TAGS
            return_sql_arr << @update_entry_sql % [ en_headword, mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), mysql_escape_str(meanings_fts), all_tags_list, serialised_cedict_rec, merged_entry_card_id]
            ##prt " - Merging tags & meaning!"
            merge_counter = merge_counter + 1
          else
            # UPDATE VISIBLE MEANINGS & TAGS
            return_sql_arr << @update_tags_sql % [mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), all_tags_list, serialised_cedict_rec, merged_entry_card_id]
            ##prt " - Merging tags only!"
            merge_counter = merge_counter + 1
          end
        end # duplicates_arr.each do
      else

        # Serialise for storage in DB
        serialised_cedict_hash = mysql_serialise_ruby_object(cedict_rec)

        # INSERT NEW ENTRY
        meanings_txt, meanings_html, meanings_fts = get_formatted_meanings(cedict_rec)
        # MMA - what does this do?
#        update_hash_mtxt_arr = meanings_txt.split($delimiters[:jflash_meanings])

#        for i in 0..update_hash_mtxt_arr.size-1
#          cedict_rec[:meanings][i][:sense] = update_hash_mtxt_arr[i]
#        end
 
        all_tags_list = Parser.combine_and_uniq_arrays(cedict_rec.all_tags).join($delimiters[:jflash_tag_coldata])
        return_sql_arr << @insert_entry_sql % [cn_headword_trad, cn_headword_simp, en_headword, cedict_rec.pinyin, cedict_rec.pinyin_diacritic,
            mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), mysql_escape_str(meanings_fts),
            (cedict_rec.classifier ? "'"+mysql_escape_str(cedict_rec.classifier)+"'" : "NULL"), all_tags_list,
            (cedict_rec.references.empty? ? "NULL" : "'"+mysql_escape_str(cedict_rec.references.join(";"))+"'"),
            (cedict_rec.is_only_redirect? ? "1" : "0"),
            (cedict_rec.has_variant ? "1" : "0"), (cedict_rec.is_erhua_variant ? "1" : "0"),
            (cedict_rec.is_proper_noun? ? "1" : "0"),
            (cedict_rec.variant_of ? "'"+mysql_escape_str(cedict_rec.variant_of)+"'" : "NULL"), serialised_cedict_hash]

        new_counter = new_counter + 1
      end

      # Return string of SQL commands to execute
      return_sql_arr.join("\n")
    end
  
    prt "Merged #{merge_counter}"
    prt "Inserted #{new_counter}"
  end

  # DESC: Check if duplicate exists in existing array, returns dupe edict2hashes
  def get_duplicates_by_headword_reading(cn_headword_trad, readings_str, existing_card_lookup, entry_scope = 0)
    duplicates = []
    if existing_card_lookup.has_key?(entry_scope)
      if existing_card_lookup[entry_scope][cn_headword_trad]
        existing_card_lookup[entry_scope][cn_headword_trad].each do |card_id|
          cedict_entry = get_existing_card_hash_optimised(card_id)
          if readings_str == cedict_entry.pinyin
            duplicates << cedict_entry
          end
        end
      end
    end
    return duplicates
  end

  # DESC: Get edict2hash as specified by card_id, caches to memory
  def get_existing_card_hash_optimised(card_id)
    if $shared_cache[:existing_card_hashes].nil?
      connect_db
      $shared_cache[:existing_card_hashes] = {}
      tickcount("Caching existing card hashes once per run!") do
        $cn.execute("SELECT card_id, cedict_hash FROM cards_staging").each do |cid, cedict_hash|
          $shared_cache[:existing_card_hashes][cid] = cedict_hash
        end
      end
    end

    # Add the card_id onto the hash for merging back to DB
    deserialised_hash = mysql_deserialise_ruby_object($shared_cache[:existing_card_hashes][card_id])
    deserialised_hash.set_id(card_id)
    return deserialised_hash
  end

  # DESC: Merges existing entry with new entry, either combining existing senses, or appending new ones!
  def merge_duplicate_entries(new_entry, existing_entry)

    # WARNING: We modify existing_entry hash in the caller's scope!
    # WARNING: We modify existing_entry hash in the caller's scope!
    # WARNING: We modify existing_entry hash in the caller's scope!

    ### DEBUG ##  prt "existing_array << "; pp existing_entry; prt ""; prt "new_array << "; pp new_entry;   prt ""

    if existing_entry.meanings.size > 0
      original_str = existing_entry.meanings.collect {|m| m[:meaning]}.join($delimiters[:jflash_meanings])
    else
      original_str = ""
    end

    meaning_strings_merged = false
    new_entry.meanings.each do |new_meaning|

      glosses_to_append = {}
      related_gloss_found = {}

      new_pos_tags_per_sense = {}
      new_cat_tags_per_sense = {}
      new_lang_tags_per_sense = {}

      new_sense = new_meaning[:meaning]
      cleaned_new_sense = new_sense.gsub($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses])

      # NEW GLOSS LOOP ##########################################
      cleaned_new_sense.split(' / ').each do |new_gloss|

        found_gloss = false
        sense_number = 0
        new_gloss.strip!

        # LOOP: match new gloss to exisiting gloss (inside existing_meaning[:sense])
        existing_entry.meanings.each do |existing_meaning|

          sense_number = sense_number+1
          existing_sense = existing_meaning[:meaning]

          glosses_to_append[sense_number] = [] if glosses_to_append[sense_number].nil?
          related_gloss_found[sense_number] = false if related_gloss_found[sense_number].nil?

          # Compare each string without parentheticals!
          existing_sense = existing_sense.gsub($regexes[:parenthetical],"").gsub($regexes[:duplicate_spaces], "").strip
          new_gloss = new_gloss.gsub($regexes[:parenthetical],"").gsub($regexes[:duplicate_spaces], "").strip

          if existing_sense.scan(new_gloss).size > 0
            # If new_gloss already exists, merge the tags only
            related_gloss_found[sense_number] = true
            new_pos_tags_per_sense[sense_number] = "" #get_inline_tags_from_sense(new_sense, "pos")
            next
          else
            # If new_gloss does not exist, add append gloss
            glosses_to_append[sense_number] << new_gloss
          end

        end
      end

      # MERGE INTO EXISTING SENSES
      ###################################
      sense_number = 0
      existing_entry.meanings.each do |existing_meaning|
        
        sense_number = sense_number+1
        existing_sense = existing_meaning[:meaning]
        new_glosses = glosses_to_append[sense_number].join($delimiters[:jflash_glosses])

        # Merge in POS tags
        pos_tags_arr = [] #get_inline_tags_from_sense(existing_sense)
        if new_pos_tags_per_sense[sense_number] and new_pos_tags_per_sense[sense_number].size > 0
          pos_tags_arr << new_pos_tags_per_sense[sense_number]
          meaning_strings_merged = true
        end
        pos_tags_arr = Parser.combine_and_uniq_arrays(pos_tags_arr)
        pos_tag_suffix = (pos_tags_arr.size > 0 ? " (#{pos_tags_arr.join($delimiters[:jflash_inlined_tags])})" : "")
        
        # Merge in CAT tags
        cat_tags_arr = (existing_meaning[:cat].nil? ? [] : existing_meaning[:cat])
        if new_cat_tags_per_sense.has_key?(sense_number) and new_cat_tags_per_sense[sense_number].size > 0
          cat_tags_arr << new_cat_tags_per_sense[sense_number]
        end
        cat_tags_arr = Parser.combine_and_uniq_arrays(cat_tags_arr)

        if related_gloss_found[sense_number]
          # Update sense wth merged glosses & tags
          existing_entry.meanings[sense_number-1][:meaning] = existing_sense #clean_inlined_tags(existing_sense) + ( new_glosses.size > 0 ? $delimiters[:jflash_glosses] + new_glosses : "" ) + pos_tag_suffix
          existing_entry.meanings[sense_number-1][:tags] << pos_tags_arr
          existing_entry.meanings[sense_number-1][:tags] << cat_tags_arr
          meaning_strings_merged = true
        else
          # Recreate sense wth inline tags at end
          existing_entry.meanings[sense_number-1][:meaning] = existing_sense #clean_inlined_tags(existing_sense) + pos_tag_suffix
          existing_entry.meanings[sense_number-1][:tags] << pos_tags_arr
          existing_entry.meanings[sense_number-1][:tags] << cat_tags_arr
        end

        # Flatten down POS/CAT tag arrays
        existing_entry.meanings[sense_number-1][:tags] = Parser.combine_and_uniq_arrays(existing_entry.meanings[sense_number-1][:pos])
        existing_entry.meanings[sense_number-1][:tags] = Parser.combine_and_uniq_arrays(existing_entry.meanings[sense_number-1][:cat])

      end

    end

    ### Update references in case we merge
    ###################################
#    if !existing_entry[:jmdict_refs].nil?
#      merged_reference = Parser.combine_and_uniq_arrays(existing_entry[:jmdict_refs].split($delimiters[:jflash_jmdict_refs]), new_entry[:jmdict_refs])
#    else
#      merged_reference = []
#    end

#    existing_entry[:pos] = Parser.combine_and_uniq_arrays(existing_entry[:pos], new_entry[:pos])
#    existing_entry[:cat] = Parser.combine_and_uniq_arrays(existing_entry[:cat], new_entry[:cat])

    # Aggregate all tags including global and sense specific as ALL TAGS
 #   all_lang_tags_arr.flatten!
#    existing_entry[:all_tags] = Parser.combine_and_uniq_arrays(existing_entry[:pos], existing_entry[:cat], all_lang_tags_arr.collect{|l| l[:language] if l[:language]})
#    existing_entry[:jmdict_refs] = merged_reference

    ### DEBUG ##  prt "expected_array << "; pp existing_entry; prt ""
    return existing_entry, meaning_strings_merged
  end
  
  # DESC: Returns formatted meaning strings
  def get_formatted_meanings(cedict_rec, tag_mode="inhuman")
    meanings_html_arr  = []
    meanings_text_arr  = []
    meanings_fts_arr   = []

    sense_count = cedict_rec.meanings.size
    cedict_rec.meanings.each do |m|
      mtxt, mfts, mhtml = xfrm_inline_tags_with_meaning(cedict_rec.pos, m[:meaning], sense_count, tag_mode)
      meanings_html_arr << mhtml
      meanings_text_arr << mtxt
      meanings_fts_arr << mfts
    end

    meanings_txt  = join_meaning_entries_txt(meanings_text_arr)
    meanings_html = join_meaning_entries_html(meanings_html_arr)
    meanings_fts  = xfrm_remove_stop_words(meanings_fts_arr.join($delimiters[:jflash_meanings]))

    return meanings_txt, meanings_html, meanings_fts
  end

  ## TRANSFORM 
  def xfrm_inline_tags_with_meaning(tag_array, meaning_str, sense_count=1, tag_mode="inhuman")

    tag_buffer =[]
    inlined_tags = meaning_str.scan($regexes[:inlined_tags]).to_s

    # Extract trailing parentheticals, re-insert if not tags!
    meaning_str = meaning_str.gsub($regexes[:inlined_tags], "").strip
    inlined_tags.split($delimiters[:jflash_inlined_tags]).each do |m|
      tag_buffer << m if Entry.is_pos_tag?(m)
    end
    inlined_tags.strip!
    meaning_str.strip!

    if tag_buffer.size == 0 and inlined_tags != ""
      trailing_parentheticals = " (" + inlined_tags + ")"
    else
      trailing_parentheticals = ""
    end

    pos_tag_array = []
    if !tag_array.nil?
      tag_array.each do |t|
        if Entry.is_pos_tag?(t)
          pos_tag_array << (tag_mode == "inhuman" ? t : xfrm_pos_tag_to_human_tag(t))
        end
      end
      pos_tag_array.compact!
    end

    mfts  = meaning_str
    meaning_str = meaning_str + trailing_parentheticals
    mtxt  = (pos_tag_array.size > 0 ? meaning_str + " (" + pos_tag_array.join($delimiters[:jflash_inlined_tags]) + ")" : meaning_str)
    mhtml = (pos_tag_array.size > 0 ? meaning_str + " "  + pos_tag_array.collect{ |t| "<dfn>#{t}</dfn>" }.join("") : meaning_str)
    mhtml = "<li>#{mhtml}</li>" if sense_count > 1

    return mtxt, mfts, mhtml
  end

  # XFORMATION: Convenience method for returning humanised tags inline!
  def xfrm_inline_human_tags_with_meaning(tag_array, meaning_str, sense_count)
    return xfrm_inline_tags_with_meaning(tag_array, meaning_str, sense_count, "human")
  end

  # XFORMATION: Returns human tag name from the DB, caching everything on first call
  def xfrm_pos_tag_to_human_tag(tag)
    cache_tag_data if $shared_cache[:pos_tag_human_readings].nil?
    if $shared_cache[:pos_tag_human_readings].has_key?(tag)
      return $shared_cache[:pos_tag_human_readings][tag][:humanised]
    else
      return tag
    end
  end

  # DESC: Join TXT entries passed in array of strings
  def join_meaning_entries_txt(meaning_array)
    meaning_array.join($delimiters[:jflash_meanings])
  end

  # DESC: Join HTML entries passed in array of strings
  def join_meaning_entries_html(meaning_array)
    tmp = meaning_array.collect{ |d| d }.join("")
    if meaning_array.size > 1
      return "<ol>" + tmp + "</ol>"
    else
      return tmp
    end
  end

  # TODO - make me work like for real
  def self.add_group_links
    connect_db
    $cn.execute("INSERT INTO group_tag_link (tag_id,group_id) SELECT tag_id, 0 FROM tags_staging")
  end

  # DESC: Add tag link records to 'card_tag_link'
  def self.add_tag_links(visible_tag_array = [ $options[:system_tags]['LWE_FAVORITES'] ])

    connect_db
    tag_by_name_arr = {}
    data_en = nil

    # Note, we match on 'source name' column values
    tags = $cn.execute("SELECT tag_id, source_name FROM tags_staging WHERE source_name <> '' ORDER BY tag_id")

    tickcount("Caching Tags") do
      tags.each do |tag_id,source_name|

        if source_name.index($delimiters[:jflash_tag_coldata])
          # Handle multiple source names
          source_name.split($delimiters[:jflash_tag_coldata]).each do |sn|
            tag_by_name_arr[sn] = { :tag_id => tag_id }
          end
        else
          # Handle single source name
          tag_by_name_arr[source_name] = { :tag_id => tag_id }
        end

      end
    end

    tickcount("Selecting Cards") do
      data_en = $cn.execute("SELECT card_id, tags FROM cards_staging")
    end

    # Empty the table
    $cn.execute("TRUNCATE TABLE card_tag_link")

    # Not optimsied for batches, but it only takes 7 seconds for 21,000 recs
    tickcount("Looping n Inserting") do
      data_en.each do |card_id, tags|
        tags.split($delimiters[:jflash_tag_coldata]).each do |tag|
          vector = tag_by_name_arr[tag.strip]
          if vector.nil?
            tag_strip = tag.strip
            # Add missing tag to stack
            prt "Added missing tag: #{tag}"
            $cn.insert("INSERT INTO tags_staging (tag_name, description, source_name, source) values ('#{tag_strip}', '', '#{tag_strip}', 'edict')")
            the_tag = $cn.execute("SELECT tag_id, tag_name, source FROM tags_staging WHERE tag_name = '#{tag_strip}'")
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
          $cn.insert("INSERT INTO card_tag_link (tag_id, card_id) values (#{curr_tag_id}, #{card_id}) ON DUPLICATE KEY UPDATE tag_id = #{curr_tag_id}")
        end
      end
    end

    data = $cn.execute("SELECT t.tag_name, l.tag_id, count(l.card_id) as cnt FROM card_tag_link l INNER JOIN tags_staging t ON l.tag_id = t.tag_id GROUP BY l.tag_id ORDER BY cnt desc")
    $cn.execute("UPDATE tags_staging SET visible = 0 WHERE tag_id NOT IN (#{ visible_tag_array.join(",") })")

    prt "\nSummary of tag associations added..."
    prt "==========================================================================="
    data.each do |tag_name, tag_id, cnt|
      if cnt.to_i > 6
        $cn.execute("UPDATE tags_staging SET visible = 1 WHERE tag_id = #{tag_id}")
        prt "#{tag_id}\t\t#{cnt}\t\t#{tag_name}\t\t\t\t\t#{(cnt.to_i < 5 ? '** non-visible**' : '' )}"
      end
    end
    prt "==========================================================================="
    
  end

  # DESC: Humanise inlined tags, and then export tables
  def self.humanise_inline_tags_in_table(cards_table="cards_staging")
    prt "Bulk updating formatted meanings with humanised tag names"
    connect_db
    output_table = cards_table + "_humanised"
    $cn.execute("DROP TABLE IF EXISTS #{output_table}")
    $cn.execute("CREATE TABLE #{output_table} SELECT card_id, card_type, headword, alt_headword, headword_en, reading, romaji, meaning, meaning_html, meaning_fts, tags, ptag FROM #{cards_table}")
    $cn.execute("ALTER TABLE #{output_table} ADD PRIMARY KEY (card_id)")
    result_data = $cn.execute("SELECT card_id, cedict_hash FROM #{cards_table}")
    bulkSQL = BulkSQLRunner.new(0,10000)
    result_data.each do |card_id, edict2hash|
      edict2hash = mysql_deserialise_ruby_object(edict2hash)
      meanings_txt, meanings_html, meanings_fts = get_formatted_meanings(edict2hash, "human")
      bulkSQL.add("UPDATE #{output_table} SET meaning = \'#{mysql_escape_str(meanings_txt)}\',  meaning_html = \'#{mysql_escape_str(meanings_html)}\',  meaning_fts = \'#{mysql_escape_str(meanings_fts)}\' WHERE card_id = #{card_id};")
    end
    bulkSQL.flush # flush the remainder!
  end

  # DESC: Empty and update the headword/card_id 
  def self.create_headword_index

    connect_db
    $cn.execute("TRUNCATE TABLE idx_cards_by_headword_staging")
    bulkSQL = BulkSQLRunner.new(0, 0)

    tickcount("Recreating Headword Keyword-Index") do
      $cn.execute("SELECT card_id, headword_trad, reading FROM cards_staging").each do | card_id, headword, reading |
        bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{headword}');")
        reading.split($delimiters[:jflash_readings]).each do |keyword|
          bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{keyword}');")
        end
      end
    end
    
    bulkSQL.flush
    
  end


  # RETURNS: Hash of existing tag data 
  def self.get_existing_tags(table ="tags_staging", where = "source='edict'")
    hash = self.cache_sql_query( { :select => "source_name, short_name, source", :from => table, :where => where } ) do | sqlrow, cache_data |
      source_name = sqlrow['source_name']
      if source_name.index($delimiters[:jflash_tag_coldata])
        # handle multiple source names
        source_name.split($delimiters[:jflash_tag_coldata]).each do |sn|
          cache_data[sn] = sqlrow['name']
        end
      else
        # handle single source name
        cache_data[source_name] = sqlrow['name']
      end
    end
    return hash
  end

  # DESC: Returns the JFlash active tag data, separated by tag_type
  # RETURNS: Hash of tag source_names => tag_ids
  def self.get_existing_tags_by_type
    connect_db
    good_tags = {}

    # Get Good POS Tags from DB
    good_tags[:pos] = []
    results = $cn.select_all("SELECT source_name FROM tags_staging WHERE source = 'edict' AND tag_type ='pos' AND parent_tag_id IS NULL")
    results.each do |sqlrow|
      sqlrow['source_name'].split($delimiters[:jflash_tag_sourcenames]).each do |t|
        good_tags[:pos] << t
      end
    end
    
    # Get Good CAT Tags from DB
    good_tags[:cat] = []
    results = $cn.select_all("SELECT source_name FROM tags_staging WHERE tag_type ='cat' AND parent_tag IS NULL")
    results.each do |sqlrow|
      sqlrow['source_name'].split($delimiters[:jflash_tag_sourcenames]).each do |t|
        good_tags[:cat] << t
      end
    end
    
    # Get Good LANG Tags from DB
    good_tags[:lang] = []
    results = $cn.select_all("SELECT source_name FROM tags_staging WHERE source = 'edict' AND tag_type ='lang' AND parent_tag IS NULL")
    results.each do |sqlrow|
      sqlrow['source_name'].split($delimiters[:jflash_tag_sourcenames]).each do |t|
        good_tags[:lang] << t
      end
    end
    return good_tags
  end

  # Gets all tagsout of the cards_staging tag column and makes an array
  def self.create_tags_hash_from_tags_data
    connect_db
    # First get all of the tags from all cards
    tags = {}
    self.cache_sql_query( { :select => "tags", :from => "cards_staging", :where => "" } ) do | sqlrow, cache_data |
      # We are not taking data from multiple sources
      curr_row_tags = sqlrow['tags'].split(",")
      curr_row_tags.each do |tag|
        if !tags.has_key?(tag)
          tags[tag] = {}
          tags[tag][:count] = 1
        else
          tags[tag][:count] = tags[tag][:count] + 1
        end
      end
    end
    return tags
  end

  # Creates tables in the database from a passed in array of tags
  def self.create_tags_staging(tags = {})
    connect_db
    bulkSQL = BulkSQLRunner.new(tags.size, 30000, false)
    insert_tag_sql = "INSERT INTO tags_staging (tag_name,tag_type,short_name,description,source_name,source,visible,count,parent_tag_id,force_off) VALUES ('%s','%s','%s','%s','%s','%s',%s,%s,%s,%s);"
    tags.each do |key, tag_data|
      bulkSQL.add(insert_tag_sql % [key,"",key,key,key,key,"1",tag_data[:count],"0","0"])
    end
  end

  def ___BELOW_HERE_WE_DONT_USE_THE_METHODS_______
    # This function exists to help me with TextWranglers lack of a #pragma mark
  end

#========================================
# probably not going to need these
#========================================
  # DESC: Splits large tag sets based on REL1.0 data
  # TODO: THIS CAN BE A SMALLER METHOD!!!
  def self.create_size_limited_tags_based_on_rel1
    connect_db
    
    prt "Splitting large sets based on previous version's set splits"
    prt_dotted_line

    arbitrarily_high_starting_point_for_new_tag_ids = 20000
    
    # Clean  up
    $cn.execute("TRUNCATE TABLE card_tag_link_migration")

    # Get all previous version tags that were split
    parent_tags_results = $cn.execute("SELECT parent_tag_id FROM tags_staging_rel1 WHERE parent_tag_id IS NOT NULL GROUP BY parent_tag_id")
    parent_tags_results.each do |rec|
    
      new_cards_array = []               # Holds an array of ALL cards for this parent tag ID
      new_grouping_hash = {}             # Holds a hash of arrays for each child tag ID (inc. parent)
      old_grouping_hash = {}             # Holds a hash of arrays for each child tag ID (inc. parent)
      to_be_removed_hash = {}
      to_be_added_hash   = {}
      tag_name_hash      = {}
      desc_hash      = {}
    
      parent_tag_id = rec[0]
      $cn.execute("SELECT tag_name,description FROM tags_staging WHERE tag_id = %s ORDER BY tag_id ASC" % parent_tag_id).each do |result|
        tag_name_hash[parent_tag_id] = result[0]
        desc_hash[parent_tag_id] = result[1]
      end

      #=======================================================
      prt "Populating old_grouping_hash for parent tag_id #{parent_tag_id} (#{tag_name_hash[parent_tag_id]})"
      #=======================================================
      # First cache parent itself
      old_grouping_hash[parent_tag_id] = []
      parent_cards_results = $cn.execute("SELECT card_id FROM card_tag_link_rel1 WHERE tag_id = %s" % parent_tag_id)
      parent_cards_results.each do |card_rec|
        card_id = card_rec[0]
        old_grouping_hash[parent_tag_id] << card_id
      end
      
      # Now deal with each child
      child_tags_results = $cn.execute("SELECT tag_id,tag_name,description FROM tags_staging_rel1 WHERE parent_tag_id = %s" % parent_tag_id)
      child_tags_results.each do |child_rec|
        child_tag_id = child_rec[0]
        tag_name_hash[child_tag_id] = child_rec[1]
        desc_hash[child_tag_id] = child_rec[2]
        old_grouping_hash[child_tag_id] = []

        # Now get all cards in that particular child
        prt "--> Caching for child_tag_id #{child_tag_id} (#{tag_name_hash[child_tag_id]})"
        rel1_card_links = $cn.execute("SELECT card_id FROM card_tag_link_rel1 WHERE tag_id = %s" % child_tag_id)
        rel1_card_links.each do |card_rec|
          card_id = card_rec[0]
          old_grouping_hash[child_tag_id] << card_id
        end  # each card
      end  # each child tag

      #=======================================================
      prt "--> Caching new version's tags."
      #=======================================================
      new_cards_results = $cn.execute("SELECT card_id FROM card_tag_link WHERE tag_id = %s" % parent_tag_id)
      new_cards_results.each do |new_card_rec|
        new_cards_array << new_card_rec[0]
      end

      #=======================================================
      prt "--> Detecting cards to be added/removed..."
      #=======================================================
      to_be_added_array = new_cards_array
      # Loop through each old child (inc. parent)
      old_grouping_hash.each do |child_tag_id,card_id_array|
                
        # First, get an array of everything that needs to be removed from this child
        to_be_removed_hash[child_tag_id] = card_id_array - new_cards_array
        new_grouping_hash[child_tag_id] = card_id_array - to_be_removed_hash[child_tag_id]
        prt "--> Removing #{to_be_removed_hash[child_tag_id].size} cards from child tag_id #{child_tag_id}"
        to_be_removed_hash[child_tag_id].each do |card_id|
          sql_output = "INSERT INTO card_tag_link_migration (card_id, tag_id, to_add, to_remove) VALUES (%s,%s,0,1);"
          $cn.execute(sql_output % [card_id, child_tag_id])
        end
        to_be_added_array = to_be_added_array - card_id_array
      end

      old_grouping_hash.each do |child_tag_id,card_id_array|
        if (card_id_array.size == $options[:maximum_cards_per_tag])
          clearance_for_new_cards = to_be_removed_hash[child_tag_id].size 
        else
          clearance_for_new_cards = ($options[:maximum_cards_per_tag] - card_id_array.size) + to_be_removed_hash[child_tag_id].size
        end
        prt "--> Have room for #{clearance_for_new_cards}"
        
        # How many cards should we add to each set??
        if (to_be_added_array.size > clearance_for_new_cards)
          add_now_array = to_be_added_array[0..(clearance_for_new_cards-1)]
        else
          add_now_array = to_be_added_array
        end

        # Add the SQL
        prt "--> Adding #{add_now_array.size} cards to child_tag_id #{child_tag_id}"
        new_grouping_hash[child_tag_id] = new_grouping_hash[child_tag_id] + add_now_array
        add_now_array.each do |card_id|
          sql_output = "INSERT INTO card_tag_link_migration (card_id, tag_id, to_add, to_remove) VALUES (%s,%s,1,0);"
          $cn.execute(sql_output % [card_id, child_tag_id])
        end
        
        # And update the array
        to_be_added_array = to_be_added_array - add_now_array
      end
      
      #=======================================================
      prt "--> Inserting new child tags and updating card_tag_link..."
      #=======================================================
      sql_insert_query = "INSERT tags_staging (tag_id, tag_name, description, source, parent_tag_id, visible) VALUES (%s,'%s','%s','jflash-importer',%s,1)"
      sql_update_query = "UPDATE card_tag_link SET tag_id = %s WHERE tag_id = %s AND card_id = %s"
      new_grouping_hash.each do |child_tag_id, card_id_array|
        if child_tag_id != parent_tag_id
          $cn.execute(sql_insert_query % [child_tag_id,tag_name_hash[child_tag_id],desc_hash[child_tag_id],parent_tag_id])
          card_id_array.each do |card_id|
            $cn.execute(sql_update_query % [child_tag_id, parent_tag_id, card_id])
          end
        end
      end
      
      #=======================================================
      prt "--> Adding new child tags if necessary..."
      #=======================================================
      while (to_be_added_array.size > 0)
        if (to_be_added_array.size > $options[:maximum_cards_per_tag])
          add_now_array = to_be_added_array[0..($options[:maximum_cards_per_tag]-1)]
        else
          add_now_array = to_be_added_array
        end

        # add new tag to tags_staging and update membership
        new_grouping_hash[arbitrarily_high_starting_point_for_new_tag_ids] = add_now_array
        new_tag_name = tag_name_hash[parent_tag_id] + (" %02d" % (tag_name_hash.size + 1))
        $cn.execute(sql_insert_query % [arbitrarily_high_starting_point_for_new_tag_ids,new_tag_name,desc_hash[parent_tag_id],parent_tag_id])
        add_now_array.each do |card_id|
          sql_output = "INSERT INTO card_tag_link_migration (card_id, tag_id, to_add, to_remove) VALUES (%s,%s,1,0);"
          $cn.execute(sql_output % [card_id, arbitrarily_high_starting_point_for_new_tag_ids])
          $cn.execute(sql_update_query % [arbitrarily_high_starting_point_for_new_tag_ids, parent_tag_id, card_id])
        end
        prt "--> Added #{add_now_array.size} new cards to new child tag #{new_tag_name}"
        to_be_added_array = to_be_added_array - add_now_array
        arbitrarily_high_starting_point_for_new_tag_ids = arbitrarily_high_starting_point_for_new_tag_ids + 1
      end

      #=======================================================
      prt "--> Adding child tags to groups..."
      #=======================================================
      # Get parent folder for adding group_tag_link
      parent_group_id_array = []
      $cn.execute("SELECT group_id FROM group_tag_link WHERE tag_id = #{parent_tag_id}").each do |group_rec|
        parent_group_id_array << group_rec[0]
      end
      
      new_grouping_hash.each do |child_tag_id,card_id_array|
        if child_tag_id != parent_tag_id
          parent_group_id_array.each do |group_id|
            prt "--> Will add child #{child_tag_id} to group_id #{group_id}"
            $cn.insert("INSERT INTO group_tag_link (group_id, tag_id) VALUES (#{group_id}, #{child_tag_id})")
          end
        end
      end

      prt "Finished updating for parent_tag: #{parent_tag_id}"
      prt_dotted_line
    end  # each parent tag
    prt "Updating tag counts..."
    $cn.execute("UPDATE tags_staging t SET count = (SELECT count(tag_id) FROM card_tag_link cl WHERE cl.tag_id = t.tag_id)")
    prt "...done!"
    prt_dotted_line
  end




  # DESC: Limits tag size, creating additional numbered sets if max size is exceeded"
  # MMA - 6_21_2010 - don't use this guy because he does not play well with MERGING with old tag IDs.
  # USE instead - create_size_limited_tags_based_on_rel1
  def self.limit_tag_size_DO_NOT_USE(max_per_tag = $options[:maximum_cards_per_tag])

    connect_db

    #--- Make sure tag counts are up to date! ----
    $cn.execute("UPDATE tags_staging SET count = 0")
    $cn.execute("UPDATE tags_staging t SET count = (SELECT count(tag_id) FROM card_tag_link cl WHERE cl.tag_id = t.tag_id)")

    # For tags exceeding maximum set size (10,000) ... create additional tags (eg. Noun 1, Noun 2) and reassign
    prt "\n\nCarving up large sets into smaller groups of sets!"
    prt_dotted_line
    
    if !mysql_col_exists("card_tag_link.tmpid")
      prt "Adding temporary id to card_tag_link"
      $cn.execute("ALTER TABLE card_tag_link ADD COLUMN tmpid int(11) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (tmpid);") # add tmpid column
    end

    $cn.execute("SELECT tag_name, tag_id, count, description FROM tags_staging WHERE count > #{max_per_tag}").each do | tag_name, tag_id, count, description |

      parent_group_id_arr=[]
      tags_needed = (count.to_i - (count.to_i % max_per_tag)) / max_per_tag + (count.to_i % max_per_tag > 0 ? 1 : 0)
      prt "\nTag: #{tag_name} (#{count})\nTags Needed: #{tags_needed}"

      # Get parent folder for adding group_tag_link
      $cn.execute("SELECT group_id FROM group_tag_link WHERE tag_id = #{tag_id}").each do |group_id|
        parent_group_id_arr << group_id
      end

      (2..tags_needed).each do |counter|

        ## Added "%02d" without testing closely!
        new_child_tag_id = $cn.insert("INSERT INTO tags_staging (tag_name, description, source, parent_tag_id, visible) VALUES ('#{tag_name} #{"%02d" % counter}', '(cont) #{description}', 'jflash-importer', #{tag_id}, 1)")

        ### Add group_tag_link for each association of the parent (it appears where the parent does!)
        parent_group_id_arr.each do |group_id|
          $cn.insert("INSERT INTO group_tag_link (group_id, tag_id) VALUES (#{group_id}, #{new_child_tag_id})")
        end

        limit_num_recs = (counter < tags_needed ? max_per_tag : count.to_i - (max_per_tag * (tags_needed-1)) )
        limit_offset = max_per_tag
        cntrec=0

        prt "New Tag ID #{new_child_tag_id}"
        prt_dotted_line

        # Updates each card_tag_link.tag_id separately
        $cn.execute("SELECT tmpid FROM card_tag_link WHERE tag_id = #{tag_id} LIMIT #{limit_offset}, #{limit_num_recs}").each do | tmpid |
          cntrec +=1
          $cn.execute("UPDATE card_tag_link SET tag_id = #{new_child_tag_id} WHERE tmpid = #{tmpid}")
        end
        prt "Looped thru updater loop #{cntrec} times"

        # Update child tag count
        new_count = $cn.select_one("SELECT count(tag_id) as cnt FROM card_tag_link WHERE tag_id = #{new_child_tag_id}")["cnt"]
        $cn.execute("UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{new_child_tag_id}")
        prt "New tag cnt: #{new_count}\nUPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{new_child_tag_id}"

      end

      # Update parent tag count (should be 10,000)
      new_count = $cn.select_one("SELECT count(tag_id) as cnt FROM card_tag_link WHERE tag_id = #{tag_id}")["cnt"]
      $cn.execute("UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{tag_id}")
      prt "Orig tag cnt: #{new_count}"
      prt "UPDATE tags_staging SET count = #{new_count} WHERE tag_id = #{tag_id}"

    end

    # Remove tmpid column
    prt "Removing temporary id column"
    $cn.execute("ALTER TABLE card_tag_link DROP tmpid") # drop tmpid column

  end


  # DESC: For kana only headwords, use readings to match for a duplicate

  # DESC: Ensures each JLPT tagged card is included in lower levels using CONCAT
  def self.add_jlpt_tags
    connect_db
    prt "Adding additional JLPT set membership tags to existing JLPT cards"
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt3,',tags) WHERE tags like '%jlpt4%' AND tags not like '%jlpt3%'")
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt2,',tags) WHERE tags like '%jlpt3%' AND tags not like '%jlpt2%'")
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt1,',tags) WHERE tags like '%jlpt2%' AND tags not like '%jlpt1%'")
  end

  # DESC: Overrides base method, passing in data from jFlashImport staging tables
  def self.separate_romaji_readings(forced=true)

    connect_db

    source_query = nil
    sql_cond = (forced ? "" : "WHERE (romaji is NULL OR romaji = '' OR romaji = 'NULL' AND reading NOT LIKE '%;%') ")
    count = $cn.select_one("SELECT count(card_id) as cnt FROM cards_staging #{sql_cond}")["cnt"]

    tickcount("Selecting Cards") do
      source_query = $cn.execute("SELECT card_id, headword, reading, romaji FROM cards_staging #{sql_cond}")
    end

    existing_readings_hash = {}
    source_query.each do |card_id, headword, reading, romaji|
      # JUMAN doesn't handle multiple readings, so ignore readings containing a comma
      if !reading.index(",")
        existing_readings_hash[card_id] = { :headword => headword, :reading => reading, :romaji => romaji }
      end
    end

    result_data = super(existing_readings_hash, forced)

    bulkSQL = BulkSQLRunner.new(0, 50000)
    tickcount("Creating Romaji Update Statements") do
      result_data.each do |rec|
        if !rec[:romaji].nil?
          bulkSQL.add("UPDATE cards_staging SET romaji = \'#{mysql_escape_str(rec[:romaji])}\' WHERE card_id = #{rec[:card_id]};")
        end
      end
    end
    bulkSQL.flush

=begin
    max_per_run = 200000
    total_pages = (count.to_i - (count.to_i % max_per_run)) / max_per_run + (count.to_i % max_per_run)
    (1..total_pages).each do |counter|
      tickcount("Selecting Cards") do
        limit_num_recs = (counter < total_pages ? (counter-1) * max_per_run + 1 : count.to_i - (max_per_run * (total_pages-1)) )
        limit_cond = "LIMIT #{max_per_run}, #{limit_num_recs}"
        source_query = $cn.execute("SELECT card_id, headword, reading, romaji FROM cards_staging #{sql_cond} #{limit_cond}")
        pp "SELECT card_id, headword, reading, romaji FROM cards_staging #{sql_cond} #{limit_cond}"
      end
      existing_readings_hash = {}
      source_query.each do |card_id, headword, reading, romaji|
        # JUMAN doesn't handle multiple readings, so ignore readings containing a comma
        if !reading.index(",")
          existing_readings_hash[card_id] = { :headword => headword, :reading => reading, :romaji => romaji }
        end
      end
      result_data = super(existing_readings_hash, forced)
      bulkSQL = BulkSQLRunner.new(0, 10000)
      tickcount("Creating Romaji Update Statements") do
        result_data.each do |rec|
          if !rec[:romaji].nil?
            bulkSQL.add("UPDATE cards_staging SET romaji = \'#{mysql_escape_str(rec[:romaji])}\' WHERE card_id = #{rec[:card_id]};")
          end
        end
      end
      bulkSQL.flush
    end
=end
  end

  # DESC: Removes inlined tags from the sense string
  def self.clean_inlined_tags(sense)
    tags = get_inline_tags_from_sense(sense).flatten
    if tags.size > 0
      return sense.gsub($regexes[:inlined_tags],"").strip.gsub($regexes[:leading_trailing_slashes], "").strip
    else
      return sense.strip.gsub($regexes[:leading_trailing_slashes], "").strip
    end
  end

  # DESC: Returns the tags contained in the sense string passed
  def self.get_inline_tags_from_sense(sense, type="pos")
    out_arr=[]
    return [] if sense.nil?
    # Ensure no spaces appear after commas in tag string
    tags = sense.scan($regexes[:inlined_tags]).flatten.to_s.gsub(/,\s*/, $delimiters[:jflash_tag_coldata]).split($delimiters[:jflash_tag_coldata])
    if tags.size > 0
      tags.each do |tag|
        if Edict2Parser.is_pos_tag?(tag) and type == "pos"
          out_arr << tag
        elsif Edict2Parser.is_pos_tag?(xfrm_pos_tag_to_inhuman_tag(tag)) and type == "pos"
          out_arr << xfrm_pos_tag_to_inhuman_tag(tag)
        elsif Edict2Parser.is_language_tag?(tag) and type == "lang"
          out_arr <<  tag
        elsif type == "cat"
          out_arr << tag
        end
      end
    end
    return out_arr
  end

  # XFORMATION: Return meaning with tags inlined
  
  # XFORMATION: Returns inhuman tag name from the DB, caching everything on first call
  def self.xfrm_pos_tag_to_inhuman_tag(tag)
    cache_tag_data if $shared_cache[:pos_tag_inhuman_readings].nil?
    if $shared_cache[:pos_tag_inhuman_readings].has_key?(tag)
      return $shared_cache[:pos_tag_inhuman_readings][tag][:inhumanised]
    else
      return tag
    end
  end

  # RETURNS: Existing headword lookup data
  def self.get_existing_headwords
    hash = self.cache_sql_query( { :select => "card_id, keyword", :from => "idx_cards_by_headword_staging" } ) do | sqlrow, cache_data |
      # Store rows in hash
      cache_data[sqlrow['keyword']] = sqlrow['card_id']
    end
    return hash
  end

  # DESC: Clean up meaning string for comparison purposes
  def self.clean_meaning_for_comparison(meaning)
    out = []
    meaning.split($delimiters[:jflash_meanings]).each do |m|
      m = clean_inlined_tags(m)
      m = m.gsub($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses]).strip.gsub($regexes[:leading_trailing_slashes], "").strip
      out << m
    end
    out.join($delimiters[:jflash_meanings])
  end

  # CLEAN out the child tags
  def self.delete_child_tags
    connect_db
    prt_dotted_line
    prt "Deleting child tags from group_tag_link..."
    $cn.execute("DELETE FROM group_tag_link WHERE tag_id IN (SELECT tag_id FROM tags_staging WHERE parent_tag_id IS NOT NULL)") # Delete all non-parent tag group link recs
    prt "Deleting child tags from tags_staging..."
    $cn.execute("DELETE FROM tags_staging WHERE parent_tag_id IS NOT NULL") # Delete all non-parent tags!
    prt_dotted_line
  end




end
