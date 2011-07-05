#### JFLASH IMPORTER #####
class JFlashImporter < Importer

  # DESC: Overridden base class import method
  def import

    # Set filter by common flag
    @config[:filter_by_common] = false

    # Cache exiting cards/tags into hashes
    existing_card_lookup = self.class.get_existing_cards

    # MERGE_NEW Counters
    merge_counter=0
    new_counter=0
    
    # Call 'super' method to process loop for us
    super do |edict2_hash_rec|

      meanings_txt = ""
      meanings_html = ""
      meanings_html = ""

      # 0 - If filtering by common_only, check it is common before proceeding
      if !@config[:filter_by_common] || (@config[:filter_by_common] && edict2_hash_rec[:common])

        return_sql_arr = []
        ja_headword = ""
        other_ja_headwords = ""
        other_ja_headwords_arr = []
        en_headword = ""
        readings = ""

        @update_entry_sql = "UPDATE cards_staging SET headword_en='%s', meaning='%s', meaning_html='%s', meaning_fts='%s', tags='%s', jmdict_refs = '%s', edict2hash = '%s' WHERE card_id = %s;"
        @update_tags_sql  = "UPDATE cards_staging SET meaning = '%s', meaning_html = '%s', tags='%s', jmdict_refs ='%s', edict2hash = '%s' WHERE card_id = %s;"
        @insert_entry_sql = "INSERT INTO cards_staging (headword,alt_headword,headword_en,reading,romaji,meaning,meaning_html,meaning_fts,tags,card_type,ptag,jmdict_refs,edict2hash) VALUES ('%s','%s','%s','%s','%s','%s','%s', '%s', '%s', %s, %s, '%s', '%s');"

        # Processing flags
        duplicate_exists = false

        # 1 - Collate JA headwords into strings
        edict2_hash_rec[:headwords].each do |hw|
          if ja_headword.empty? && hw[:priority].size > 0
            ja_headword = hw[:headword]
          else
            other_ja_headwords_arr << hw[:headword]
          end
        end
        if ja_headword.empty?
          ja_headword = other_ja_headwords_arr.first
          other_ja_headwords_arr.delete_at(0)
          other_ja_headwords = other_ja_headwords_arr.join($delimiters[:jflash_headwords])
        end

        # 2 - Generate EN headword
        if edict2_hash_rec[:meanings].size>0
          en_headword = self.class.xfrm_extract_en_headword(edict2_hash_rec[:meanings].first[:sense].strip)
        else
          en_headword = ""
        end      

        # 3 - Collate Readings into string, generate romaji
        romaji_str = ""
        readings_str = ""
        edict2_hash_rec[:readings].each do |r|
          if readings_str.size > 0
            readings_str = readings_str + $delimiters[:jflash_readings] + r[:reading].to_s
            romaji_str   = romaji_str   + $delimiters[:jflash_readings] + r[:romaji].to_s if r[:romaji].size > 0
          else
            readings_str = r[:reading].to_s
            romaji_str   = r[:romaji].to_s if r[:romaji].size > 0
          end
        end
        romaji_str = mysql_escape_str(romaji_str)

        # 4 - Duplicate check by Headword & Readings
        duplicates_arr = self.class.get_duplicates_by_headword_reading(ja_headword, readings_str, existing_card_lookup, @config[:entry_type])
      
        # 5 - Skip unmatched entries with empty meanings?
        if @config[:skip_empty_meanings] and edict2_hash_rec[:meanings].size == 0 and duplicates_arr.size == 0
          skip_import = true
          @config[:skipped_data] << edict2_hash_rec
        else
          skip_import = false
        end

        # 6 - Merge with duplicates
        if duplicates_arr.size > 0

          # LOOP through each possible duplicate and go
          duplicates_arr.each do |dupe|

            # Merge existing, format meaning variously, do tags and refs
            merged_entry, meaning_strings_merged = self.class.merge_duplicate_entries(edict2_hash_rec, dupe)
            meanings_txt, meanings_html, meanings_fts = self.class.get_formatted_meanings(merged_entry)
          
            jmdict_ref_list = Parser.combine_and_uniq_arrays(merged_entry[:jmdict_refs]).join($delimiters[:jflash_jmdict_refs])
            all_tags_list = Parser.combine_and_uniq_arrays(merged_entry[:all_tags]).join($delimiters[:jflash_tag_coldata])

            # Serialise for storage in DB
            serialised_edict2_hash = mysql_serialise_ruby_object(merged_entry)

            # Remove embedded card_id from hash 
            merged_entry_card_id = merged_entry[:card_id].to_i
            merged_entry.delete(:card_id)

            if meaning_strings_merged

              # UPDATE HEADWORD_EN, MEANINGS & TAGS
              return_sql_arr << @update_entry_sql % [ en_headword, mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), mysql_escape_str(meanings_fts), all_tags_list, jmdict_ref_list, serialised_edict2_hash, merged_entry_card_id]
              ##prt " - Merging tags & meaning!"
              merge_counter=merge_counter+1

            else

              # UPDATE VISIBLE MEANINGS & TAGS
              return_sql_arr << @update_tags_sql % [mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), all_tags_list, jmdict_ref_list, serialised_edict2_hash, merged_entry_card_id]
              ##prt " - Merging tags only!"
              merge_counter=merge_counter+1

            end
          end

        elsif !skip_import

          # Serialise for storage in DB
          serialised_edict2_hash = mysql_serialise_ruby_object(edict2_hash_rec)

          # INSERT NEW ENTRY
          meanings_txt, meanings_html, meanings_fts = self.class.get_formatted_meanings(edict2_hash_rec)
          update_hash_mtxt_arr = meanings_txt.split($delimiters[:jflash_meanings])

          begin
            for i in 0..update_hash_mtxt_arr.size-1
              edict2_hash_rec[:meanings][i][:sense] = update_hash_mtxt_arr[i]
            end
          rescue
            # This will trigger if extraneous semi-colons are not removed!!
            pp "ERROR - This will trigger if extraneous semi-colons are not removed!!"
            pp update_hash_mtxt_arr
            debugger
          end
        
          all_tags_list = Parser.combine_and_uniq_arrays(edict2_hash_rec[:all_tags]).join($delimiters[:jflash_tag_coldata])
          jmdict_ref_list = Parser.combine_and_uniq_arrays(edict2_hash_rec[:jmdict_refs]).join($delimiters[:jflash_jmdict_refs])
          return_sql_arr << @insert_entry_sql % [ja_headword, other_ja_headwords, en_headword, readings_str, romaji_str, mysql_escape_str(meanings_txt), mysql_escape_str(meanings_html), mysql_escape_str(meanings_fts), all_tags_list, @config[:entry_type], (edict2_hash_rec[:common] ? "1" : "0"), jmdict_ref_list, serialised_edict2_hash]
          new_counter=new_counter+1

        end
        ### WARNING: We are NOT currently inling (see ...) or (... only) references! ###

      end

      # Return string of SQL commands to execute
      return_sql_arr.join("\n")
    end
  
    prt "Merged #{merge_counter}"
    prt "Inserted #{new_counter}"
  end

  # DESC: Caches staging database tag data
  def self.cache_tag_data
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

  # DESC: Check if duplicate exists in existing array, returns dupe edict2hashes
  def self.get_duplicates_by_headword_reading(ja_headword, readings_str, existing_card_lookup, entry_scope=0)

    duplicates = []
    if existing_card_lookup.has_key?(entry_scope)

      ##prt "Headword #{ja_headword}"
      if existing_card_lookup[entry_scope][ja_headword]
        ##prt "Found headword!"
        existing_card_lookup[entry_scope][ja_headword].each do |card_id|
          edict2hash = get_existing_card_hash_optimised(card_id)
          ##prt "Matching reading #{readings_str}"
          edict2hash[:readings].each do |r|
            if readings_str.split($delimiters[:jflash_readings]).index(r[:reading])
              duplicates << edict2hash
              ##prt "Dupe match for #{ja_headword} #{r[:reading]}"
            end
          end
        end

      # Kana only headwords
      elsif ja_headword.scan($regexes[:not_kana_nor_basic_punctuation]).size == 0
        dupe = get_kana_only_duplicate_by_reading_optimised(ja_headword, entry_scope)
        duplicates << dupe if !dupe.nil?
      end
    end

    return duplicates
  end

  # DESC: For kana only headwords, use readings to match for a duplicate
  def self.get_kana_only_duplicate_by_reading(ja_headword, entry_scope)
    # Look for dupes by reading, only use if there is exactly ONE match
    connect_db
    first_matched = nil
    
    count = $cn.select_one("SELECT count(card_id) as cnt FROM cards_staging WHERE reading = '#{ja_headword}' and card_type=#{entry_scope}")["cnt"].to_i
    if count == 1
      existing_lookup = get_existing_cards("cards_staging", "reading = '#{ja_headword}'")
      first_matched_card_id = existing_lookup[entry_scope].first[1][0]
      first_matched = get_existing_card_hash_optimised(first_matched_card_id)
      ##prt "Merging Kana-Only Headword: #{ja_headword} to #{first_matched['headword']} / #{first_matched['reading']} (ID-#{first_matched['card_id']})"
    end
    return first_matched
  end

  # DESC: OPTIMISED!! For kana only headwords, use readings to match for a duplicate
  def self.get_kana_only_duplicate_by_reading_optimised(ja_headword, entry_scope)
    # Look for dupes by reading, only use if there is exactly ONE match
    connect_db
    first_matched = nil
    
    if $shared_cache[:existing_card_by_reading].nil?
      connect_db
      $shared_cache[:existing_card_by_reading] = {}
      tickcount("Caching existing card readings once per run!") do
        $cn.execute("SELECT card_id, card_type, reading FROM cards_staging").each do |card_id, card_type, reading|
          card_type = card_type.to_i
          $shared_cache[:existing_card_by_reading][card_type] = {} if !$shared_cache[:existing_card_by_reading].has_key?(card_type)
          $shared_cache[:existing_card_by_reading][card_type][reading] = [] if !$shared_cache[:existing_card_by_reading][card_type].has_key?(reading)
          $shared_cache[:existing_card_by_reading][card_type][reading] << card_id
        end
      end
    end
    
    if ($shared_cache[:existing_card_by_reading].has_key?(entry_scope) and
       $shared_cache[:existing_card_by_reading][entry_scope].has_key?(ja_headword) and 
       $shared_cache[:existing_card_by_reading][entry_scope][ja_headword].size == 1)
       matched_card_id = $shared_cache[:existing_card_by_reading][entry_scope][ja_headword].to_s
       first_matched = get_existing_card_hash_optimised(matched_card_id)
    end
    return first_matched
  end

  # DESC: Merges existing entry with new entry, either combining existing senses, or appending new ones!
  def self.merge_duplicate_entries(new_entry, existing_entry)

    # WARNING: We modify existing_entry hash in the caller's scope!
    # WARNING: We modify existing_entry hash in the caller's scope!
    # WARNING: We modify existing_entry hash in the caller's scope!

    ### DEBUG ##  prt "existing_array << "; pp existing_entry; prt ""; prt "new_array << "; pp new_entry;   prt ""

    if existing_entry[:meanings].size > 0
      original_str = existing_entry[:meanings].collect {|m| m[:sense]}.join($delimiters[:jflash_meanings])
    else
      original_str = ""
    end

    meaning_strings_merged = false
    all_lang_tags_arr = []
    new_entry[:meanings].each do |new_meaning|

      glosses_to_append = {}
      related_gloss_found = {}

      new_pos_tags_per_sense = {}
      new_cat_tags_per_sense = {}
      new_lang_tags_per_sense = {}

      new_sense = new_meaning[:sense]
      cleaned_new_sense = new_sense.gsub($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses])

      # NEW GLOSS LOOP ##########################################
      cleaned_new_sense.split(' / ').each do |new_gloss|

        found_gloss = false
        sense_number=0
        new_gloss.strip!

        # LOOP: match new gloss to exisiting gloss (inside existing_meaning[:sense])
        existing_entry[:meanings].each do |existing_meaning|

          sense_number = sense_number+1
          existing_sense = existing_meaning[:sense]

          glosses_to_append[sense_number] = [] if glosses_to_append[sense_number].nil?
          related_gloss_found[sense_number] = false if related_gloss_found[sense_number].nil?

          # Compare each string without parentheticals!
          existing_sense = existing_sense.gsub($regexes[:parenthetical],"").gsub($regexes[:duplicate_spaces], "").strip
          new_gloss = new_gloss.gsub($regexes[:parenthetical],"").gsub($regexes[:duplicate_spaces], "").strip

          if existing_sense.scan(new_gloss).size > 0
            # If new_gloss already exists, merge the tags only
            related_gloss_found[sense_number] = true
            new_pos_tags_per_sense[sense_number] = get_inline_tags_from_sense(new_sense, "pos")
            new_cat_tags_per_sense[sense_number] = new_meaning[:cat] if new_meaning[:cat]
            new_lang_tags_per_sense[sense_number] = new_meaning[:lang] if new_meaning[:lang]
            next
          else
            # If new_gloss does not exist, add append gloss
            glosses_to_append[sense_number] << new_gloss
          end

        end
      end

      # MERGE INTO EXISTING SENSES
      ###################################
      sense_number=0
      existing_entry[:meanings].each do |existing_meaning|
        
        sense_number = sense_number+1
        existing_sense = existing_meaning[:sense]
        new_glosses = glosses_to_append[sense_number].join($delimiters[:jflash_glosses])

        # Merge in POS tags
        pos_tags_arr = get_inline_tags_from_sense(existing_sense)
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

        # Merge in CAT tags
        lang_tags_arr = []
        if new_lang_tags_per_sense.has_key?(sense_number) and new_lang_tags_per_sense[sense_number].size > 0
          lang_tags_arr << new_lang_tags_per_sense[sense_number]
        end
        lang_tags_arr = Parser.combine_and_uniq_arrays(lang_tags_arr)
        all_lang_tags_arr << lang_tags_arr if lang_tags_arr.size > 0

        if related_gloss_found[sense_number]
          # Update sense wth merged glosses & tags
          existing_entry[:meanings][sense_number-1][:sense] = clean_inlined_tags(existing_sense) + ( new_glosses.size > 0 ? $delimiters[:jflash_glosses] + new_glosses : "" ) + pos_tag_suffix
          existing_entry[:meanings][sense_number-1][:pos] << pos_tags_arr
          existing_entry[:meanings][sense_number-1][:cat] << cat_tags_arr
          existing_entry[:meanings][sense_number-1][:lang] << lang_tags_arr
          meaning_strings_merged = true
        else
          # Recreate sense wth inline tags at end
          existing_entry[:meanings][sense_number-1][:sense] = clean_inlined_tags(existing_sense) + pos_tag_suffix
          existing_entry[:meanings][sense_number-1][:pos] << pos_tags_arr
          existing_entry[:meanings][sense_number-1][:cat] << cat_tags_arr
          existing_entry[:meanings][sense_number-1][:lang] << lang_tags_arr
        end

        # Flatten down POS/CAT/LANG tag arrays
        existing_entry[:meanings][sense_number-1][:pos] = Parser.combine_and_uniq_arrays(existing_entry[:meanings][sense_number-1][:pos])
        existing_entry[:meanings][sense_number-1][:cat] = Parser.combine_and_uniq_arrays(existing_entry[:meanings][sense_number-1][:cat])
        existing_entry[:meanings][sense_number-1][:lang] = Parser.combine_and_uniq_arrays(existing_entry[:meanings][sense_number-1][:lang])

      end

    end

    ### Update references in case we merge
    ###################################
    if !existing_entry[:jmdict_refs].nil?
      merged_reference = Parser.combine_and_uniq_arrays(existing_entry[:jmdict_refs].split($delimiters[:jflash_jmdict_refs]), new_entry[:jmdict_refs])
    else
      merged_reference = []
    end

    existing_entry[:pos] = Parser.combine_and_uniq_arrays(existing_entry[:pos], new_entry[:pos])
    existing_entry[:cat] = Parser.combine_and_uniq_arrays(existing_entry[:cat], new_entry[:cat])

    # Aggregate all tags including global and sense specific as ALL TAGS
    all_lang_tags_arr.flatten!
    existing_entry[:all_tags] = Parser.combine_and_uniq_arrays(existing_entry[:pos], existing_entry[:cat], all_lang_tags_arr.collect{|l| l[:language] if l[:language]})
    existing_entry[:jmdict_refs] = merged_reference

    ### DEBUG ##  prt "expected_array << "; pp existing_entry; prt ""
    return existing_entry, meaning_strings_merged
  end
  
  # DESC: Returns formatted meaning strings
  def self.get_formatted_meanings(edict2_hash, tag_mode="inhuman")
    meanings_html_arr  = []
    meanings_text_arr  = []
    meanings_fts_arr   = []

    first_meaning = true
    sense_count = edict2_hash[:meanings].size

    edict2_hash[:meanings].each do|m|

      # Clean any ; inside parentheses, this can break the importer
      sense = Edict2Parser.replace_one_char_in_parens(m[:sense].to_s, ";", ",")

      # 1) Remove meaning parenthetical prefixes, create txt & html strings
      mtxt = xfrm_reorder_parentheticals(sense).strip

      # 2) Add space-padding to forward slashes, remove trailing slashes
      mtxt = mtxt.strip.gsub($regexes[:leading_trailing_slashes], "").gsub($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses]).strip

      # 3) Inline pos tags with meaning strings
      if first_meaning
        global_and_local_pos_arr = Parser.combine_and_uniq_arrays(edict2_hash[:pos], m[:pos])
        mtxt, mfts, mhtml = xfrm_inline_tags_with_meaning(global_and_local_pos_arr, mtxt, sense_count, tag_mode)
      else
        mtxt, mfts, mhtml = xfrm_inline_tags_with_meaning(m[:pos], mtxt, sense_count, tag_mode)
      end

      meanings_html_arr << mhtml
      meanings_text_arr << mtxt
      meanings_fts_arr << mfts
      first_meaning = false
    end
    meanings_txt  = join_meaning_entries_txt(meanings_text_arr)
    meanings_html = join_meaning_entries_html(meanings_html_arr)
    meanings_fts  = xfrm_remove_stop_words(meanings_fts_arr.join($delimiters[:jflash_meanings]))

    return meanings_txt, meanings_html, meanings_fts

  end

  # XFORMATION: Return meaning with tags inlined
  def self.xfrm_inline_tags_with_meaning(tag_array, meaning_str, sense_count=1, tag_mode="inhuman")

    tag_buffer =[]
    inlined_tags = meaning_str.scan($regexes[:inlined_tags]).to_s

    # Extract trailing parentheticals, re-insert if not tags!
    meaning_str = meaning_str.gsub($regexes[:inlined_tags], "").strip
    inlined_tags.split($delimiters[:jflash_inlined_tags]).each do |m|
      tag_buffer << m if Edict2Parser.is_pos_tag?(m)
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
        if Edict2Parser.is_pos_tag?(t)
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
  def self.xfrm_inline_human_tags_with_meaning(tag_array, meaning_str, sense_count)
    return xfrm_inline_tags_with_meaning(tag_array, meaning_str, sense_count, "human")
  end
  
  # XFORMATION: Returns human tag name from the DB, caching everything on first call
  def self.xfrm_pos_tag_to_human_tag(tag)
    cache_tag_data if $shared_cache[:pos_tag_human_readings].nil?
    if $shared_cache[:pos_tag_human_readings].has_key?(tag)
      return $shared_cache[:pos_tag_human_readings][tag][:humanised]
    else
      return tag
    end
  end
  
  # XFORMATION: Returns inhuman tag name from the DB, caching everything on first call
  def self.xfrm_pos_tag_to_inhuman_tag(tag)
    cache_tag_data if $shared_cache[:pos_tag_inhuman_readings].nil?
    if $shared_cache[:pos_tag_inhuman_readings].has_key?(tag)
      return $shared_cache[:pos_tag_inhuman_readings][tag][:inhumanised]
    else
      return tag
    end
  end

  # DESC: Join TXT entries passed in array of strings
  def self.join_meaning_entries_txt(meaning_array)
    meaning_array.join($delimiters[:jflash_meanings])
  end

  # DESC: Join HTML entries passed in array of strings
  def self.join_meaning_entries_html(meaning_array)
    tmp = meaning_array.collect{ |d| d }.join("")
    if meaning_array.size > 1
      return "<ol>" + tmp + "</ol>"
    else
      return tmp
    end
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


  # Makes 1.1 tag Ids match 1.0 tag ids
  def self.match_rel1_tag_ids
    connect_db
    prt "Matching tag IDs to Rel 1.1 tag IDs"
    prt_dotted_line
    
    # Loop through each new tag and see if we need to update
    sql_data = $cn.execute("SELECT tag_id, tag_name FROM tags_staging");
    sql_data.each do | tag_id, tag_name |
      old_tag = $cn.execute("SELECT tag_id FROM tags_staging_rel1 WHERE tag_name = '#{mysql_escape_str(tag_name)}'");
      old_tag.each do | old_tag_array |
        old_tag_id = old_tag_array[0]
        if (old_tag_id != tag_id)
          # Update CARD_TAG_LINK and GROUP_TAG_LINK and TAGS with new ID
          sql_queries = []
          sql_queries << "UPDATE card_tag_link SET tag_id = %s WHERE tag_id = %s"
          sql_queries << "UPDATE group_tag_link SET tag_id = %s WHERE tag_id = %s"
          sql_queries << "UPDATE tags_staging SET tag_id = %s WHERE tag_id = %s"
          sql_queries.each do |query|
            query = query % [old_tag_id, tag_id]
            $cn.execute(query)
          end
          prt "Updated tag: #{tag_name} from id #{tag_id} to id #{old_tag_id}"
        end
      end # had old record
    end # each new tag
  end


  # Creates a SQLite-syntax output file for deletion  of dead card Ids
  def self.create_dead_card_id_sql(output_filename="dead_card_id_sql.txt")
    connect_db
    prt "Creating SQL file for deleting dead card ids"
    prt_dotted_line
    
    # Open the output file
    sql_file = File.new(output_filename,"w")
    
    # Now loop through the SQL
    sql_data =$cn.execute("SELECT card_id FROM cards_dead_rel1_card_ids")
    sql_data.each do | card_id |
      sql_output = "DELETE FROM card_tag_link WHERE card_id = %s\nDELETE FROM user_history WHERE card_id = %s\n"
      sql_file.write(sql_output % [card_id, card_id])
    end
    
    #Close the file
    sql_file.close
  end


  #---------------------------------------------------------------------------------
  # Diffs the two card_tag_link tables and creates an output file writing in SQL how to patch
  def self.create_card_tag_link_diff_sql(fn = "card_tag_link_diff.sql")
    connect_db
    prt "Creating SQL diff of card_tag_link between rel1 and current release using #{fn}"
    prt_dotted_line

    insert_array = []
    delete_array = []
    
    output_file = File.new(fn, "w")
    
    # Loop through each tag in the NEW table
    tags = $cn.execute("SELECT tag_id FROM tags_staging WHERE force_off = 0")
    tags.each do |rec|
      tag_id = rec[0]
      new_membership_array = []
      old_membership_array = []
      cards_to_add = []
      cards_to_remove = []

      # Get SQL hash results
      new_membership = $cn.execute("SELECT card_id FROM card_tag_link WHERE tag_id = %s" % tag_id)
      old_membership = $cn.execute("SELECT card_id FROM card_tag_link_rel1 WHERE tag_id = %s" % tag_id)
      
      # Collapse SQL hash result to simple arrays
      new_membership.each do |rec|
        new_membership_array << rec[0]
      end
      old_membership.each do |rec|
        old_membership_array << rec[0]
      end
      
      # NOW do the comparison
      cards_to_add = new_membership_array - old_membership_array
      cards_to_remove = old_membership_array - new_membership_array
      
      # Write out to the file
      cards_to_add.each do |added_card|
        insert_array << "INSERT INTO card_tag_link (card_id, tag_id) VALUES (%s,%s)\n" % [added_card, tag_id]
      end
      cards_to_remove.each do |removed_card|
        delete_array << "DELETE FROM card_tag_link WHERE card_id = %s AND tag_id = %s\n" % [removed_card, tag_id]
      end
      prt "Tag ID #{tag_id}: removing #{cards_to_remove.size}, adding #{cards_to_add.size}, new size is #{new_membership_array.size}" if ((cards_to_remove.size > 0) or (cards_to_add.size > 0))
    end

    insert_array.each { |sql| output_file.write(sql) }
    delete_array.each { |sql| output_file.write(sql) }
    output_file.close
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


  # Creates a SQLite-syntax output file for new tags (not in 1.0)
  def self.create_tag_diff_sql(output_filename="tag_diff_sql.txt")
    connect_db
    prt "Creating SQL file for newly-added tags"
    prt_dotted_line
    
    # Open the output file
    sql_file = File.new(output_filename,"w")
    
    new_tag_array = []
    old_tag_array = []
    tags_to_add = []
    
    # Get SQL hash results
    new_tags = $cn.execute("SELECT tag_id, tag_name, description, count FROM tags_staging WHERE force_off = 0")
    old_tags = $cn.execute("SELECT tag_id, tag_name, description, count FROM tags_staging_rel1 WHERE force_off = 0")
    
    new_tag_hash = {}
    
    # Collapse SQL hash result to simple arrays
    new_tags.each do |tag_id, tag_name, description, count|
      new_tag_array << tag_id
      new_tag_hash[tag_id] = [tag_name, description, count]
    end
    old_tags.each do |tag_id, tag_name, description, count|
      old_tag_array << tag_id
    end
    
    # NOW do the comparison
    tags_to_add = new_tag_array - old_tag_array
    
    # Write out to the file
    tags_to_add.each do |tag_id|
      sql_output = "INSERT INTO tags (tag_id, tag_name, description, editable, count) VALUES (%s,\"%s\",\"%s\",0,%s)\n"
      sql_file.write(sql_output % [tag_id, new_tag_hash[tag_id][0], new_tag_hash[tag_id][1], new_tag_hash[tag_id][2]])
    end
    
    #Close the file
    sql_file.close
  end



  # DESC: Exports contents of staging database to Sqlite file
  def self.export_staging_db_from_table(cards_table ="cards_staging_humanised", visible_tag_array = [ $options[:system_tags]['LWE_FAVORITES'], $options[:system_tags]['BAD_DATA'] ])

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

      ## Ensure no blank HTML meanings
      $cn.execute("UPDATE cards_staging SET meaning_html = meaning WHERE meaning_html IS NULL")

      ## Create intermediate tables
      $cn.execute("CREATE TABLE cards SELECT card_id, card_type, headword, headword_en, reading, romaji FROM #{cards_table}")
      $cn.execute("CREATE TABLE tags SELECT tag_id, tag_name, description, visible AS editable, count, force_off FROM tags_staging")
      $cn.execute("CREATE TABLE groups SELECT * FROM groups_staging")
      $cn.execute("CREATE TABLE cards_search_content SELECT card_id, headword, reading, romaji, meaning_fts, ptag FROM #{cards_table}")
      $cn.execute("CREATE TABLE cards_html SELECT card_id, meaning_html AS meaning FROM #{cards_table}")

      ## Generate the card search content table
      $cn.execute("ALTER TABLE cards_search_content ADD COLUMN content varchar(5000)")
      $cn.execute("UPDATE cards_search_content SET content = CONCAT(headword, ' [ ', reading, ' / ', romaji, ' / ',  REPLACE(romaji, \" \", \"\"),' ] ', meaning_fts);")
      $cn.execute("ALTER TABLE cards_search_content DROP headword")
      $cn.execute("ALTER TABLE cards_search_content DROP reading")
      $cn.execute("ALTER TABLE cards_search_content DROP romaji")
      $cn.execute("ALTER TABLE cards_search_content DROP meaning_fts")

      # Remove non-visible tags
      $cn.execute("DELETE FROM tags WHERE editable=0 OR force_off=1")

      # Set system tags to uneditable
      $cn.execute("UPDATE tags SET editable = 0 WHERE tag_id NOT IN (#{ visible_tag_array.join(",") })")
      $cn.execute("ALTER TABLE tags DROP force_off")
      

    prt "\n\nExporting tables to temporary file"
    prt_dotted_line

    ### EXPORT TO SQLITE
    #######################################

      sqlite_create_core
      sqlite_create_cards
      sqlite_create_fts

    prt_dotted_line
    prt "JFlash export complete\n"

  end

  # DESC: Update staging database card IDs to match jFlash REL 1.0 IDs
  def self.normalise_to_jflash_v1_ids(cards_table ="cards_staging")
    
    prt "Normalising to jFlash REL 1.0 IDs on #{cards_table} table"
    
    connect_db
    if !mysql_col_exists("#{cards_table}.staging_card_id")
      $cn.execute("ALTER TABLE #{cards_table} CHANGE card_id staging_card_id int(11) NOT NULL AUTO_INCREMENT;")
      $cn.execute("ALTER TABLE #{cards_table} ADD COLUMN card_id int(11) NOT NULL DEFAULT 0;") # Add jflash_card_id column
    else
      begin
        $cn.execute("ALTER TABLE #{cards_table} DROP INDEX card_id_uniq") #try!
      rescue
        # Do nothing!
      end
      $cn.execute("UPDATE #{cards_table} SET card_id = 0;") # Blank out target column
    end
    $cn.execute("UPDATE #{cards_table} c, card_migration_results m SET c.card_id = m.old_card_id WHERE m.new_card_id <> 0 AND m.new_card_id = c.staging_card_id")
    max_id = $cn.select_one("SELECT MAX(card_id) AS max_id FROM cards_staging_rel1")["max_id"].to_i
    counter = 0

    # Select all the NEW cards that did not exist in REL 1.0 (card_id = 0)
    bulkSQL = BulkSQLRunner.new(0, 0)
    $cn.execute("SELECT staging_card_id FROM #{cards_table} WHERE card_id = 0").each do |staging_card_id|
      counter+=1
      new_id = max_id + counter
      bulkSQL.add("UPDATE #{cards_table} SET card_id = #{new_id} WHERE staging_card_id = #{staging_card_id};")
    end
    bulkSQL.flush

    # Add an index to the table to ensure it is unique
    $cn.execute("ALTER TABLE #{cards_table} ADD INDEX card_id_idx_bollocks (card_id)")
    $cn.execute("ALTER TABLE #{cards_table} ADD UNIQUE INDEX card_id_uniq (card_id)")
  end


  # DESC: PREPARE AND DUMP THE CORE DATABASE
  def self.sqlite_create_core
    sql_tmp_out_fn = "tmp_jflash_sqlite_dump.sql"
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
    CREATE TABLE groups (group_id INTEGER PRIMARY KEY NOT NULL, group_name VARCHAR NOT NULL,owner_id INTEGER NOT NULL  DEFAULT 0, tag_count INTEGER NOT NULL  DEFAULT 0, recommended INTEGER DEFAULT 0 );\\
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
    INSERT INTO version VALUES (\"USER_DB\", \"1.1\", \"Core Database\");\\
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
  def self.sqlite_create_cards
    sql_tmp_out_fn = "tmp_jflash_sqlite_dump.sql"
    File.delete(sql_tmp_out_fn) if File.exist?(sql_tmp_out_fn) # delete old tmp files
    mysql_dump_tables_via_cli(["cards", "cards_html"], sql_tmp_out_fn, $options[:mysql_name])

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS cards;\\
    CREATE TABLE cards (card_id INTEGER PRIMARY KEY, card_type TEXT, headword TEXT, headword_en TEXT, reading TEXT, romaji TEXT);\\
    \\
    DROP TABLE IF EXISTS cards_html;\\
    CREATE TABLE cards_html (card_id INTEGER PRIMARY KEY, meaning TEXT);\\
    \\
    DROP INDEX IF EXISTS cards_card_id;\\
    CREATE INDEX cards_card_id ON cards (card_id ASC);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"CARD_DB\", \"1.1\", \"Cards Database (READ ONLY)\");\\
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
  def self.sqlite_create_fts
    # Clean up any old dump files
    fts_tmp_out_fn = "tmp_jflash_sqlite_dump_fts.sql"
    File.delete(fts_tmp_out_fn) if File.exist?(fts_tmp_out_fn) # delete old tmp files

    # Dump tables to file, with as little extra crap as possible!
    mysql_dump_tables_via_cli(["cards_search_content"], fts_tmp_out_fn, $options[:mysql_name])

    sqlite_prepare_db_statements = "\\
    PRAGMA synchronous=OFF;\\
    PRAGMA count_changes=OFF;\\
    BEGIN TRANSACTION;\\
    \\
    DROP TABLE IF EXISTS cards_search_content;\\
    CREATE VIRTUAL TABLE cards_search_content using FTS3(card_id, content, ptag INTEGER NOT NULL DEFAULT 0);\\
    \\
    DROP TABLE IF EXISTS version;\\
    CREATE TABLE version (plugin_key TEXT PRIMARY KEY NOT NULL, version TEXT, plugin_name TEXT);\\
    INSERT INTO version VALUES (\"FTS_DB\", \"1.1\", \"Full Text Search Database (READ ONLY)\");\\
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
  def self.drop_export_tables
    connect_db
    prt "Dropping mySQL interim export tables (cards, cards_html, tags, groups, cards_search_content)\n\n"
    $cn.execute("DROP TABLE IF EXISTS cards")
    $cn.execute("DROP TABLE IF EXISTS cards_html")
    $cn.execute("DROP TABLE IF EXISTS tags")
    $cn.execute("DROP TABLE IF EXISTS groups")
    $cn.execute("DROP TABLE IF EXISTS cards_search_content")
  end
  
  # DESC: Removes all data from JFlash Import staging tables
  def self.empty_staging_tables
    connect_db
    prt "Removing all data from JFlash Import staging tables (cards_staging, card_tag_link)\n\n"
    if mysql_table_exists("cards_staging") and mysql_col_exists("cards_staging.staging_card_id")
        $cn.execute("ALTER TABLE cards_staging DROP COLUMN card_id;") # Drop jflash_card_id column
        $cn.execute("ALTER TABLE cards_staging CHANGE staging_card_id card_id int(11) NOT NULL AUTO_INCREMENT;")
    end
    $cn.execute("TRUNCATE TABLE cards_staging") 
    $cn.execute("TRUNCATE TABLE cards_html") if mysql_table_exists("cards_html")
    $cn.execute("TRUNCATE TABLE card_tag_link") if mysql_table_exists("card_tag_link")
  end

  # DESC: Ensures each JLPT tagged card is included in lower levels using CONCAT
  def self.add_jlpt_tags
    connect_db
    prt "Adding additional JLPT set membership tags to existing JLPT cards"
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt3,',tags) WHERE tags like '%jlpt4%' AND tags not like '%jlpt3%'")
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt2,',tags) WHERE tags like '%jlpt3%' AND tags not like '%jlpt2%'")
    $cn.execute("UPDATE cards_staging SET tags = concat('jlpt1,',tags) WHERE tags like '%jlpt2%' AND tags not like '%jlpt1%'")
  end

  # DESC: Add tag link records to 'card_tag_link'
  def self.add_tag_links(visible_tag_array = [ $options[:system_tags]['LWE_FAVORITES'] ])

    connect_db
    tag_by_name_arr = {}
    data_en = nil

    prt "Truncating card_tag_link table"
    $cn.execute("TRUNCATE TABLE card_tag_link")

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

  # DESC: Humanise inlined tags, and then export tables
  def self.humanise_inline_tags_in_table(cards_table="cards_staging")
    prt "Bulk updating formatted meanings with humanised tag names"
    connect_db
    output_table = cards_table + "_humanised"
    $cn.execute("DROP TABLE IF EXISTS #{output_table}")
    $cn.execute("CREATE TABLE #{output_table} SELECT card_id, card_type, headword, alt_headword, headword_en, reading, romaji, meaning, meaning_html, meaning_fts, tags, ptag FROM #{cards_table}")
    $cn.execute("ALTER TABLE #{output_table} ADD PRIMARY KEY (card_id)")
    result_data = $cn.execute("SELECT card_id, edict2hash FROM #{cards_table}")
    bulkSQL = BulkSQLRunner.new(0,10000)
    result_data.each do |card_id, edict2hash|
      edict2hash = mysql_deserialise_ruby_object(edict2hash)
      meanings_txt, meanings_html, meanings_fts = get_formatted_meanings(edict2hash, "human")
      bulkSQL.add("UPDATE #{output_table} SET meaning = \'#{mysql_escape_str(meanings_txt)}\',  meaning_html = \'#{mysql_escape_str(meanings_html)}\',  meaning_fts = \'#{mysql_escape_str(meanings_fts)}\' WHERE card_id = #{card_id};")
    end
    bulkSQL.flush # flush the remainder!
  end

  # DESC: Creates a smaller version of the jFlash Sqlite database using only certain tags
  def self.minify_sqlite_db

    # Tags to Keep:
    # JLPT 3, JLPT4,All Kana, LWE Favourites, Onomatopeia, Common Words
    tag_ids_to_keep_arr = [94,95,124,201,204,138,42,617,618] ### WARNING these last two tag ids are generated and can change!!
    tag_ids_to_keep_list = tag_ids_to_keep_arr.join(", ")

    # Copy the source file
    new_fn= "#{$options[:sqlite_file_path][:jflash_user]}_mini.db"
    `cp '#{$options[:sqlite_file_path][:jflash_user]}' '#{new_fn}'`

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
    `#{$options[:sqlite_bin]} "#{new_fn}" '#{sql}'`
  end

  # DESC: Empty and update the headword/card_id 
  def self.create_headword_index

    connect_db
    $cn.execute("TRUNCATE TABLE idx_cards_by_headword_staging")
    bulkSQL = BulkSQLRunner.new(0, 0)

    tickcount("Recreating Headword Keyword-Index") do
      $cn.execute("SELECT card_id, headword, reading FROM cards_staging").each do | card_id, headword, reading |
        bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{headword}');")
        reading.split($delimiters[:jflash_readings]).each do |keyword|
          bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{keyword}');")
        end
      end
    end
    
    bulkSQL.flush
    
  end

  # RETURNS: Existing cards and adds them into a hash
  def self.get_existing_cards(table ="cards_staging", where ="")
    lookup = self.cache_sql_query( { :select => "card_id, headword, alt_headword, card_type, edict2hash", :from => table, :where => where } ) do | sqlrow, cache_data |
      # Cache Storage
      card_type = sqlrow['card_type'].to_i
      cache_data[card_type] = {} if !cache_data[card_type]
      # Store rows in hash, deserialise stored Ruby Obj
      cache_data[card_type][sqlrow['headword']] = [] if !cache_data[card_type][sqlrow['headword']]
      cache_data[card_type][sqlrow['headword']] << sqlrow['card_id']
      sqlrow['alt_headword'].split($delimiters[:jflash_headwords]).each do |alt_headword|
        cache_data[card_type][alt_headword] = [] if !cache_data[card_type][alt_headword]
        cache_data[card_type][alt_headword] << sqlrow['card_id']
      end
    end
    return lookup
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

  # DESC: Get edict2hash as specified by card_id
  def self.get_existing_card_hash(card_id)
    connect_db
    result = $cn.select_one("SELECT card_id, edict2hash FROM cards_staging WHERE card_id = #{card_id}")
    edict2hash = mysql_deserialise_ruby_object(result['edict2hash'])
    # Add the existing card_id to the hash, this is removed before merging existing records!!
    edict2hash[:card_id] = result['card_id']
    return edict2hash
  end
  
  # DESC: Get edict2hash as specified by card_id, caches to memory
  def self.get_existing_card_hash_optimised(card_id)

    if $shared_cache[:existing_card_hashes].nil?
      connect_db
      $shared_cache[:existing_card_hashes] = {}
      tickcount("Caching existing card hashes once per run!") do
        $cn.execute("SELECT card_id, edict2hash FROM cards_staging").each do |cid, edict2hash|
          $shared_cache[:existing_card_hashes][cid] = edict2hash
        end
      end
    end

    # Add the card_id onto the hash for merging back to DB
    deserialised_hash = mysql_deserialise_ruby_object($shared_cache[:existing_card_hashes][card_id])
    deserialised_hash[:card_id] = card_id
    return deserialised_hash
  end

  # RETURNS: Existing headword lookup data
  def self.get_existing_headwords
    hash = self.cache_sql_query( { :select => "card_id, keyword", :from => "idx_cards_by_headword_staging" } ) do | sqlrow, cache_data |
      # Store rows in hash
      cache_data[sqlrow['keyword']] = sqlrow['card_id']
    end
    return hash
  end

  # DESC: Import English Words and match to entry in import DB - with / without tags (ACCEPTS: file=en_import_words.txt)
  # WARNING ~ WARNING ~ does not match effectively and creates duplicates!!!
  def self.DONT_USE_import_english_words(src_filename)

    connect_db

    out = ""
    line_count = 0
    existing_data = {}
    existing_eng_headwords = {}
    existing_eng_words = {}
    possible_matches = {}
    no_matches = []
    data = nil

    # Cache all cards
    tickcount("Selecting Existing Cards") do
      data = $cn.execute("SELECT card_id, headword, headword_en, meaning, reading, romaji FROM cards_staging")
    end

    # Open out file
    outf = File.open(src_filename + "_out.txt", 'w')
    data.each do |card_id, headword, headword_en, meaning, reading, romaji|

      # Headword wise matching
      eng_str = headword_en.gsub($regexes[:tag_like], "").gsub("[\(|\)]","").strip
      if existing_eng_headwords.include?(headword_en)
        # Add to existing subarray
        existing_eng_headwords[headword_en] << card_id
      else
        # Create subarray and add
        existing_eng_headwords[headword_en] = []
        existing_eng_headwords[headword_en] << card_id
      end
      
      # Word-wise matches
      eng_str.split(' ').each do |word|
        if existing_eng_words.include?(word)
            # Add to existing subarray
            existing_eng_words[word] << card_id
          else
            # Create subarray and add
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
    
    lines = File.open(src_filename, 'r')
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
        prt "Did not match: #{line}"
        no_matches << line
      end
    end
    outf.close

    prt "Lines read: #{line_count}"
    prt "Not Matched: #{no_matches.size.to_s}"

    outf = File.open(src_filename + "_not_matched.txt", 'w')
    outf.write(no_matches.join(""));
    outf.close
  end

  # DESC: Create JFlash Import Tables
  def self.create_tables(tables_arr=[], create_all=false)

    create_statements ={}
    create_statements["cards_staging"] = "\\
    CREATE TABLE `cards_staging` (\\
      `card_id` int(11) NOT NULL AUTO_INCREMENT,\\
      `card_type` int(11) DEFAULT '0',\\
      `headword` varchar(200) DEFAULT NULL,\\
      `alt_headword` varchar(200) DEFAULT NULL,\\
      `headword_en` varchar(200) DEFAULT NULL,\\
      `reading` varchar(500) DEFAULT NULL,\\
      `romaji` varchar(1000) DEFAULT NULL,\\
      `meaning` varchar(3000) DEFAULT NULL,\\
      `meaning_html` varchar(5000) DEFAULT NULL,\\
      `meaning_fts` varchar(3000) DEFAULT NULL,\\
      `tags` varchar(200) DEFAULT NULL,\\
      `ptag` tinyint(4) DEFAULT '0',\\
      `jmdict_refs` varchar(500) DEFAULT NULL,\\
      `edict2hash` longblob,\\
      PRIMARY KEY (`card_id`),\\
      KEY `card_ja` (`card_id`),\\
      KEY `headword` (`headword`),\\
      KEY `meaning` (`meaning`(333)),\\
      KEY `card_type` (`card_type`)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;"
    
    create_statements["chinese_cards_staging"] = "\\
    CREATE TABLE `chinese_cards_staging` (\\
      `card_id` int(11) NOT NULL AUTO_INCREMENT,\\
      `card_type` int(11) DEFAULT '0',\\
      `headword` varchar(200) DEFAULT NULL,\\
      `alt_headword` varchar(200) DEFAULT NULL,\\
      `headword_en` varchar(200) DEFAULT NULL,\\
      `reading` varchar(500) DEFAULT NULL,\\
      `romaji` varchar(1000) DEFAULT NULL,\\
      `meaning` varchar(2000) DEFAULT NULL,\\
      `meaning_html` varchar(2000) DEFAULT NULL,\\
      `tags` varchar(200) DEFAULT NULL,\\
      `ptag` tinyint(4) DEFAULT '0',\\
      PRIMARY KEY (`card_id`),\\
      KEY `card_ja` (`card_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["groups_staging"] = "\\
    CREATE TABLE `groups_staging` (\\
      `group_id` int(11) NOT NULL,\\
      `group_name` varchar(50) NOT NULL,\\
      `owner_id` int(11) NOT NULL,\\
      `tag_count` int(11) DEFAULT '0',\\
      `recommended` int(11) DEFAULT '0',\\
      PRIMARY KEY (`group_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"

    create_statements["tags_staging"] = "\\
    CREATE TABLE `tags_staging` (\\
      `tag_id` int(11) NOT NULL AUTO_INCREMENT,\\
      `tag_name` varchar(50) DEFAULT NULL,\\
      `tag_type` varchar(4) DEFAULT NULL,\\
      `short_name` varchar(20) DEFAULT NULL,\\
      `description` varchar(200) DEFAULT NULL,\\
      `source_name` varchar(50) DEFAULT NULL,\\
      `source` varchar(50) DEFAULT NULL,\\
      `visible` int(11) NOT NULL DEFAULT '0',\\
      `count` int(11) NOT NULL DEFAULT '0',\\
      `parent_tag_id` int(11) NULL DEFAULT NULL,\\
      `force_off` tinyint(4) DEFAULT '0',\\
      PRIMARY KEY (`tag_id`),\\
      UNIQUE KEY `short_name` (`short_name`)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;"
    
    create_statements["sentences_staging"] ="\\
    CREATE TABLE `sentences_staging` (\\
      `sentence_id` int(11) NOT NULL AUTO_INCREMENT,\\
      `sentence_ja` varchar(500) DEFAULT NULL,\\
      `sentence_en` varchar(500) DEFAULT NULL,\\
      `tanc_en_id` int(11) DEFAULT NULL,\\
      `tanc_ja_id` int(11) DEFAULT NULL,\\
      `checked` tinyint(4) DEFAULT NULL,\\
      KEY `sentence_id` (`sentence_id`),\\
      KEY `checked` (`checked`)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;"

    create_statements["kanji_staging"] ="\\
    CREATE TABLE `kanji_staging` (\\
      `kanji` binary(64) NOT NULL,\\
      `radical` int(11) NOT NULL,\\
      `stroke_count` int(11) NOT NULL,\\
      `jlpt` int(11) NOT NULL,\\
      `grade` int(11) NOT NULL,\\
      `frequency` int(11) NOT NULL,\\
      `components` varchar(30) NOT NULL,\\
      `nanori` varchar(30) NOT NULL,\\
      `XML` blob NOT NULL,\\
      PRIMARY KEY (`kanji`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["kanji_readings_staging"] ="\\
    CREATE TABLE `kanji_readings_staging` (\\
      `kanji` binary(64) NOT NULL,\\
      `reading` varchar(10) NOT NULL,\\
      `reading_type` varchar(10) NOT NULL,\\
      KEY `kanji` (`kanji`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["kanji_meanings_staging"] ="\\
    CREATE TABLE `kanji_meanings_staging` (\\
      `kanji` binary(64) NOT NULL,\\
      `meaning` varchar(50) NOT NULL,\\
      `language` varchar(3) NOT NULL,\\
      KEY `kanji` (`kanji`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["card_tag_link"] ="\\
    CREATE TABLE `card_tag_link` (\\
      `tag_id` int(11) DEFAULT NULL,\\
      `card_id` int(11) DEFAULT NULL,\\
      UNIQUE KEY `card_tag_link_uniq` (`tag_id`,`card_id`),\\
      KEY `card_tag` (`tag_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"

    create_statements["group_tag_link"] ="\\
    CREATE TABLE `group_tag_link` (\\
      `group_id` int(11) NOT NULL,\\
      `tag_id` int(11) NOT NULL\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"

    create_statements["card_sentence_link"] ="\\
    CREATE TABLE `card_sentence_link` (\\
      `card_id` int(11) DEFAULT NULL,\\
      `sentence_id` int(11) DEFAULT NULL,\\
      `should_show` tinyint(4) DEFAULT 1,\\      
      `sense_number` int(11) DEFAULT NULL,\\
      KEY `card_id` (`card_id`),\\
      KEY `sentence_id` (`sentence_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"

    create_statements["idx_sentences_by_keyword_staging"] ="\\
    CREATE TABLE `idx_sentences_by_keyword_staging` (\\
      `sentence_id` int(11) DEFAULT NULL,\\
      `segment_number` int(11) DEFAULT NULL,\\
      `sense_number` int(11) DEFAULT NULL,\\
      `checked` tinyint(4) DEFAULT NULL,\\
      `keyword_type` int(11) DEFAULT NULL,\\
      `keyword` varchar(100) DEFAULT NULL,\\
      `reading` varchar(100) DEFAULT NULL,\\
      KEY `sentence_id` (`sentence_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["idx_cards_by_headword_staging"] ="\\
    CREATE TABLE `idx_cards_by_headword_staging` (\\
      `card_id` int(11) DEFAULT NULL,\\
      `keyword` varchar(100) DEFAULT NULL\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;\\"
    
    connect_db

    # Create tables we are told to make
    tables_arr = create_statements.keys.collect {|i| i} if create_all
    tables_arr.each do |table_nm|
      if tables_arr.index(table_nm) and !mysql_table_exists(table_nm)
        $cn.execute(create_statements[table_nm])
      end
    end

  end
  
  # DESC: Inserts current starting tag set into the tags_staging table
  def self.populate_tags_staging
    connect_db
    create_tables(["tags_staging"])
    $cn.execute("INSERT INTO `tags_staging` (`tag_name`,`tag_type`,`short_name`,`description`,`source_name`,`source`,`visible`,`parent_tag_id`) VALUES\\
    ('12 Hour Clock', 'cat', '12 Hour Clock', '12 Hour Clock', 'Time_:_12_Hour_Clock', 'jflash', 1, NULL),\\
    ('24 Hour Clock', 'cat', '24 Hour Clock', '24 Hour Clock', 'Time_:_24_Hour_Clock', 'jflash', 1, NULL),\\
    ('2ch (Ni Channeru)', 'cat', '2ch', '2ch Term (Ni Channeru)', '2-ch_term,2-ch term', 'edict', 0, NULL),\\
    ('Abbreviations', 'cat', 'abbrev', 'Abbreviation', 'abbr', 'edict', 1, NULL),\\
    ('Adjective', 'pos', 'adjective', 'Legacy tag: adjective (being removed)', 'adj', 'edict', 1, NULL),\\
    ('~たる Adjectives', 'pos', 'たる adj', 'たる adjective', 'adj-t', 'edict', 1, NULL),\\
    ('Adverbial Nouns', 'pos', 'adv noun', 'Adverbial noun (副指摘名詞・fukushitekimeishi)', 'n-adv', 'edict', 1, NULL),\\
    ('Adverbs', 'pos', 'adverb', 'Adverb (副詞・fukushi)', 'adv', 'edict', 1, NULL),\\
    ('~と Adverbs', 'pos', '~と adverb', 'Adverb taking the と particle', 'adv-to', 'edict', 1, NULL),\\
    ('Aeronautical', 'cat', 'Aeronautical', 'Aeronautical term', 'aeronautical', 'edict', 0, NULL),\\
    ('Ainu Words', 'lang', 'cf. Ainu', 'Cf. Ainu language', 'ai', 'edict', 1, NULL),\\
    ('Animals', 'cat', 'Animals', 'Animals', 'Common_Animals', 'jflash', 1, NULL),\\
    ('Apologies', 'cat', 'Apologies', 'Apologies', 'Expressions_:_Apologies', 'jflash', 1, NULL),\\
    ('Arabic Words', 'lang', 'cf. Arabic', 'Cf. Arabic', 'ar', 'edict', 1, NULL),\\
    ('Archaic', 'cat', 'Archaic', 'Archaic', 'arch', 'edict', 1, NULL),\\
    ('Astronomical', 'cat', 'Astronomical', 'Astronomical term', 'astronomical', 'edict', 1, NULL),\\
    ('Auxiliary Adjectives', 'pos', 'aux adj', 'Auxiliary Adjectives', 'aux-adj', 'edict', 0, NULL),\\
    ('Auxiliaries', 'pos', 'aux', 'Auxiliary', 'aux', 'edict', 1, NULL),\\
    ('Auxiliary Verbs', 'pos', 'aux verb', 'Auxiliary verb', 'aux-v', 'edict', 1, NULL),\\
    ('Aux ~する Irreg. Verbs', 'pos', '~する verb irr', 'する verb (irregular)', 'vs-i', 'edict', 1, NULL),\\
    ('Aux ~する Reg. Verbs', 'pos', '~する verb reg', 'Noun or participle which takes the aux. verb する', 'vs', 'edict', 1, NULL),\\
    ('Aux ~する Special Verbs', 'pos', '~する verb sp', 'する verb (special class)', 'vs-s', 'edict', 1, NULL),\\
    ('Baseball', 'cat', 'Baseball', 'Baseball', 'baseball', 'edict', 1, NULL),\\
    ('Botanical', 'cat', 'Botanical', 'Botanical term', 'botanical,botanical_term,botanical term', 'edict', 1, NULL),\\
    ('Buddhist Religion', 'cat', 'Buddhist Religion', 'Buddhist Religion', 'Buddh', 'edict', 1, NULL),\\
    ('Buildings', 'cat', 'Buildings', 'Buildings', 'Common_Buildings', 'jflash', 1, NULL),\\
    ('Burmese Words', 'lang', 'cf.  Burmese', 'Cf. Burmese language', 'bu', 'edict', 0, NULL),\\
    ('Calendar Months', 'cat', 'Calendar Months', 'Calendar Months', 'Time_:_Calendar_Months', 'jflash', 1, NULL),\\
    ('Calling for Help', 'cat', 'Calling for Help', 'Calling for Help', 'Expressions_:_Calling_for_Help', 'jflash', 1, NULL),\\
    ('Catholic Religion', 'cat', 'Catholic Religion', 'Catholic Religion', 'Catholic', 'edict', 1, NULL),\\
    ('Chemistry', 'cat', 'Chemistry', 'Chemistry', 'chem', 'edict', 1, NULL),\\
    ('Children\'s Language', 'cat', 'Children\'s Language', 'Children\'s language', 'chn', 'edict', 1, NULL),\\
    ('Children\'s Games', 'cat', 'Children\'s Games', 'Name of children\'s game', 'game_of,game of', 'edict', 0, NULL),\\
    ('Chinese Words', 'lang', 'cf. Chinese', 'Cf. Chinese language', 'ch', 'edict', 1, NULL),\\
    ('Classroom Words', 'cat', 'Classroom Words', 'Classroom Words', 'Classroom_Words', 'jflash', 1, NULL),\\
    ('Clothing', 'cat', 'Clothing', 'Clothing', 'Common_Clothing', 'jflash', 1, NULL),\\
    ('Colloquialisms', 'cat', 'Colloquialisms', 'Colloquialisms', 'col', 'edict', 1, NULL),\\
    ('Colors', 'cat', 'Common Colors', 'Common Colors', 'Common_Colors', 'jflash', 1, NULL),\\
    ('Colors (More)', 'cat', 'More Colors', 'More Colors', 'colour', 'edict', 1, NULL),\\
    ('Common Words', 'cat', 'common', 'Common use word', 'P,common', 'edict', 1, NULL),\\
    ('Common Verbs', 'cat', 'Common Verbs', 'Common Verbs', 'Common_Verbs', 'jflash', 1, NULL),\\
    ('Common い Adjectives', 'cat', 'い adj common', 'Common い Adjectives', 'Common_i-adjectives', 'jflash', 1, NULL),\\
    ('Common な Adjectives', 'cat', 'な adj common', 'Common な Adjectives', 'Common_na-adjectives', 'jflash', 0, NULL),\\
    ('Computers', 'cat', 'Computers', 'Computers', 'comp,Common_PC_Terms,Common_Networking_Terms', 'edict', 1, NULL),\\
    ('Conjunctions', 'pos', 'conjunction', 'Conjunctions', 'conj', 'edict', 1, NULL),\\
    ('Constellations', 'cat', 'Constellations', 'Constellation name', 'constellation', 'edict', 1, NULL),\\
    ('Counter Kanji', 'pos', 'counter', 'Counter word', 'ctr', 'edict', 1, NULL),\\
    ('Days of the Week', 'cat', 'Days of the Week', 'Days of the Week', 'Time_:_Days_of_the_Week', 'jflash', 1, NULL),\\
    ('Derogatory', 'cat', 'Derogatory', 'Derogatory', 'derog', 'edict', 1, NULL),\\
    ('Drinking Words', 'cat', 'Drinking Words', 'Drinking Words', 'Drinking_Terms', 'jflash', 1, NULL),\\
    ('Dutch Words', 'lang', 'cf. Dutch', 'Cf. Dutch language', 'du,nl', 'edict', 1, NULL),\\
    ('Edo Period', 'cat', 'Edo Period', 'Edo Period', 'Edo-period', 'edict', 1, NULL),\\
    ('Generic', 'cat', 'generic counters', 'Generic counter for objects', 'Counters_:_General', 'jflash', 1, NULL),\\
    ('Electrical', 'cat', 'Electrical', 'Electrical term', 'electrical', 'edict', 1, NULL),\\
    ('English Words', 'lang', 'cf. English', 'Cf. English language', 'en', 'edict', 0, NULL),\\
    ('Everyday Expressions', 'cat', 'everyday expr.', 'Everyday Expressions', 'Expressions_:_Everyday', 'jflash', 1, NULL),\\
    ('Familiar Language', 'cat', 'Familiar Language', 'Familiar language', 'fam', 'edict', 1, NULL),\\
    ('Family', 'cat', 'Family', 'Family', 'Family', 'jflash', 1, NULL),\\
    ('Fantasy', 'cat', 'Fantasy', 'Fantasy', 'Fantasy_Terms', 'jflash', 1, NULL),\\
    ('Female Expressions', 'cat', 'female expr.', 'Female Expressions', 'fem', 'edict', 1, NULL),\\
    ('Financial', 'cat', 'Financial', 'Financial', 'Financial_Terms', 'jflash', 1, NULL),\\
    ('Food', 'cat', 'Common Food', 'Common Food', 'Common_Food_Terms', 'jflash', 1, NULL),\\
    ('Food (More)', 'cat', 'More Food', 'More Food', 'food', 'edict', 1, NULL),\\
    ('French Words', 'lang', 'cf. French', 'Cf. French language', 'fr', 'edict', 1, NULL),\\
    ('Gagaku', 'cat', 'Gagaku', 'Gagaku related term (雅楽)', 'gagaku', 'edict', 0, NULL),\\
    ('Geography', 'cat', 'Geography', 'Geography', 'Geography', 'jflash', 1, NULL),\\
    ('Geometry', 'cat', 'Geometry', 'Geometry', 'geom', 'edict', 0, NULL),\\
    ('German Words', 'lang', 'cf. German', 'Cf. German language', 'de', 'edict', 1, NULL),\\
    ('Gikun meaning or reading', 'cat', 'gikun', 'Gikun meaning or reading', 'gikun', 'edict', 0, NULL),\\
    ('Greek Words', 'lang', 'cf. Greek', 'Cf. Greek lanugage', 'gr', 'edict', 1, NULL),\\
    ('Greetings', 'cat', 'Greetings', 'Greetings', 'Expressions_:_Greetings', 'jflash', 1, NULL),\\
    ('Hanafuda', 'cat', 'Hanafuda', 'Hanafuda term', 'hanafuda', 'edict', 0, NULL),\\
    ('Homes', 'cat', 'Homes', 'Homes', 'Homes', 'jflash', 1, NULL),\\
    ('Honorifics', 'cat', 'Honorifics', 'Honorifics', 'hon', 'edict', 1, NULL),\\
    ('Hospitals', 'cat', 'Hospitals', 'Hospitals', 'Hospitals', 'jflash', 1, NULL),\\
    ('Humble Language', 'cat', 'Humble Language', 'Humble Language (謙譲語・kenjougo)', 'hum', 'edict', 1, NULL),\\
    ('Idiomatic Expressions', 'cat', 'idiom', 'Idomatic Expressions', 'id', 'edict', 1, NULL),\\
    ('Illness', 'cat', 'Illness', 'Illness', 'Illness', 'jflash', 1, NULL),\\
    ('Insects', 'cat', 'Insects', 'Insects', 'Insects', 'jflash', 1, NULL),\\
    ('Interjections', 'pos', 'interjection', 'Interjections (感動詞・kandoushi)', 'int', 'edict', 1, NULL),\\
    ('Intransitive Verbs', 'pos', 'verb intrans', 'Intrasitive verb (自動詞・jidoushi)', 'vi', 'edict', 1, NULL),\\
    ('Irregular Kana Usage', 'cat', 'irreg kana', 'Irregular Kana Usage', 'ikana', 'edict', 0, NULL),\\
    ('Irregular Kanji Usage', 'cat', 'irreg kanji', 'Irregular Kanji Usage', 'ikanji', 'edict', 0, NULL),\\
    ('Irregular Okurigana', 'cat', 'irreg okurigana', 'Irregular Okurigana Usages', 'io', 'edict', 0, NULL),\\
    (' ~ぬ Irregular Verbs', 'pos', '~ぬ verb irr', 'Verb ending in ぬ (irregular)', 'vn', 'edict', 0, NULL),\\
    ('Italian Words', 'lang', 'cf. Italian', 'Cf. Italian language', 'it', 'edict', 1, NULL),\\
    ('Japanglish (Wasei Eigo)', 'lang', 'Wasei Eigo', 'English word repurposed for Japanese (pidgin)', 'wasei', 'edict', 1, NULL),\\
    ('JLPT Level N1', 'cat', 'jlpt1', 'JLPT Level N1', 'jlpt1', 'edict', 1, NULL),\\
    ('JLPT Level N2', 'cat', 'jlpt2', 'JLPT Level N2', 'jlpt2', 'edict', 1, NULL),\\
    ('JLPT Level N3', 'cat', 'jlpt3', 'JLPT Level N3', 'jlpt3', 'edict', 1, NULL),\\
    ('JLPT Level N4', 'cat', 'jlpt4', 'JLPT Level N4', 'jlpt4', 'edict', 1, NULL),\\
    ('Judeo-christian', 'cat', 'Judeo-christian', 'Judeo-Christian term', 'Judeo-Christian', 'edict', 0, NULL),\\
    ('Kansai Dialect', 'lang', 'Kansai Dialect', 'Kansai Dialect (関西弁)', 'ksb,osb', 'edict', 1, NULL),\\
    ('Kantou Dialect', 'lang', 'Kantou Dialect', 'Kantou Dialect (関東弁)', 'ktb', 'edict', 1, NULL),\\
    ('Khmer Words', 'lang', 'cf. Khmer', 'Cf. Khmer languag', 'kh', 'edict', 0, NULL),\\
    ('Korean Words', 'lang', 'cf. Korean', 'Cf. Korean language', 'ko', 'edict', 1, NULL),\\
    ('Kyouto Dialect', 'lang', 'Kyouto Dialect', 'Kyouto Dialect (京都弁)', 'kyb', 'edict', 0, NULL),\\
    ('Latin Words', 'lang', 'cf. Latin', 'Cf. Latin language', 'la', 'edict', 1, NULL),\\
    ('Leisure Time', 'cat', 'Leisure Time', 'Leisure Time', 'Leisure_Time', 'jflash', 1, NULL),\\
    ('L1 Verbs', 'pos', 'verb L1', 'Ichidan verb', 'v1', 'edict', 1, NULL),\\
    ('L1 Verbs (~ずる ending)', 'pos', '~ずる verb L1', 'Ichidan verb ずる verb (alternative form of ~じる verbs)', 'vz', 'edict', 1, NULL),\\
    ('L4 Verbs (~う ending)', 'pos', '~う verb L4', 'Yondan verb with ??? ending', 'v4h', 'edict', 0, NULL),\\
    ('L4 Verbs (~る ending)', 'pos', '~る verb L4', 'Yondan verb with る ending', 'v4r', 'edict', 0, NULL),\\
    ('L5 Verbs (~ぁる ending)', 'pos', '~ぁる verb L5', 'Godan verb with ~ぁる ending (special class)', 'v5aru', 'edict', 1, NULL),\\
    ('L5 Verbs (~いく or ~ゆく)', 'pos', '~(い/ゆ)く verb L5', 'Godan verb ending with いく or ゆく (special class)', 'v5k-s', 'edict', 1, NULL),\\
    ('L5 Verbs (~う ending)', 'pos', '~う verb L5', 'Godan verb with う ending', 'v5u', 'edict', 1, NULL),\\
    ('L5 Verbs (~う special class)', 'pos', '~う verb L5 sp', 'Godan verb with う ending (special class)', 'v5u-s', 'edict', 0, NULL),\\
    ('L5 Verbs (~く ending)', 'pos', '~くverb L5', 'Godan verb with く ending', 'v5k', 'edict', 1, NULL),\\
    ('L5 Verbs (~ぐ ending)', 'pos', '~ぐ verb L5', 'Godan verb with ぐ ending', 'v5g', 'edict', 1, NULL),\\
    ('L5 Verbs (~す ending)', 'pos', '~す verb L5', 'Godan verb with す ending', 'v5s', 'edict', 1, NULL),\\
    ('L5 Verbs (~ずるending)', 'pos', '~ずる verb L5', 'Godan verb with ずる ending', 'v5z', 'edict', 0, NULL),\\
    ('L5 Verbs (~つ ending)', 'pos', '~つ verb L5', 'Godan verb with つ ending', 'v5t', 'edict', 1, NULL),\\
    ('L5 Verbs (~ぬ ending)', 'pos', '~ぬ verb L5', 'Godan verb with ぬ ending', 'v5n', 'edict', 0, NULL),\\
    ('L5 Verbs (~ぶ ending)', 'pos', '~ぶ verb L5', 'Godan verb with ぶ ending', 'v5b', 'edict', 1, NULL),\\
    ('L5 Verbs (~む ending)', 'pos', '~む verb L5', 'Godan verb with む ending', 'v5m', 'edict', 1, NULL),\\
    ('L5 Verbs (~る ending)', 'pos', '~る verb L5', 'Godan verb with る ending', 'v5r', 'edict', 1, NULL),\\
    ('L5 Verbs (~る irregular)', 'pos', '~る verb irr L5', 'Godan verb with る ending (irregular verb)', 'v5r-i', 'edict', 0, NULL),\\
    ('Linguistics', 'cat', 'linguistic', 'Linguistics', 'ling,linguistic', 'edict', 1, NULL),\\
    ('Long Weekend Favorites', 'cat', 'lwe favourite', 'Our favorite Japanese vocabulary', 'Long_Weekend_Favorites', 'jflash', 1, NULL),\\
    ('Malaysian Words', 'lang', 'cf. Malaysian', 'Cf. Malaysian language', 'ma', 'edict', 0, NULL),\\
    ('Male Expressions', 'cat', 'male expr.', 'Male Expressions', 'male,masc', 'edict', 1, NULL),\\
    ('Manga Slang', 'cat', 'Manga Slang', 'Manga Slang', 'm-sl', 'edict', 1, NULL),\\
    ('Martial Arts', 'cat', 'Martial Arts', 'Martial Arts', 'MA', 'edict', 1, NULL),\\
    ('Mathematical', 'cat', 'Mathematical', 'Mathematical', 'math', 'edict', 1, NULL),\\
    ('Military', 'cat', 'Military', 'Military', 'mil', 'edict', 1, NULL),\\
    ('Norwegian Words', 'lang', 'cf. Norwegian', 'Cf. Norwegian language', 'no', 'edict', 0, NULL),\\
    ('Noun Suffixes', 'pos', 'noun suffix', 'Noun, used as a suffix', 'n-suf', 'edict', 1, NULL),\\
    ('Nouns', 'pos', 'noun', 'Common noun (副名詞・fukumeishi)', 'n', 'edict', 1, NULL),\\
    ('Numeric', 'pos', 'numeric', 'Numeric', 'num', 'edict', 1, NULL),\\
    ('Obscure', 'cat', 'obscure', 'Obscure', 'obsc,rare', 'edict', 1, NULL),\\
    ('Obsolete', 'cat', 'obsolete', 'Obsolete', 'obs', 'edict', 1, NULL),\\
    ('Obsolete Kana Usage', 'cat', 'osbsolete kana', 'Obsolete Kana Usage', 'okana', 'edict', 0, NULL),\\
    ('Onomatopoeia', 'cat', 'onomatopoeia', 'Onomatopoeia or mimetic words', 'on-mim', 'edict', 1, NULL),\\
    ('Out-Dated Kanji Usages', 'cat', 'outdated kanji use', 'Out-Dated Kanji Usages', 'okanji', 'edict', 0, NULL),\\
    ('Particles', 'pos', 'particle', 'Particles (助詞・joshi)', 'prt', 'edict', 1, NULL),\\
    ('Parts of Speech', 'cat', 'Parts of Speech', 'Parts of Speech', 'Parts_of_Speech,gram', 'jflash', 1, NULL),\\
    ('Parts of the Body', 'cat', 'Parts of the Body', 'Parts of the Body', 'Parts_of_the_Body', 'jflash', 1, NULL),\\
    ('People at School', 'cat', 'People at School', 'People at School', 'People_at_School', 'jflash', 1, NULL),\\
    ('Numbers', 'cat', 'numbers', 'Japanese numbers', 'Counting_&_Numbers', 'jflash', 1, NULL),\\
    ('Phonetic Kanji usage (ateji)', 'cat', 'ateji', 'Phonetic Kanji usage (ateji)', 'ateji', 'edict', 0, NULL),\\
    ('Common Expressions', 'pos', 'expression', 'Common Expressions', 'exp', 'edict', 1, NULL),\\
    ('Physics', 'cat', 'Physics', 'Physics related term', 'physics', 'edict', 1, NULL),\\
    ('Plant Families', 'cat', 'Plant Families', 'Plant Families', 'plant,plant_family,plant family', 'edict', 1, NULL),\\
    ('Poetry', 'cat', 'Poetry', 'Poetry term', 'poet', 'edict', 0, NULL),\\
    ('Polite Language', 'cat', 'polite', 'Polite Language', 'pol', 'edict', 1, NULL),\\
    ('Political Language', 'cat', 'Political Language', 'Political language', 'political', 'edict', 1, NULL),\\
    ('Portuguese Words', 'lang', 'cf. Portuguese', 'Cf. Portguese language', 'po,pt', 'edict', 1, NULL),\\
    ('Pre-Noun Adjectival ', 'pos', 'prenoun adj', 'Pre-Noun Adjectival (連体詞・rentaishi)', 'adj-pn', 'edict', 1, NULL),\\
    ('Precise Time', 'cat', 'Precise Time', 'Precise Time', 'Time_:_Precise_Terms', 'jflash', 1, NULL),\\
    ('Prefix Noun', 'pos', 'prefix noun', 'Noun, used as a prefix', 'n-pref', 'edict', 1, NULL),\\
    ('Prefixes', 'pos', 'prefix', 'Prefix', 'pref', 'edict', 1, NULL),\\
    ('Prenominal Noun/Verb', 'pos', 'prenom v/adv', 'Noun or verb acting prenominally (other than the above)', 'adj-f', 'edict', 1, NULL),\\
    ('Relative Time', 'cat', 'Relative Time', 'Relative Time', 'Relative_Time', 'jflash', 1, NULL),\\
    ('Report Bad Data', 'cat', 'Report Bad Data', 'Add words to this set to report bad data', 'BAD_DATA_(Beta_Users)', 'jflash', 0, NULL),\\
    ('Rude or Impolite', 'cat', 'Rude or Impolite', 'Rude or X-Rated', 'X,vulg', 'edict', 1, NULL),\\
    ('Russian Words', 'lang', 'cf. Russian', 'Cf. Russian language', 'ru', 'edict', 1, NULL),\\
    ('Ryuukyuu Dialect', 'lang', 'Ryuukyuu Dialect', 'Ryuukyuu Dialect from Okinawa (琉球弁)', 'rkb', 'edict', 1, NULL),\\
    ('Sanskrit Words', 'lang', 'cf. Sanskrit', 'Cf. Sanskrit language (usu. relating to Buddhism)', 'sa', 'edict', 1, NULL),\\
    ('School Life', 'cat', 'School Life', 'School Life', 'School_Life', 'jflash', 1, NULL),\\
    ('School Subjects', 'cat', 'School Subjects', 'School Subjects', 'School_Subjects', 'jflash', 1, NULL),\\
    ('Schools', 'cat', 'Schools', 'Schools', 'Schools', 'jflash', 1, NULL),\\
    ('Sensitive Words', 'cat', 'sensitive', 'Sensitive word (potentially rude or insulting)', 'sens', 'edict', 1, NULL),\\
    ('Shogi (Japanese Chess)', 'cat', 'shogi', 'Shogi (Japanese Chess)', 'shogi', 'edict', 1, NULL),\\
    ('Slang', 'cat', 'slang', 'Slang', 'sl', 'edict', 1, NULL),\\
    ('Spanish Words', 'lang', 'cf. Spanish', 'Cf. Spanish language', 'es', 'edict', 1, NULL),\\
    ('Special Verbs (~くる ending)', 'pos', '~くる verb sp', 'Verb ending in くる (special class)', 'vk', 'edict', 1, NULL),\\
    ('Suffixes', 'pos', 'suffix', 'Suffix', 'suf', 'edict', 1, NULL),\\
    ('Sumo Wrestling', 'cat', 'Sumo', 'Sumo Wrestling', 'sumo', 'edict', 1, NULL),\\
    ('Character Symbols', 'pos', 'symbol', 'Character Symbols', 'symbol', 'edict', 0, NULL),\\
    ('Tahitian Words', 'lang', 'cf. Tahitian', 'Cf. Tahitian language', 'ta', 'edict', 0, NULL),\\
    ('Taxonomical', 'cat', 'Taxonomical', 'Taxonomical', 'taxonomical', 'edict', 1, NULL),\\
    ('Telephone At Home', 'cat', 'Telephone At Home', 'Telephone At Home', 'Expressions_:_Telephone_At_Home', 'jflash', 1, NULL),\\
    ('Telephone At Work', 'cat', 'Telephone At Work', 'Telephone At Work', 'Expressions_:_Telephone_at_Work', 'jflash', 1, NULL),\\
    ('Telephone General', 'cat', 'Telephone General', 'Telephone General', 'Expressions_:_Telephone_General', 'jflash', 1, NULL),\\
    ('Telephony', 'cat', 'Telephony', 'Telephony related', 'telephone', 'edict', 1, NULL),\\
    ('Temporal Nouns', 'pos', 'temporal noun', 'Temporal noun temporal (時相名詞・jisoumeishi)', 'n-t', 'edict', 1, NULL),\\
    ('Thai Words', 'lang', 'cf. Thai', 'Cf. Thai language', 'th', 'edict', 0, NULL),\\
    ('Theatrical', 'cat', 'Theatrical', 'Theatrical', 'theatrical', 'edict', 1, NULL),\\
    ('TIbetan Words', 'lang', 'cf. TIbetan', 'Cf. Tibetan language', 'ti', 'edict', 0, NULL),\\
    ('Time In Minutes', 'cat', 'Time In Minutes', 'Time In Minutes', 'Time_:_In_Minutes', 'jflash', 1, NULL),\\
    ('Tosa Dialect', 'lang', 'Tosa Dialect', 'Tosa Dialect (土佐弁)', 'tsb', 'edict', 0, NULL),\\
    ('Touhoku Dialect', 'lang', 'Touhoku Dialect', 'Touhoku Dialect (東北弁)', 'thb', 'edict', 0, NULL),\\
    ('Trains', 'cat', 'Trains', 'Trains', 'Trains', 'jflash', 1, NULL),\\
    ('Transitive Verbs', 'pos', 'verb trans', 'Transitive verb (他動詞・tadoushi)', 'vt', 'edict', 1, NULL),\\
    ('Tsugaru', 'lang', 'Tsugaru', 'Tsugaru dialect (津軽弁)', 'tsug', 'edict', 0, NULL),\\
    ('Weather', 'cat', 'Weather', 'Weather', 'Weather', 'jflash', 1, NULL),\\
    ('Written with Kana Only', 'cat', 'kana only word', 'Word usually written using kana alone', 'ukana', 'edict', 1, NULL),\\
    ('Zoological', 'cat', 'Zoological', 'Zoological term', 'zoological', 'edict', 0, NULL),\\
    ('い Adjectives', 'pos', 'い adj', 'い Adjectives (形容詞・keiyoushi)', 'adj-i', 'edict', 1, NULL),\\
    ('な Adjectives', 'pos', 'な adj', 'Adjectival nouns or quasi-adjectives (keiyodoshi)', 'adj-na', 'edict', 1, NULL),\\
    ('の Adjectives', 'pos', 'の adj', 'Nouns which may take the genitive case particle の', 'adj-no', 'edict', 1, NULL),\\
    ('Hiragana (Basic)', 'cat', 'Hiragana (Basic)', 'Hiragana (Basic)', 'Hiragana_Basic', 'jflash', 1, NULL),\\
    ('Hiragana (All)', 'cat', 'Hiragana (All)', 'Hiragana (All)', 'Hiragana_All', 'jflash', 1, NULL),\\
    ('Hiragana (Voiced)', 'cat', 'Hiragana (Voiced)', 'Hiragana (Voiced)', 'Hiragana_Dakuon', 'jflash', 1, NULL),\\
    ('Katakana (Basic)', 'cat', 'Katakana (Basic)', 'Katakana (Basic)', 'Katakana_Basic', 'jflash', 1, NULL),\\
    ('Katakana (All)', 'cat', 'Katakana (All)', 'Katakana (All)', 'Katakana_All', 'jflash', 1, NULL),\\
    ('Katakana (Voiced)', 'cat', 'Katakana (Voiced)', 'Katakana (Voiced)', 'Katakana_Dakuon', 'jflash', 1, NULL),\\
    ('Katakana (Compounds)', 'cat', 'katakana compounds', 'Katakana (Compounds)', 'Katakana_Distorted', 'jflash', 1, NULL),\\
    ('Hiragana (Compounds)', 'cat', 'hiragana compounds', 'Hiragana (Compounds)', 'Hiragana_Distorted', 'jflash', 1, NULL),\\
    ('Pronouns', 'pos', 'pronoun', 'Pronouns', 'pn', 'edict', 1, NULL),\\
    ('Obscure Kanji', 'cat', 'nokanji', 'Kanji usage is obscure and not normally used', 'nokanji', 'edict', 0, NULL),\\
    ('People', 'cat', 'people counters', 'Counters for people', 'Counters_:_People', 'jflash', 1, NULL),\\
    ('Flat Objects', 'cat', 'flat-object counters', 'Counters for flat objects, paper, plates, etc', 'Counters_:_Flat_Objects', 'jflash', 1, NULL),\\
    ('Long Objects', 'cat', 'long-object counters', 'Counters for long objects, pencils, pens, sticks, etc', 'Counters_:_Long_Objects', 'jflash', 1, NULL),\\
    ('Books', 'cat', 'book counters', 'Counters for books, magazines, etc', 'Counters_:_Books', 'jflash', 1, NULL),\\
    ('Rank', 'cat', 'rank counters', 'Counters for oridnal rank (in a race, etc)', 'Counters_:_Ordinal_Rank', 'jflash', 1, NULL),\\
    ('Order', 'cat', 'order counters', 'Counters for order in a series', 'Counters_:_Order_in_Series', 'jflash', 1, NULL),\\
    ('Containers', 'cat', 'container counters', 'Counters for containers (cup, mug, bowl, etc)', 'Counters_:_Containers', 'jflash', 1, NULL),\\
    ('Days of the Month', 'cat', 'days of month', 'Counters for days of the month', 'Counters_:_Days_of_Month', 'jflash', 1, NULL),\\
    ('Repetition/Times', 'cat', 'repetition', 'Counters for repetition/times', 'Counters_:_Repetition', 'jflash', 1, NULL),\\
    ('Floors of Building', 'cat', 'floors', 'Counters for floors of a building', 'Counters_:_Floors', 'jflash', 1, NULL),\\
    ('Written Using Kanji Alone', 'cat', 'usu. in kanji only', 'Word usually written using kanji alone', 'ukanji', 'edict', 0, 1);")
  end

end
