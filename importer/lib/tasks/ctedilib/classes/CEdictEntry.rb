# Single entry class - based on active record?
class CEdictEntry < Entry

  include CardHelpers

  # These are class variables
  @@good_tags = ["classical", "golf", "mechanics", "honorific", "Chinese medicine", "psychology",
                 "telecommunications", "technology", "slang", 
                 "physiology", "agriculture", "astronomy", "military", "sexual", "mechanics","suffix",
                 "prefix","navigation","animal","electric","phonetic","automotive","zoology", "mythology",
                 "electronics", "meteorology","accountancy","derogatory","political","Communist","martial arts",
                 "color","archaic","topolect", "pharmacology","buddhism", "sports", "statistics", "fashion",
                 "colloquial", "idiom", "onomatopoeia", "philosophy", "expression", "vulgar", "interjection",
                 "Taiwan", "Cantonese", "computing", "software", "law", "constellation", "economics", "finance",
                 "dialect", "loanword", "geometry", "formal", "language", "abbr", "literary", "mathematics",
                 "grammar", "geology", "medicine", "anatomy", "computing", "name", "music", "linguistics",
                 "biology", "botany", "chemistry", "honorific", "physics", "slang", "buddhism"]

  @@partial_tags = {"greek" => /Greek letter/, "zhuang" => /Zhuang/, "amoy" => /Amoy/, "sanskrit" => /[sS]anskrit/,
                 "idiom" => /idiom/, "derogatory" => /derog/, "humble" => /humble/, "mathematics" => /math\./,
                 "electric"=> /electric/ , "euphemism" => /euphemism/, "kangxi" => /Kangxi radical/,
                 "constellation" => /constellation/, "computing" => /programming/, "particles" => /final particle/,
                 "abbr" => /abbreviated/, "mathematics" => /calculus|algebra|polar coordinate/, "political" => /diplomatic/, 
                 "mechanics" => /mechanics/, "Communist" => /[Cc]ommunist/, "military" => /military/,
                 "business" => /business/,"onomatopoeia"=> /onomatopoeia/,  "archaeology" => /archaeology/,
                 "biology" => /biology/, "computing" => /computing/, "archaic" => /arch\./, "punctuation" => /punc./,
                 "slang" => /slang/, "finance" => /derivative trading/, "colloquial" => /colloquial/,
                 "interjection" => /interj/, "archaic"=> /archaic/, "email" => /email/, "expression" => /common saying/,
                 "Chinese medicine" => /Chinese medicine/, "computing" => /keyboard/, "physics" => /physics/,
                 "music" => /instrument/, "zoology" => /taxonom/, "phonetic" => /phonetic/, "sports" => /gymnastic/, 
                 "logic" => /logic/, "computing" => /computer/, "korean" => /Korea/, "honorific" => /honorific/,
                 "loanword" => /loanword/, "colloquial" => /informal/,"dialect"=> /dialect/, "topolect" => /topolect/,
                 "tibetan" => /Tibetan/, "mongolian" => /Mongolian/, "uighur" => /Uighur/, "russian" => /Russian/,
                 "aramaic" => /Aramaic/, "japanese" => /Japanese/, "grammar" => /grammar/, "buddhism"=> /Budd/ }

  @@ignore_tags = [/^usu\. /, /^of a/, /^s$/, /^[A-Z0-9]{1,5}$/, /city in/, /one's/, /in a /, /also/, /see /, /someone/, /cf\./, /to sb/, /sb's/, /fig\./, /sth/, /lit\./, /(e\.g\.)/, /(i\.e\.)/, /[0-9]{1,4}-[0-9]{1,4}/, /-[0-9]{2,4}/, /[0-9]{2,4}-/, /etc/, /esp\./ ]
  
  @@tag_transformations = { "common saying" => "expression", "athletics" => "sports", "polite"=>"formal",
  "gymnastics"=>"sports", "person name"=>"name", "hon."=>"honorific", "geological" => "geology",
  "historical"=>"history", "common expression" => "expression","elec."=>"electric", "politics" => "political",
  "derog."=>"derogatory","computing software"=>"software","pharm."=>"pharmacology", "arch."=>"archaic", 
  "old"=>"archaic", "old term"=>"archaic", "old usage"=>"archaic","onomatopeia"=>"onomatopoeia", "zoo." => "zoology",
  "euph." => "euphemism", "computer"=>"computing",
  "banking"=>"finance", "coll." => "colloquial","expr." => "expression", "math" => "mathematics",
  "math." => "mathematics", "med." => "medicine","abbr."=>"abbr", "interj." => "interjection",
  "informal" => "colloquial", "medical" => "medicine","ling."=>"language", "comp." => "computing",
  "punct." => "punctuation", "biol." => "biology", "onomat." => "onomatopoeia", "Cant." => "Cantonese" }
  #@@tag_ignore_list = ["also", "lit", "USA", "from", "form", "Note"]
