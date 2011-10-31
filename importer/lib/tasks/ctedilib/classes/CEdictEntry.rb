# Single entry class - based on active record?
class CEdictEntry < Entry

  include CardHelpers


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
    @pinyin_diacritic = Entry.get_pinyin_unicode_for_reading(@pinyin, true)
    @meanings = parse_meanings(@line_to_parse)
    
    # Finally make an English headword out of the first meaning
    if (@meanings.size > 0)
      @headword_en = extract_en_headword(@meanings.first.meaning.strip)
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
  
  def parse_meanings(line = "")
    first_index = line.index("] /") + 3
    length = line.length
    rough_meanings = line[first_index..length].split("/")

    # Now check for tags and variants
    refined_meanings = []
    rough_meanings.each do |meaning_str|
      if (meaning_str.strip != "")
      
        # Create new meaning object and parse the string
        meaning = Meaning.new(meaning_str)
        meaning.parse
      
        # Classifiers - we don't want to add classifier meanings
        skip_this_meaning = true
        if meaning.classifier
          @classifier = meaning.classifier
        elsif meaning.variant
          @variant_of = meaning.variant
          skip_this_meaning = meaning.is_redirect_only?
          @is_erhua_variant = meaning.is_erhua?
        elsif meaning.reference
          @references << meaning.reference
        else
          skip_this_meaning = false
        end
        
        # Only the ELSE block above (nothing special) will be added as a meaning
        if (!skip_this_meaning)
          refined_meanings << meaning
        end
      end
    end
    return refined_meanings
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
      meaning_str = m.meaning
      meaning_str = xfrm_remove_stop_words(meaning_str.gsub($regexes[:inlined_tags], "").strip)
      meanings_fts_arr << meaning_str unless meanings_fts_arr.include?(meaning_str)
    end

    return meanings_fts_arr.join(" ")
  end
  
  def meaning_html(tag_mode="inhuman")
    meanings_html_arr  = []
    sense_count = @meanings.size
    @meanings.each do |m|
      mtxt, mhtml = xfrm_inline_tags_with_meaning(@pos, m.meaning, tag_mode)
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
      mtxt, mhtml = xfrm_inline_tags_with_meaning(@pos, m.meaning, tag_mode)
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