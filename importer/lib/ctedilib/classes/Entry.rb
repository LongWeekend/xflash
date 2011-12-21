class Entry

  include ObjectSpace
  include DatabaseHelpers
  include ImporterHelpers

  @@pos_tags = ["Adv","Conj","VS","VA","N","M","Nb","Prep"]

  #===================================
  # Initializes a new entry
  #===================================
  
  def initialize
    @original_line = ""
    @id = -1
    @pos = []
    @grade = ""
    @classifier = false
    @headword_trad = ""
    @headword_simp = ""
    @headword_en = ""
    @pinyin = ""
    @pinyin_diacritic = ""
    @meanings = []
    @is_erhua_variant = false
    @is_archaic_variant = false
    @variant_of = false
    @priority_word = false
    
    # There can be more than one of these
    @references = []
  end

  #===================================
  # Helpers
  #===================================
  
  def self.is_pos_tag?(tag = "")
    return (@@pos_tags.index(tag) ? true : false)
  end

  #===================================
  # Setters
  #===================================
  
  def id=(new_id = -1)
    set_id(new_id)
  end
  
  def set_id(new_id = -1)
    @id = new_id
  end

  
  #===================================
  # Getters
  #===================================
  
  # Puts all the tags together on the fly
  def all_tags
    all_tags = []
    meanings.each do |meaning_hash|
      if meaning_hash.tags.size > 0
        all_tags << meaning_hash.tags
      end
    end
    return all_tags.flatten
  end
  
  def to_s
  	# Get the name of the class in string.
    class_name_str = self.class().to_s()
    
    # Concatenate the entire class instance variables and
    # its values.
    ivars = "["
    self.instance_variables.each do |var|
    	val = self.instance_variable_get(var)
    	if val.kind_of? @meanings.class
    		val = val.join("//")
    	end
		ivars << var + ": " + val.to_s() + "\n"
    end
    ivars[ivars.length-1] = "]"
    
    # Constructs the string and return it back
    result = "<%s: 0x%08x>\n%s\n\n"
  	return result % [class_name_str, self.object_id, ivars]
  end
  
  def id
    @id
  end
  
  def original_line
    @original_line
  end
  
  def checksum
    Digest::MD5.hexdigest(@original_line)
  end
  
  def headword
    (@headword_trad != nil) && (@headword_trad.strip.length > 0) ? @headword_trad : @headword_simp
  end
  
  def headword_en
    @headword_en
  end
  
  def headword_trad
    @headword_trad
  end
  
  def headword_simp
    @headword_simp
  end
  
  def pinyin
    @pinyin
  end
  
  def pinyin_diacritic
    @pinyin_diacritic
  end

  def self.get_pinyin_unicode_for_reading(readings="", leave_spaces = false)
    ## TODO: Think about the tone-5
    ## http://en.wikipedia.org/wiki/Pinyin#Tones  
    # Only runs if the reading actually has something
    if ((readings) && (readings.strip().length() > 0))
      # Variable to persist the final result.
      result = ""
      
      # sometimes some sources use "u:" <u with collon>
      # but some other uses "v" character as 
      # it is not used in the pinyin
      umlaut_regex = /[uU]:|v/
      readings.gsub!(umlaut_regex) do |s|
        [252].pack('U*')
      end
      
      # Loop through the individual readings.
      readings.split($delimiters[:cflash_readings]).each do | reading |
        
        # Just to get the tone in string (even if it should be a number)
        tone = ""
        tone << reading.slice(reading.length()-1)
        if reading == "r5"
          # Exception for the 'r' sound and the tone will always be '5'
          # Just concatinate with the result
          result << "r"
        elsif reading == "xx5"
          #ignore these BS ones
        elsif reading == "m2" or reading == "m4"
          result << reading
        elsif (tone.match($regexes[:pinyin_tone]))
          found_diacritic = false
          # Get the reading without the number (tone)
          reading = reading.slice(0, reading.length()-1)
          
          vocals = reading.scan($regexes[:vocal])
          num_of_vocal = vocals.length
           
          vocal = ""
          if (num_of_vocal == 1)
            # Take the vocal, directly if there is only 1 vocal.
            vocal = vocals[0]
          else
            vocal = reading.scan($regexes[:diacritic_vowel1])[0]
            
            vocal = reading.scan($regexes[:diacritic_vowel2])[0] unless vocal
            if (vocal)
              # Get the "o" in the 'ou' scan.
              vocal = vocal[0].chr()
            end
            
            # If everything else fails, get the second vocal.
            vocal = vocals[1] unless vocal
          end
          
          if ((vocal) && (vocal.strip().length() > 0))
            diacritic = Entry.get_unicode_for_diacritic(vocal, tone)
            result << reading.sub(vocal, diacritic)
          else
            # This should be a very rare cases.
            raise ToneParseException, "The vocal to be sub with its diacritic is not found for readings: %s, vocals: %s, reading: %s and tone: %s" % [readings, vocals, reading, tone]
          end
        elsif (reading.match($regexes[:single_letter]))
          # If there is a single letter reading, 
          # it is usually either an acronym or a single letter. (like ka-la-o-k) - Karaoke
          # Put them just as is
          result << reading
        elsif (reading.match($regexes[:pinyin_separator]))
          result << " %s " % [reading]
        else
          # This should be a very rare cases.
          raise ToneParseException, "There is no tone: %s defined for pinyin reading: %s in readings: %s" % [tone, reading, readings]
        end
        
        # Add a space if we were asked to
        result << " " if leave_spaces
      end
      return result.strip
    end

    # Back with nothing if there is no reading supplied
    return ""
  end
  
  def self.get_unicode_for_diacritic(vocal, tone)
    if vocal == "ü"
      vocal = "v"
    end
    the_vocal_sym = (vocal + tone).to_sym()
    return [$chinese_reading_unicode[the_vocal_sym]].pack('U*')
  end
  
  def self.fix_unicode_for_tone_3(pinyin)
    # GSUB accepts hashes on Ruby 1.9 but not 1.8.  We have it categorized in in additions as hash_gsub
    return pinyin.hash_gsub(/[ăĕĭŏŭ]/,{'ă'=>'ǎ','ĕ'=>'ě','ĭ'=>'ǐ','ŏ'=>'ǒ','ŭ'=>'ǔ'})
  end
  
  def pos
    @pos
  end
  
  def meanings
    @meanings
  end
  
  def grade
    @grade
  end
  
  def classifier
    @classifier
  end
  
  def variant_of
    @variant_of
  end
  
  def has_variant?
    return ((@variant_of == false) ? false : true)
  end
  
  def is_priority_word?
    @priority_word
  end
  
  def priority_word=(new_val)
    @priority_word = new_val
  end
  
  def is_erhua_variant?
    @is_erhua_variant
  end
  
  def is_archaic_variant?
    @is_archaic_variant
  end

  # Returns TRUE if the meanings are empty and this contains references or variants
  def is_only_redirect?
    return (meanings.empty? && ((references.empty? == false) || has_variant?))
  end
  
  def is_proper_noun?
    # Pinyin begins with a capital letter
    pn_regex = /\A[A-Z]+[a-z0-9\s]+/
    @pinyin.scan(pn_regex) do |match|
      return true
    end
    return false
  end
  
  def references
    @references
  end
  
  def add_classifier_to_meanings
    # Quick return if nothing set
    return false unless classifier
    
    # I have NO idea why, but when I call entry.classifier.split, shit goes haywire
    classifier.split(",").each do |classifier_str|
      @meanings << Meaning.new(("Counter: %s" % [classifier_str]),["classifier"])
    end
  end
  
  def add_ref_entry_into_meanings(ref_entry, modifier = "Also")
    meaning_str = Entry.construct_meaning_str(ref_entry, modifier)
    @meanings << Meaning.new(meaning_str,["reference"]) 
  end
  
  def rem_ref_entry_from_meanings(ref_entry, modifier = "Also")
    meaning_str = Entry.construct_meaning_str(ref_entry, modifier)
    removed_meaning = Meaning.new(meaning_str,["reference"]) 
    
    idx = @meanings.index removed_meaning
    @meanings.delete_at idx if idx != nil
    prt "This reference entry :\n %s \ncouldn't be found inside the following entries :\n %s " % [removed_meaning.to_s, self.to_s] if idx == nil
  end
  
  def self.construct_meaning_str(ref_entry, modifier = "Also")
    meaning_str = "%s: %s|%s [%s]" % [modifier, ref_entry.headword_trad, ref_entry.headword_simp, ref_entry.pinyin]
    return meaning_str
  end
  
  def add_variant_entry_to_base_meanings(variant_entry)
    modifier = self._get_modifier_for_variant(variant_entry)
    add_ref_entry_into_meanings(variant_entry,modifier)
  end

  def add_base_entry_to_variant_meanings(base_entry)
    modifier = self._get_modifier_for_base(base_entry)
    add_ref_entry_into_meanings(base_entry,modifier)
  end
  
  def rem_variant_entry_from_base_meanings(variant_entry)
    modifier = self._get_modifier_for_variant(variant_entry)
    rem_ref_entry_from_meanings(variant_entry,modifier)
  end

  def rem_base_entry_from_variant_meanings(base_entry)
    modifier = self._get_modifier_for_base(base_entry)
    rem_ref_entry_from_meanings(base_entry,modifier)
  end
  
  def _get_modifier_for_base(base_entry)
    modifier = "Variant of"
    if is_erhua_variant?
      modifier = "Erhua variant of"
    elsif is_archaic_variant?
      modifier = "Archaic variant of"
    end
    return modifier
  end
  
  def _get_modifier_for_variant(variant_entry)
    modifier = "Has variant"
    if variant_entry.is_erhua_variant?
      modifier = "Has Erhua variant"
    elsif variant_entry.is_archaic_variant?
      modifier = "Has archaic variant"
   end
   return modifier
  end
    
  def inline_entry_match?(inline_entry)
    # Quick return in case of non-headword match
    return false if @headword_trad != inline_entry.headword_trad

    if inline_entry.pinyin != nil
      return false if @pinyin != inline_entry.pinyin
    end
    
    # We haven't returned false, and the headword is the same, so match it
    return true
  end
  
  def self.parse_inline_entry(line = "")
    inline_entry = InlineEntry.new
    inline_entry.parse_line(line)
    if inline_entry.headword_trad.empty? == false
      return inline_entry
    else
      return nil
    end
  end
  
  # This method is used to create a human-readable version of the card (for exception handling)
  def description
    reading = @pinyin.empty? ? @pinyin_diacritic : @pinyin
    desc_str = "%s %s [%s], %s" % [@headword_trad, @headword_simp, reading, meaning_txt]
  end
  
  def to_insert_sql
    insert_entry_sql = "INSERT INTO cards_staging (headword_trad,headword_simp,headword_en,reading,reading_diacritic,meaning,meaning_html,meaning_fts,classifier,entry_tags,referenced_cards,is_reference_only,is_variant,is_erhua_variant,is_proper_noun,variant,priority_word,cedict_hash) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s',%s,'%s',%s,%s,%s,%s,%s,%s,%s,'%s');"
    all_tags_list = Array.combine_and_uniq_arrays(all_tags).join($delimiters[:jflash_tag_coldata])
    
    return insert_entry_sql % [headword_trad, headword_simp, headword_en, pinyin, pinyin_diacritic,
        mysql_escape_str(meaning_txt), mysql_escape_str(meaning_html), mysql_escape_str(meaning_fts),
        (classifier ? "'"+mysql_escape_str(classifier)+"'" : "NULL"), all_tags_list,
        (references.empty? ? "NULL" : "'"+mysql_escape_str(references.join(";"))+"'"),
        (is_only_redirect? ? "1" : "0"),
        (has_variant? ? "1" : "0"), (is_erhua_variant? ? "1" : "0"),
        (is_proper_noun? ? "1" : "0"),
        (variant_of ? "'"+mysql_escape_str(variant_of)+"'" : "NULL"),
        (is_priority_word? ? "1" : "0"),
        mysql_serialise_ruby_object(self)]
  end
  
  def to_update_sql
    return false if (id == -1)
    
    update_entry_sql = "UPDATE cards_staging SET headword_trad = '%s',headword_simp = '%s',headword_en = '%s',reading = '%s',reading_diacritic = '%s',meaning = '%s',meaning_html = '%s',meaning_fts = '%s',classifier = %s,entry_tags = '%s',referenced_cards = %s,is_reference_only = %s,is_variant = %s,is_erhua_variant = %s,is_proper_noun = %s,variant = %s,priority_word = %s, cedict_hash = '%s' WHERE card_id = %s;"
    all_tags_list = Array.combine_and_uniq_arrays(all_tags).join($delimiters[:jflash_tag_coldata])

    return update_entry_sql % [headword_trad, headword_simp, headword_en, pinyin, pinyin_diacritic,
        mysql_escape_str(meaning_txt), mysql_escape_str(meaning_html), mysql_escape_str(meaning_fts),
        (classifier ? "'"+mysql_escape_str(classifier)+"'" : "NULL"), all_tags_list,
        (references.empty? ? "NULL" : "'"+mysql_escape_str(references.join(";"))+"'"),
        (is_only_redirect? ? "1" : "0"),
        (has_variant? ? "1" : "0"), (is_erhua_variant? ? "1" : "0"),
        (is_proper_noun? ? "1" : "0"),
        (variant_of ? "'"+mysql_escape_str(variant_of)+"'" : "NULL"),
        (is_priority_word? ? "1" : "0"),
        mysql_serialise_ruby_object(self),
        id.to_s]
    
  end
  
  def self.from_sql(record = nil)
    if record[:cedict_hash]
      return mysql_deserialise_ruby_object(record[:cedict_hash])
    end
  end
  
  # Won't work if one of the card IDs aren't set
  # But it will work if both IDs are not set
  def ==(another_card_entry)
    # If the another_card_entry is not Entry type
    # just return with false.
    if (!another_card_entry.kind_of?(Entry))
      return false
    end
    
    # Incase both of the entries has not gotten the ID yet
    # and the match depends on the headword.
    if ((self.id == -1) and (another_card_entry.id == -1))
      return (self.headword_simp == another_card_entry.headword_simp or self.headword_trad == another_card_entry.headword_trad)
    end
  
    return (self.id == another_card_entry.id and self.id != -1)
  end  

  # USED FOR MATCHING BY TAG IMPORTER
  
  # You can, and should, override these in the subclasses
  def default_match_criteria
    match_criteria = Proc.new do |dict_entry, tag_entry|
      same_headword = (dict_entry.headword_trad == tag_entry.headword_trad) || (dict_entry.headword_simp == tag_entry.headword_simp)
      if same_headword
        # Now process the pinyin and see if we match
        tag_pinyin = tag_entry.pinyin.gsub(" ","")
        dict_pinyin = dict_entry.pinyin.gsub(" ","")
        if dict_entry.meaning_txt.downcase.index("surname")
          same_pinyin = (dict_pinyin == tag_pinyin)
        else
          same_pinyin = (dict_pinyin.downcase == tag_pinyin.downcase)
        end
          
        # If we didn't match right away, also check for the funny tone changes 
        if (same_pinyin == false and (tag_pinyin.index("yi2") or tag_pinyin.index("bu2")))
          same_pinyin = (dict_pinyin.downcase == tag_pinyin.downcase.gsub("yi2","yi1").gsub("bu2","bu4"))
        end
        
        # The return keyword will F everything up!
        (same_headword and same_pinyin)
      else
        false
      end
    end
    return match_criteria
  end
  
  # You can, and should, override these in the subclasses
  def loose_match_criteria
    match_criteria = Proc.new do |dict_entry, tag_entry|
      same_headword = (dict_entry.headword_trad == tag_entry.headword_trad) || (dict_entry.headword_simp == tag_entry.headword_simp)
    end
    return match_criteria
  end

  def similar_to?(entry, match_criteria = nil)
    # Make sure the entry is kind of Entry class-
    raise "You must pass an Entry subclass to this method!" unless entry.kind_of?(Entry)
    if match_criteria
      return match_criteria.call(self, entry)
    else
      return true
    end
  end
  # FORMAT MEANING STRINGS FOR HUMAN CONSUMPTION
  
  def meaning_fts(tag_mode="inhuman")
    meanings_fts_arr   = []
    sense_count = @meanings.size
    @meanings.each do |m|
      if !m.should_skip_fts?
        meaning_str = m.meaning
        meaning_str = xfrm_remove_stop_words(meaning_str.strip)
        meanings_fts_arr << meaning_str unless meanings_fts_arr.include?(meaning_str)
      end
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

    # XFORMATION: Remove common English stop words from string
  def xfrm_remove_stop_words(str)
    stop_words = ['Variant','variant', 'Erhua', 'Counter', 'Has', 'I', 'me', 'a', 'an', 'am', 'are', 'as', 'at', 'be', 'by','how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'than', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will', 'with', 'the']
    results = []
    str.gsub!($regexes[:inlined_tags], "") ## remove tag blocks
    str.split(' ').each do |sstr|
      # remove non word characters from string
      results << sstr unless stop_words.index(sstr.gsub(/[^a-zA-Z|\s]/, '').strip)
    end
    return results.flatten.compact.join(' ')
  end
  
# EOF
end