#Sanskrit:
#Tibetan:
#Japanese:
#Mongolian:
#Uighur:

#ignore:
#e.g. 
#i.e.
#dates


  #===================================
  # Parses a line from the CEDICT data source
  #===================================
  def parse_line (line = "")
    init

    @line_to_parse = line

    # A little sanity checking on line
    if @line_to_parse.nil?
      return false
    end
    
    # Get the headwords, traditional then simplified
    headword_arr = get_headwords(@line_to_parse)
    @headword_trad = headword_arr[0]
    @headword_simp = headword_arr[1]
    
    # Now get the reading
    @pinyin = get_pinyin(@line_to_parse)
    
    # The "true" keeps the spaces in the pinyin - we want that for our FTS database
    @pinyin_diacritic = get_pinyin_unicode_for_reading(@pinyin, true)
    @meanings = get_meanings(@line_to_parse)
    
    # Finally make an English headword out of the first meaning
    if (@meanings.size > 0)
      @headword_en = extract_en_headword(@meanings.first[:meaning].strip)
    end
  end

  #==================================
  # Parsing helper methods
  #==================================
 
  # Extracts and returns headword block
  def get_headwords(line = "")
   index = line.index("[") - 1
   return line[0..index].split(" ")
  end
  
  def get_pinyin(line = "")
    first_index = line.index("[") + 1
    second_index = line.index("]") - 1
    return line[first_index..second_index]
  end
  
  def get_meanings(line = "")
    first_index = line.index("] /") + 3
    length = line.length
    rough_meanings = line[first_index..length].split("/")

    # Now check for tags and variants
    refined_meanings = []
    rough_meanings.each do |meaning|
      
      # Loop state variable
      skip_this_meaning = false;
      tag = false
      
      # Is this whitespace?
      skip_this_meaning = true if (meaning.strip == "")

      # Is this a reference?
      meaning = strip_references_from_meaning(meaning)

      # Get tags from meaning - double return is hacky, but it keeps this code cleana
      meaning, tags = get_and_strip_tags_from_meaning(meaning)
      
      # Erhua - do this BEFORE variants
      meaning = strip_erhua_variant(meaning) if found_erhua_variant(meaning)
      
      # Variants - do this AFTER erhua
      meaning = strip_variant(meaning) if found_variant(meaning)
      
      # Do we have any meaning left?
      if !meaning
        skip_this_meaning = true
      end
      
      # Classifiers - we don't want to add classifier meanings
      skip_this_meaning = true if found_classifier(meaning)

      if (!skip_this_meaning)
        tmp_hash = {:meaning=>meaning, :tags=>tags}
        refined_meanings << tmp_hash
      end
    end
    return refined_meanings
  end
  
  # Helper function to prevent the above method from getting out-of-control large

  def get_and_strip_tags_from_meaning(meaning)  
  
    # Quick return
    return false if !meaning

    tags = []
    tags_hash = get_tags_for_meaning(meaning)
    tags << tags_hash[:full_match]
    tags << tags_hash[:partial_match]
    tags.flatten!
    if !(tags_hash[:full_match].empty?)
      # Only remove FULL match tags
      meaning = strip_tags_from_meaning(meaning,tags_hash[:full_match])
      # Now transform tags if necessary (needs to be done after strip)
      new_tags = []
      tags.each do |tag|
        if @@tag_transformations.has_key?(tag)
          new_tags << @@tag_transformations[tag]
        else
          new_tags << tag
        end
      end
      tags = new_tags
    end
    tags << "abbr" if (found_abbreviation(meaning) and !tags.include?("abbr"))
    return meaning, tags
  end

  # VARIANT DETECTION
  
  # This method is not written well... duplicated code and such.
  def found_variant (meaning = "")

    # Quick return if bad input
    return false if !meaning
    
    # First try the variant+meaning
    variant_regex = /variant of (.+)(,\s)+(.+)/
    meaning.scan(variant_regex) do |variant|
      @variant_of = variant[0]
      return true
    end

    # Now try variant only
    variant_regex = /variant of (.+)/
    meaning.scan(variant_regex) do |variant|
      @variant_of = variant[0]
      return true
    end
    
    return false
  end
  
  def strip_variant (meaning = "")
    if meaning_is_variant_only(meaning)
      return false
    else
      start_index = meaning.index(",") + 2
      return meaning[start_index..meaning.length]
    end
  end
  
  def meaning_is_variant_only(meaning = "")
    variant_regex = /variant of (.+)(,\s)+(.+)/
    meaning.scan(variant_regex) do |variant|
      if (variant[1] == ", ")
        return false
      else
        return true
      end
    end
  end
  
  # ERHUA DETECTION
  
  def found_erhua_variant(meaning = "")

    # Quick return if bad input
    return false if !meaning

    variant_regex = /erhua variant of (.+)/
    meaning.scan(variant_regex) do |variant|
      @is_erhua_variant = true
      return @is_erhua_variant
    end
    return false
  end
  
  def strip_erhua_variant(meaning = "")
    variant_regex = /erhua (variant of .+)/
    meaning.scan(variant_regex) do |variant|
      return variant[0]
    end
    # This shouldn't happen but just in case
    return meaning
  end
  
  # REFERENCE DETECTION
  
  def strip_references_from_meaning(meaning = "")
  
    false_positive_regex = /see you/
    meaning.scan(false_positive_regex) do |false_positive|
      # If we have a false positive just return
      return meaning
    end
    ref_regex = /\Asee (also |)([^a-zA-Z0-9\s]+)(\[[\sA-Za-z0-9]+\])*\z/
    stripped = false
    meaning.scan(ref_regex) do |reference|
      stripped = true
      @references << ("%s%s" % [reference[1],reference[2]])
    end

    if stripped
      return false
    else
      return meaning
    end
  end
  
  # TAG DETECTION
  
  def get_tags_for_meaning(meaning = "")
  
    # Quick return if bad input
    return false if !meaning
    
    # Set up return dictionary hash
    tags_hash = {:full_match =>[],:partial_match => []}

    tag_regex = /\(([^\)]+)\)/
    meaning.scan(tag_regex) do |tag_text|
      the_tag = tag_text[0]
      # Now see if it is in the good tags whitelist or transformations list
      if (@@good_tags.include?(the_tag) or @@tag_transformations.has_key?(the_tag))
        tags_hash[:full_match] << the_tag
      else
        # If it wasn't a direct match, see if it hits our ignore list
        matched = false
        @@ignore_tags.each do |ignore_tag_regex|
          the_tag.scan(ignore_tag_regex) do |match|
            matched = true
          end
        end #ignore matches
        
        # See if we have a partial match
        if !matched
          @@partial_tags.each do |key, partial_tag_regex|
            the_tag.scan(partial_tag_regex) do |match|
              tags_hash[:partial_match] << key
              matched = true
            end
          end
        end #partial match
        
