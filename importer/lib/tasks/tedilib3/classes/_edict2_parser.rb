#### EDICT2 PARSER #####
class Edict2Parser < Parser

  # Alias the base class' method 
  alias :run_super :run
  
  # Maybe move into the DB later?
  @@good_tags = {}
  @@possible_lang_tags = {}

  # Default EDICT values
  @@good_tags[:pos] = ["adj", "adj-f", "adj-i", "adj-na", "adj-no", "adj-pn", "adj-t", "adv", "adv-n", "adv-to", "aux", "aux-adj", "aux-v", "conj", "ctr", "exp", "f", "h", "id", "int", "iv", "m", "n", "n-adv", "n-pref", "n-suf", "n-t", "num", "pref", "prt", "suf", "symbol", "u", "v1", "v4h", "v4r", "v5", "v5aru", "v5b", "v5g", "v5k", "v5k-s", "v5m", "v5n", "v5r", "v5r-i", "v5s", "v5t", "v5u", "v5u-s", "v5uru", "v5z", "vi", "vk", "vn", "vs", "vs-i", "vs-s", "vt", "vz"]
  @@good_tags[:cat] = ["common", "2-ch term", "Buddh", "Catholic", "Edo-period", "Judeo-Christian", "MA", "X", "abbr", "aeronautical", "arch", "astronomical", "ateji", "baseball", "botanical", "botanical term", "chem", "chn", "col", "colour", "comp", "constellation", "derog", "ekana", "ekanji", "electrical", "fam", "fem", "food", "gagaku", "game of", "geom", "gikun", "gram", "hanafuda", "hon", "hum", "ikana", "ikanji", "io", "ling", "linguistic", "m-sl", "male", "male-sl", "masc", "math", "mil", "ng", "obs", "obsc", "okana", "okanji", "on-mim", "philosohical", "physics", "plant", "plant family", "poet", "pol", "political", "rare", "sens", "shogi", "sl", "sumo", "taxonomical", "telephone", "theatrical", "ukana", "ukanji", "vulg", "zoological"]
  @@good_tags[:lang] = ["ai", "ar", "bu", "ch", "de", "du", "el", "en", "es", "fr", "gr", "he", "id", "it", "kh", "ko", "ksb", "ktb", "kyb", "la", "ma", "ms", "nl", "no", "osb", "po", "pt", "rkb", "ro", "ru", "sa", "sv", "ta", "th", "thb", "ti", "tsb", "tsug", "wasei", "zh"]
  @@tag_transformations = { "P" => "common", "san"=>"sa", "ita"=>"it", "tib"=>"ti", "tha"=>"th", "kor"=>"ko", "dut"=>"du", "chi"=>"ch", "gre"=>"gr", "spa"=>"es", "khm"=>"kh", "tah"=>"ta", "ara"=>"ar", "may"=>"ma", "rus"=>"ru", "ain"=>"ai", "nor"=>"no", "por"=>"po", "eng"=>"en", "bur"=>"bu", "was"=>"wasei", "lat"=>"la", "ger"=>"de", "fre"=>"fr", "uK"=>"ukanji", "uk"=>"ukana", "oK"=>"okanji", "ok"=>"okana", "eK"=>"ekanji", "ek"=>"ekana", "iK"=>"ikanji", "ik"=>"ikana", "Buddhist"=>"Buddh", "euph. for"=>"euphemism", "computer"=>"comp", "in geometry"=>"geom", "in gagaku"=>"gagaku", "in hanafuda"=>"hanafuda", "military"=>"mil" }
  @@tag_ignore_list = ["also", "lit", "USA", "from", "form", "Note"]

  def set_tags(pos_tags, cat_tags, lang_tags)
    @@good_tags[:pos] = pos_tags
    @@good_tags[:cat] = cat_tags
    @@good_tags[:lang] = lang_tags
  end

  def run
    entries = []
    entries_by_headword = {}

    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|

      # Rough check for EDICT format conformance
      next if line.index("/").nil?
      line.strip!

      # Replace funky {} with ()
      line = line.gsub('{','(').gsub('}',')')
      
      headwords = []
      readings  = []
      readings_wout_ref = []
      meanings  = []
      all_pos_tags_per_sense = []
      pos_tags  = []
      cat_tags  = []
      lang_tags  = []
      common_flag = false

      # Get JMDICT REF
      #--------------------------
      jmdict_ref_arr = Edict2Parser.get_jmdict_ref(line)
      jmdict_ref_arr = ["#{@source_file_name.split('/').last}:#{line_no}"] if jmdict_ref_arr.size == 0 # create ref no based on source file

      # Get primary headword
      #--------------------------
      breakme = false
      headwords_arr = Edict2Parser.get_headwords(line)
      headwords_arr.each do |hw|
      tmp_hash = Edict2Parser.get_inline_tags(hw)
        headwords << self.class.get_headword_hash( tmp_hash[:string], Parser.combine_and_uniq_arrays(tmp_hash[:pos],tmp_hash[:cat]))
      end

      # Get Readings
      #--------------------------
      readings_arr = Edict2Parser.get_readings(line)
      readings_arr = [headwords_arr.first] if readings_arr.size < 1 and headwords_arr.first.scan($regexes[:kana_or_basic_punctuation]).size > 0
      tmp_reading = nil
      readings_arr.each do |r|
        # Package up the reading into a hash
        tmp_hash = Edict2Parser.get_inline_tags(r, $regexes[:comma_delimited])
        headword_ref_arr = tmp_hash[:custom]

        if !headword_ref_arr.nil? and headword_ref_arr.size > 0
          headword_refs = tmp_hash[:custom].join("\; ")
        else
          headword_refs = nil
        end
        tmp_reading = self.class.get_reading_hash(tmp_hash[:string], Importer.xfrm_to_romaji(tmp_hash[:string]), Parser.combine_and_uniq_arrays(tmp_hash[:pos],tmp_hash[:cat]), headword_refs)

        # Keep only explicitly referenced readings
        if headword_ref_arr.size > 0
          headword_ref_arr.each do |hw_ref|
            if headwords.first[:headword] == hw_ref
              readings << tmp_reading
            end
          end
        else
          readings_wout_ref << tmp_reading
        end

      end
      
      # Use implicitly referenced readings if no explicit ones were saved
      if readings.size < 1
        if readings_wout_ref.size > 0
          ### Use globally refd reading
          readings << readings_wout_ref
        elsif headwords.first[:headword].scan($regexes[:not_kana_nor_basic_punctuation]).size == 0
          ### Kana or punctuation only headword
          readings <<  self.class.get_reading_hash(headwords.first[:headword], Importer.xfrm_to_romaji(headwords.first[:headword]), [], [])
          #prt "Non-kanji headword!"
          #prt headwords.first[:headword]
        else
          ### Insert blank reading hash, no reading data found!
          readings << self.class.get_reading_hash(headwords.first[:headword], "", [], [])
          #prt "\nNo reading matched headword!"
          #prt readings_wout_ref
          #prt line
          #prt_dotted_line
        end
      end
      readings.flatten!

      # Get Meanings
      #----------------------------------------------------
      tmp_meanings_arr = Edict2Parser.get_meanings(line)
      
      # Extract POS tags appearing "before" the first numbered block (1)
      if tmp_meanings_arr.size > 1
        pos_tag_tmp = line.scan($regexes[:first_tag_like_block]).to_s
        pos_tag_arr = (pos_tag_tmp.size > 0 ? pos_tag_tmp.split($delimiters[:edict2_inlined_tags]) : [])
        pos_tags = Parser.combine_and_uniq_arrays(pos_tag_arr)
      end

      # Loop each gloss and process for tags
      tmp_meanings_arr.each do |meaning|

        # reset the array
        pos_tags_per_sense = []
        cat_tags_per_sense = []
        lang_tags_per_sense = []

        # Remove nested parentheticals
        meaning = remove_nested_parens(meaning.strip)
        
        # Process meaning/tags/refs
        meaning_data = Edict2Parser.get_inline_tags(meaning)

        # Clean leading slash-spaces, leading slash, trailing slash
        meaning_data[:string] = meaning_data[:string].gsub($regexes[:leading_space_slash],"/").strip.gsub($regexes[:leading_trailing_slashes], "")
        meaning_data[:string] = meaning_data[:string].gsub($regexes[:number_marker], "").gsub($regexes[:duplicate_spaces], " ").strip

        # Check for common tag
        if meaning_data[:cat].include?("common")
          ### We need this ## meaning_data[:cat].delete("common")
          common_flag = true
        end

        # Tags for this sense
        if tmp_meanings_arr.size > 1
          pos_tags_per_sense = Parser.combine_and_uniq_arrays(meaning_data[:pos]) # Multi-usage, local POS tags
        else
          pos_tags = Parser.combine_and_uniq_arrays(meaning_data[:pos]) # Single usage entries, POS tags are treated as GLOBAL
        end
        cat_tags_per_sense = Parser.combine_and_uniq_arrays(meaning_data[:cat])
        lang_tags_per_sense = Parser.combine_and_uniq_arrays(meaning_data[:lang])
        
        # Tags for whole entry
        all_pos_tags_per_sense << pos_tags_per_sense
        cat_tags << cat_tags_per_sense
        lang_tags << lang_tags_per_sense
        
        # Prepare result hash
        meanings << self.class.get_meaning_hash(meaning_data[:string], pos_tags_per_sense, cat_tags_per_sense, lang_tags_per_sense, meaning_data[:references])
      end

      # Merge in CLI passed cat tags with any inlined cat tags
      cat_tags = Parser.combine_and_uniq_arrays(@category_tags_array, cat_tags)
      lang_tags = Parser.combine_and_uniq_arrays(lang_tags)
      pos_tags = Parser.combine_and_uniq_arrays(pos_tags)
      all_pos_tags_per_sense = Parser.combine_and_uniq_arrays(all_pos_tags_per_sense)

      # Aggregate all tags including global and sense specific as ALL TAGS (DLH - duplicated in merge_duplicates)
      all_tags = Parser.combine_and_uniq_arrays(pos_tags, all_pos_tags_per_sense, cat_tags, lang_tags.collect{|l| l[:language] if l[:language] })
      entries << self.class.get_entry_hash(meanings, headwords, readings, jmdict_ref_arr, common_flag, pos_tags, cat_tags, all_tags)
    end

    return entries
  end

  # DESC: Gets edict tag from string, returns cleaned string and tags as hash
  def self.get_inline_tags(str, custom_regex_array=[])

    # -----------------------------------------------------------------------------------------
    #  DOCUMENTATION - DO NOT DELETE! - Structure based on JMDict DTD
    # -----------------------------------------------------------------------------------------
    #  ENTRY > SENSE
    #  + stagk.value = Contains HW-STRING-AS-KEY (current gloss applies to indicated HW only) (INTERNAL REF)
    #  + stagr.value = Contains READING-STRING-AS-KEY (current gloss applies to indicated READING only) (INTERNAL REF)
    #  + POS = part of speech (ALSO TAG TYPE)
    #  + XREF = cross reference by HW-STRING-AS-KEY or READING-STRING-AS-KEY (ANNOTATION)
    #  + ANT = antonym (ANNOTATION)
    #  + FIELD = field of use tag (ALSO TAG TYPE)
    #  + MISC = other info tag (ALSO TAG TYPE)
    #  + S_INF = additional usage info (ANNOTATION)
    #  + LSROUCE = language of origin e.g. <lsource xml:lang="kor"/> or <lsource xml:lang="ger">Abend</lsource> (ANNOTATION)
    #  + DIAL = japanese dialect (TAG INSTANCE ONLY)
    #  + GLOSS = the gloss / GLOSS['xml:lang']
    # -----------------------------------------------------------------------------------------

    lang_tags = []
    pos_tags = []
    cat_tags = []
    references = []
    custom_results = []
    new_str = str

    # Package into array if only a single value
    if not custom_regex_array.kind_of?(Array)
      custom_regex_array = [custom_regex_array]
    end

    # Loop all tag-like substrings
    #---------------------------------------
    str.scan($regexes[:tag_like_text]) do |tag_text|

      tag_text = tag_text.to_s
      original_tag_text = '(' + tag_text + ')'

      # Loop multiple, inlined tags (csv)
      #---------------------------------------
      tag_text.split($delimiters[:edict2_inlined_tags]).each do |tag|

        tag.strip!

        # Clean up tag & transform if necessary
        tag = Edict2Parser.transform_tag(tag.to_s.strip)

        # POS: Check if POS tags
        #---------------------------------------
        if @@good_tags[:pos].include?(tag)
          tag = Edict2Parser.transform_tag(tag)
          pos_tags << tag
          tag_type = "pos"
          new_str = replace_no_gaps(new_str, original_tag_text, '')
          #prt "pos"

        # FIELD / MISC / IMPLIED tags
        #---------------------------------------
        elsif @@good_tags[:cat].include?(tag)
          tag = Edict2Parser.transform_tag(tag)
          cat_tags << tag
          tag_type = "tag"
          new_str = replace_no_gaps(new_str, original_tag_text, '')
          #prt "tag"

        # STAGK / STAGR : Check if meaning specfier tag (reading/kanji)
        #--------------------------------------------------------------
        elsif (meaning_specifier_arr = tag.scan($regexes[:meaning_specifier])).size > 0
          meaning_specifier_arr = meaning_specifier_arr.to_s.split(',').collect {|s| s.to_s.strip}
          if meaning_specifier_arr.size > 0
            if meaning_specifier_arr.to_s.scan($regexes[:kana_or_basic_punctuation]).size > 0
              ref_type = "reading"
            else
              ref_type = "headword"
            end
          end
          references << { :type => ref_type, :target => meaning_specifier_arr }
          new_str = replace_no_gaps(new_str, original_tag_text, '')
          #prt "reading specifier"

        # ANT : Check if antonym
        #---------------------------------------------------
        elsif (antonym_arr = tag.scan($regexes[:antonym])).size > 0
          antonym_arr = antonym_arr.flatten.compact.collect {|s| s.to_s.strip}
          if antonym_arr.size > 0
            ref_type = "ant"
            references << { :type => ref_type, :target => antonym_arr[0].to_s }
            new_str = replace_no_gaps(new_str, original_tag_text, '')
          end
          #prt "ant"

        # XREF : Check if cross reference
        #---------------------------------------------------
        elsif (xref_arr = tag.scan($regexes[:xreference])).size > 0
          xref_arr = xref_arr.flatten.compact.collect {|s| s.to_s.strip}
          if xref_arr.size > 0
            ref_type = "xref"
            references << { :type => ref_type, :target => xref_arr[0].to_s }
            new_str = replace_no_gaps(new_str, original_tag_text, '')
          end
          #prt "xref"

        # LSOURCE: Check if language source tag
        #---------------------------------------
        elsif (lang_tag_arr = tag_text.scan($regexes[:lang_tag])).size > 0

          # Multiple Lang Tags??
          if tag_text.index($delimiters[:edict2_inlined_lang_tags])
            lang_tag_arr = []
            tag_text.split($delimiters[:edict2_inlined_lang_tags]).each do |l|
              lang_tag_arr << l.scan($regexes[:lang_tag]).flatten
            end
          else
            lang_tag_arr = [lang_tag_arr.flatten.compact]
          end

          inline_lang_tag = ""
          lang_tag_arr.each do |l_arr|
            tag = Edict2Parser.transform_tag(l_arr[0].to_s)
            if @@good_tags[:lang].include?(tag)
              lang_source_word = (l_arr.size > 1 ? l_arr[1] : "").strip
              lang_tags << { :language => tag, :word => lang_source_word }
            end
          end
          inline_lang_tag_arr = []
          inline_lang_tag_arr = lang_tags.collect{|l| l[:word] if l[:word] != ""}.compact
          inside_text =  (inline_lang_tag_arr.size > 0 ? "(cf. "+inline_lang_tag_arr.join(", ")+")" : "")
          new_str = replace_no_gaps(new_str, original_tag_text, inside_text).strip
          #prt "lang"

        # Skip numeric, ignore-list or "quasi-lang" tags
        #-------------------------------------------------
        elsif tag.scan(/\D+/).size == 0
          #prt "WARNING: Ignored numeric tag: #{tag} in #{str}"
          #prt "numeric"

        elsif @@tag_ignore_list.include?(tag)
          #prt "WARNING: Found ignore list tag: #{tag}"
          #prt "ignore"

        # Allow multiple, custom regexes to be passed in
        # Custom regexes run only if previous ones don't match!
        #------------------------------------------------------
        elsif custom_regex_array.size > 0
          matched = false
          custom_regex_array.each do |regex|
            if (tmp_arr = tag.scan(regex).flatten.compact).size > 0
              custom_results << tmp_arr.collect {|s| s.strip}
              matched = true
            end
          end
          new_str = replace_no_gaps(new_str, original_tag_text, '') if matched
        end
        #prt "custom"

      end
    end

    custom_results = custom_results.flatten.compact
    return { :string => new_str.strip, :pos => pos_tags.uniq, :cat => cat_tags.uniq, :lang => lang_tags.uniq, :references => references, :custom => custom_results}
  end

  # Extracts and returns headword block
  def self.get_headwords(line)
    line[0..line.index(" ")-1].gsub(',', $delimiters[:edict2_headwords]).split($delimiters[:edict2_headwords])
  end

  # Returns the new JMDICT Entry ID (now stored in EDICT!)
  def self.get_jmdict_ref(line)
    tmp=line.match($regexes[:edict_entry_id])
    if !tmp.nil? and tmp.size > 0
      ### NOT SURE what the X is for, delete X to match IDs to JMDICT XML file
      return [tmp[1].to_s.gsub("X","")]
    else
      return []
    end
  end
  
  # Simple extractor returning single or multiple usages in array
  def self.get_meanings(line)
    carried_tags_from_previous_line_str = ""    # holds any carried tags across one loop cycle
    usages_arr = []
    line.gsub!($regexes[:edict_entry_id], "/") # Remove the EDICT Entry ID
    line.gsub!(";", ",") # Remove any seimcolons, these are not valid for EDICT!
    lines = line.scan($regexes[:usages_multiple]).flatten.compact
    
    lines = line.scan($regexes[:usages]) if lines.size == 0
    if lines.size > 0
      lines.each do |u|
        u = replace_one_char_in_parens(u.to_s, ";", ",") # Scrub any ';' in meanings with ','
        
        # Do I have a bit from the last run
        if carried_tags_from_previous_line_str != ""
          u = "(" + carried_tags_from_previous_line_str + ") " + u
          carried_tags_from_previous_line_str = ""
        end
        
        # Do I need to strip off the end bit?
        misplaced_tag_arr = u.strip.scan($regexes[:inlined_tags])
        if misplaced_tag_arr.size > 0
          is_indeed_misplaced = true
          misplaced_tag_arr.to_s.split($delimiters[:edict2_inlined_tags]).each do |t|
            is_indeed_misplaced = (is_indeed_misplaced and Edict2Parser.is_pos_tag?(t))
          end
          if is_indeed_misplaced
             carried_tags_from_previous_line_str = u.strip.scan($regexes[:inlined_tags]).to_s
             u.strip!
             u.gsub!("/("+carried_tags_from_previous_line_str+")","")
          end
        end
        u.gsub!($regexes[:leading_trailing_slashes], "")
        usages_arr << u
      end
    else
      prt("WARNING --- Regex /FAIL/ - No usage found!\n#{line}\n\n") if @warning_level == "VERBOSE"
    end
    return usages_arr
  end

  # Returns readings block, changing ';' in parentheses to ',' to avoid splitting mistakes
  def self.get_readings(line)
    replace_one_char_in_parens(line.scan($regexes[:inside_hard_brackets]).to_s, $delimiters[:edict2_readings], $delimiters[:edict2_readings_alt]).split($delimiters[:edict2_readings])
  end

  # Get tags relevant to ALL definitions in the entry
  def self.get_global_tags(line)
    tmp = []
    tmp << line[$regexes[:global_definition_tags]]
    tmp << line[$regexes[:compdic_style_global_tags]]
    tmp << line[$regexes[:p_tag]]
    tmp.flatten.compact.uniq!
    return tmp
  end
    
  # Splits headwords into strings 'primary' and 'other'
  def self.split_headwords(headwords_array)
    # Get text before first space, remove paretheticals
    primary = headwords_array[0].to_s
    other = ""
    # get other_headwords
    if headwords_array.length > 1
      headwords_array.delete_at(0)
      other = headwords_array.join($delimiters[:edict2_headwords])
    end
    return primary, other
  end

  # Transforms tag or not, according to @@tag_transformations entries
  def self.transform_tag(tag)
    if @@tag_transformations.has_key?(tag)
      return @@tag_transformations[tag]
    else
      return tag
    end
  end

  # String Utility - Replaces occurences inside parentheses ofsingle character 'replace' with 'with'
  def self.replace_one_char_in_parens(str, replace, with)
    new_str = ""
    ins = false
    nested_found = false
    nesting_level=0

    # Can only replace one character at a time
    replace = replace[0..1]
    with = with[0..1]
    
    str.each_char do |s|
      # Replace character in brackets
      new_str = ( nesting_level > 0 && s == replace ? (new_str + with) : (new_str + s))
      if s=="("
        ins = true
        nesting_level+=1
      elsif ins && s==")"
        nesting_level-=1
      end
      if nesting_level == 0
        ins = false
      elsif nesting_level < 0
        ## suppress errors ## exit_with_error("ERROR: Over-Closed Braces!!!", usage)
      end
    end

    if nesting_level != 0
      # Add closing brackets as needed!
      nesting_level.downto(0) { |i| str = str + ")" }
    end
    return new_str
  end

  # String Utility - returns string without nested brackets
  def remove_nested_parens(str)
    new_str = ""
    ins = false
    nested_found = false
    nesting_level=0

    str.each_char do |s| 
      # Remove Nested Brackets
      if nesting_level == 0 || (nesting_level == 1 && s == ")") || (nesting_level > 0 && s != "(" && s != ")")
        new_str = new_str + s
        #prt "level #{nesting_level}: "+s + "  +"
      #else
        #prt "level #{nesting_level}: "+s + "  -"
      end
      if s=="("
        ins = true
        nesting_level+=1
      elsif ins && s==")"
        nesting_level-=1
      end
      if nesting_level == 0
        ins = false
      elsif nesting_level < 0
        exit_with_error("ERROR: Over-Closed Braces!!!", usage)
      end
    end

    if nesting_level != 0
      # Add closing brackets as needed!
      nesting_level.downto(0) { |i| str = str + ")" }
    end
    return new_str
  end

  def self.is_pos_tag?(tag)
    return (@@good_tags[:pos].index(tag) ? true : false)
  end
  
  def self.is_language_tag?(tag)
    return (@@good_tags[:lang].index(tag) ? true : false)
  end
  
  def self.is_other_tag?(tag)
    return (@@good_tags[:cat].index(tag) ? true : false)
  end

  # XFORMATION: One time migrator for updating tags_staging with legacy pos/cat/lang data
  def self.xfrm_categorise_staging_tags
    
    connect_db
    good_tags={}
    sourcenames = {}
    good_tags[:pos] = ["adj", "adj-f", "adj-i", "adj-na", "adj-no", "adj-pn", "adj-t", "adv", "adv-n", "adv-to", "aux", "aux-adj", "aux-v", "conj", "ctr", "exp", "f", "h", "id", "int", "iv", "m", "n", "n-adv", "n-pref", "n-suf", "n-t", "num", "pref", "prt", "suf", "symbol", "u", "v1", "v4h", "v4r", "v5", "v5aru", "v5b", "v5g", "v5k", "v5k-s", "v5m", "v5n", "v5r", "v5r-i", "v5s", "v5t", "v5u", "v5u-s", "v5uru", "v5z", "vi", "vk", "vn", "vs", "vs-i", "vs-s", "vt", "vz"]
    good_tags[:cat] = ["common", "2-ch term", "Buddh", "Catholic", "Edo-period", "Judeo-Christian", "MA", "X", "abbr", "aeronautical", "arch", "astronomical", "ateji", "baseball", "botanical", "botanical term", "chem", "chn", "col", "colour", "comp", "constellation", "derog", "ekana", "ekanji", "electrical", "fam", "fem", "food", "gagaku", "game of", "geom", "gikun", "gram", "hanafuda", "hon", "hum", "ikana", "ikanji", "io", "ling", "linguistic", "m-sl", "male", "male-sl", "masc", "math", "mil", "ng", "obs", "obsc", "okana", "okanji", "on-mim", "philosohical", "physics", "plant", "plant family", "poet", "pol", "political", "rare", "sens", "shogi", "sl", "sumo", "taxonomical", "telephone", "theatrical", "ukana", "ukanji", "vulg", "zoological"]
    good_tags[:lang] = ["ai", "ar", "bu", "ch", "de", "du", "el", "en", "es", "fr", "gr", "he", "id", "it", "kh", "ko", "ksb", "ktb", "kyb", "la", "ma", "ms", "nl", "no", "osb", "po", "pt", "rkb", "ro", "ru", "sa", "sv", "ta", "th", "thb", "ti", "tsb", "tsug", "wasei", "zh"]
    
    # Index all the sourc names
    result = $cn.select_all("SELECT tag_id, source_name FROM tags_staging WHERE parent_tag=1")
    result.each do |sqlrow|
      sqlrow['source_name'].split($delimiters[:jflash_tag_sourcenames]).each do |t|
        sourcenames[t] = sqlrow['tag_id'].to_i
      end
    end

    # Loop each known list of good tags
    ["pos", "cat", "lang"].each do |type|
      good_tags[type.to_sym].each do |t|
        if sourcenames[t]
          $cn.execute("UPDATE tags_staging SET tag_type ='#{type}' WHERE tag_id = #{sourcenames[t]}")
          prt "UPDATE tags_staging SET tag_type ='#{type}' WHERE tag_id = #{sourcenames[t]}" 
        end
      end
    end

    # Update any leftovers to CAT tags, this list should be checked!
    $cn.execute("UPDATE tags_staging SET tag_type ='cat' WHERE tag_type IS NULL")
    
  end

  # DESC: Gets headwords/readings from unmatched JLPT file and collates with matching entries from second file
  def run_collate_unmatched_jlpt(new_fn, umatched_fn)

    unmatched_count=0
    err_count=0
    out_count=0

    new_file = File.open(new_fn)
    new_data_headword_idx = {}
    new_file.each do |line|
      next if line.index("/").nil?
      line.strip!
      headword_str = self.class.get_headwords(line).join($delimiters[:edict2_headwords])
      reading_str = self.class.get_readings(line).join($delimiters[:edict2_readings])
      # replace reading with headword if it contains zenkaku parens
      if reading_str.scan("（").size > 0
        new_reading_str = headword_str
        line.gsub!("["+reading_str+"]", "["+new_reading_str+"]")
      end
      new_data_headword_idx[headword_str] = line
    end

    # setup out file for unmatched entries
    errors_fn = umatched_fn.gsub("_unmatched.txt","") + "_unmatchable.txt"
    File.delete(errors_fn) if File.exist?(errors_fn) # delete old tmp files
    errorf= File.open(errors_fn, "w")

    # setup out file for matches
    out_fn = umatched_fn.gsub("_unmatched.txt","") + "_rematched.txt"
    File.delete(out_fn) if File.exist?(out_fn) # delete old tmp files
    outf = File.open(out_fn, "w")

    # Call run's super to process loop for us
    run_super do |line, line_no, cache_data|

      line.strip!
      unmatched_count+=1

      if line.index("/").nil?
        prt "Empty entry found for #{headword_str}"
        err_count+=1
        errorf.write(line +"\n")
        next
      end

      headword_str = self.class.get_headwords(line).join($delimiters[:edict2_headwords])
      reading_str = self.class.get_readings(line).join($delimiters[:edict2_readings])

      if reading_str.scan($regexes[:not_kana_nor_basic_punctuation]).size > 0
        # Invalid characters found in reading
        prt "Invalid characters found in reading #{reading_str}"
        err_count+=1
        errorf.write(line +"\n")
      elsif new_data_headword_idx.has_key?(headword_str)
        # Output matched lines
        out_count+=1
        new_line = new_data_headword_idx[headword_str]
        outf.write(new_line +"\n")
      else
        # Headword is not in new file
        prt "Entry not found for #{headword_str}"
        err_count+=1
        errorf.write(line +"\n")
      end
    end

    prt "Here are the results..."
    prt_dotted_line
    prt "Total entries retried        : #{unmatched_count}"
    prt "Total entries matched        : #{out_count}"
    prt "Total entries unable to match: #{err_count}"
    prt ""

    errorf.close
    outf.close
    
  end

end