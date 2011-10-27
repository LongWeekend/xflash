#### CEdict IMPORTER #####
class CEdictImporter < CEdictBaseImporter

  def process_duplicates_into_entry_sql(cedict_rec, duplicates_arr)
    @update_entry_sql = "UPDATE cards_staging SET headword_en='%s', meaning='%s', meaning_html='%s',meaning_fts='%s', tags='%s', cedict_hash = '%s' WHERE card_id = %s;"
    @update_tags_sql  = "UPDATE cards_staging SET meaning = '%s', meaning_html = '%s', tags='%s',cedict_hash = '%s' WHERE card_id = %s;"

    # LOOP through each possible duplicate and go
    duplicates_arr.each do |dupe|

      # Merge existing, format meaning variously, do tags and refs
      merged_entry, meaning_strings_merged = merge_duplicate_entries(cedict_rec, dupe)
    
      all_tags_list = combine_and_uniq_arrays(merged_entry.all_tags).join($delimiters[:jflash_tag_coldata])

      # Serialise for storage in DB
      serialised_cedict_rec = mysql_serialise_ruby_object(merged_entry)

      # Remove embedded card_id from hash 
      merged_entry_card_id = merged_entry.id.to_i
      merged_entry.set_id(-1)

      if meaning_strings_merged
        # UPDATE HEADWORD_EN, MEANINGS & TAGS
        ##prt " - Merging tags & meaning!"
        return @update_entry_sql % [ merged_entry.headword_en, mysql_escape_str(merged_entry.meanings_txt), mysql_escape_str(merged_entry.meanings_html), mysql_escape_str(merged_entry.meanings_fts), all_tags_list, serialised_cedict_rec, merged_entry_card_id]
      else
        # UPDATE VISIBLE MEANINGS & TAGS
        ##prt " - Merging tags only!"
        return @update_tags_sql % [mysql_escape_str(merged_entry.meanings_txt), mysql_escape_str(merged_entry.meanings_html), all_tags_list, serialised_cedict_rec, merged_entry_card_id]
      end
    end # duplicates_arr.each do
  end

  # DESC: Check if duplicate exists in existing array, returns dupe edict2hashes
  def get_duplicates_by_headword_reading(cn_headword_trad, readings_str, existing_card_lookup_hash, entry_scope = 0)
    duplicates = []
    if existing_card_lookup_hash.has_key?(entry_scope)
      if existing_card_lookup_hash[entry_scope][cn_headword_trad]
        existing_card_lookup_hash[entry_scope][cn_headword_trad].each do |card_id|
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
        pos_tags_arr = combine_and_uniq_arrays(pos_tags_arr)
        pos_tag_suffix = (pos_tags_arr.size > 0 ? " (#{pos_tags_arr.join($delimiters[:jflash_inlined_tags])})" : "")
        
        # Merge in CAT tags
        cat_tags_arr = (existing_meaning[:cat].nil? ? [] : existing_meaning[:cat])
        if new_cat_tags_per_sense.has_key?(sense_number) and new_cat_tags_per_sense[sense_number].size > 0
          cat_tags_arr << new_cat_tags_per_sense[sense_number]
        end
        cat_tags_arr = combine_and_uniq_arrays(cat_tags_arr)

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
        existing_entry.meanings[sense_number-1][:tags] = combine_and_uniq_arrays(existing_entry.meanings[sense_number-1][:pos])
        existing_entry.meanings[sense_number-1][:tags] = combine_and_uniq_arrays(existing_entry.meanings[sense_number-1][:cat])

      end

    end

    ### Update references in case we merge
    ###################################
#    if !existing_entry[:jmdict_refs].nil?
#      merged_reference = combine_and_uniq_arrays(existing_entry[:jmdict_refs].split($delimiters[:jflash_jmdict_refs]), new_entry[:jmdict_refs])
#    else
#      merged_reference = []
#    end

#    existing_entry[:pos] = combine_and_uniq_arrays(existing_entry[:pos], new_entry[:pos])
#    existing_entry[:cat] = combine_and_uniq_arrays(existing_entry[:cat], new_entry[:cat])

    # Aggregate all tags including global and sense specific as ALL TAGS
 #   all_lang_tags_arr.flatten!
#    existing_entry[:all_tags] = combine_and_uniq_arrays(existing_entry[:pos], existing_entry[:cat], all_lang_tags_arr.collect{|l| l[:language] if l[:language]})
#    existing_entry[:jmdict_refs] = merged_reference

    ### DEBUG ##  prt "expected_array << "; pp existing_entry; prt ""
    return existing_entry, meaning_strings_merged
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

end