#        if !matched
#          prt "Unknown tag: %s" % the_tag
#        end
        
      end
    end
    
    # Also, try surname
    surname_regex = /surname [A-Za-z]+/
    meaning.scan(surname_regex) do
      tags_hash[:full_match] << "surname"
    end
    
    return tags_hash
  end
  
  def strip_tags_from_meaning(meaning = "",tags = [])
    tags.each do |this_tag|
      search_string = " (%s)" % this_tag
      meaning.gsub!(search_string,"")
#      first_index = meaning.index(search_string) - 2
#      meaning = meaning[0..first_index]
    end
    return meaning
  end

  # ABBR DETECTION
  
  def found_abbreviation(meaning = "")
    abbr_regex = /abbr\./
    meaning.scan(abbr_regex) do |match|
      return true
    end
    return false
  end

  # CLASSIFIER DETECTION

  def found_classifier(meaning = "")
    # Quick return if bad input
    return @classifer if !meaning

    classifier_regex = /CL:(.+)/
    meaning.scan(classifier_regex) do |cl|
      @classifier = cl[0]
    end
    return @classifier
  end
  
  # EXTRACT ENGLISH HEADWORD FROM MEANING
  
  def extract_en_headword(first_meaning_string)
    if (first_meaning_string.length > 0)
      return first_meaning_string.gsub("'","''").gsub('  ',' ').gsub('/', ' / ').split("/").first.strip
    else
      return first_meaning_string
    end
  end
  
  # FORMAT MEANING STRINGS FOR HUMAN CONSUMPTION
  
  def meaning_fts(tag_mode="inhuman")
    meanings_fts_arr   = []
    sense_count = @meanings.size
    @meanings.each do |m|
      meaning_str = m[:meaning]
      meaning_str = xfrm_remove_stop_words(meaning_str.gsub($regexes[:inlined_tags], "").strip)
      meanings_fts_arr << meaning_str unless meanings_fts_arr.include?(meaning_str)
    end

    return meanings_fts_arr.join(" ")
  end
  
  def meaning_html(tag_mode="inhuman")
    meanings_html_arr  = []
    sense_count = @meanings.size
    @meanings.each do |m|
      mtxt, mhtml = xfrm_inline_tags_with_meaning(@pos, m[:meaning], tag_mode)
      mhtml = "<li>#{mhtml}</li>" unless sense_count == 1
      meanings_html_arr << mhtml
    end
    html = meanings_html_arr.collect { |d| d }.join("")
    html = "<ol>" + html + "</ol>" unless sense_count <= 1
    return html
  end
  
  def meaning_txt(tag_mode="inhuman")
    meanings_text_arr  = []
    sense_count = @meanings.size
    @meanings.each do |m|
      mtxt, mhtml = xfrm_inline_tags_with_meaning(@pos, m[:meaning], tag_mode)
      meanings_text_arr << mtxt
    end
    return meanings_text_arr.join($delimiters[:jflash_meanings]);
  end

  ## TRANSFORM 
  def xfrm_inline_tags_with_meaning(tag_array, meaning_str, tag_mode="inhuman")

    tag_buffer =[]

    # Extract trailing parentheticals, re-insert if not tags!
    inlined_tags = meaning_str.scan($regexes[:inlined_tags]).to_s
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

    meaning_str = meaning_str + trailing_parentheticals
    mtxt  = (pos_tag_array.size > 0 ? meaning_str + " (" + pos_tag_array.join($delimiters[:jflash_inlined_tags]) + ")" : meaning_str)
    mhtml = (pos_tag_array.size > 0 ? meaning_str + " "  + pos_tag_array.collect{ |t| "<dfn>#{t}</dfn>" }.join("") : meaning_str)

    return mtxt, mhtml
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
  
  # XFORMATION: Returns inhuman tag name from the DB, caching everything on first call
  def xfrm_pos_tag_to_inhuman_tag(tag)
    cache_tag_data if $shared_cache[:pos_tag_inhuman_readings].nil?
    if $shared_cache[:pos_tag_inhuman_readings].has_key?(tag)
      return $shared_cache[:pos_tag_inhuman_readings][tag][:inhumanised]
    else
      return tag
    end
  end

  # DESC: Caches staging database tag data
  
  def cache_tag_data
    $shared_cache[:pos_tag_human_readings] = {}
    $shared_cache[:pos_tag_inhuman_readings] = {}
    connect_db
    results = $cn.select_all("SELECT tag_id, short_name, source_name FROM tags_staging WHERE source = 'edict'")
    tickcount("Caching Existing CEDICT tags") do
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

end