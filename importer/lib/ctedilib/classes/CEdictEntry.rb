#!/usr/bin/env ruby -w
# encoding: UTF-8
# Single entry class - based on active record?
class CEdictEntry < Entry

  #===================================
  # Parses a line from the CEDICT data source
  #===================================
  def parse_line (line = "")
    begin
      # Don't process comments or bad data
      return false if line.nil? or (line.index("#") == 0)
      
      # Save a copy of this -- we'll use it later when we need a unique ID value to match against
      @original_line = line
      
      # Get the headwords, traditional then simplified
      headword_arr = get_headwords(line)
      @headword_trad = headword_arr[0]
      @headword_simp = headword_arr[1]
      
      # Now get the reading
      @pinyin = get_pinyin(line)
      
      # The "true" keeps the spaces in the pinyin - we want that for our FTS database
      @pinyin_diacritic = Entry.get_pinyin_unicode_for_reading(@pinyin, true)
      @meanings = parse_meanings(line)
      
      # Finally make an English headword out of the first meaning
      if (@meanings.size > 0)
        @headword_en = extract_en_headword(@meanings.first.meaning.strip)
      end
      return true
    rescue
      raise EntryParseException, "Error parsing line: %s" % line
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
          @is_archaic_variant = meaning.is_archaic_variant?
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