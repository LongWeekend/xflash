class Entry

  include ObjectSpace
  include DatabaseHelpers
  include ImporterHelpers

  @@pos_tags = ["Adv","Conj","VS","VA","N","M","Nb","Prep"]

  #===================================
  # Initializes a new entry
  #===================================
  
  def init
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
    @variant_of = false
    
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
          reading = reading.slice(0, reading.length()-1).downcase()
          
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
  
  def is_erhua_variant?
    @is_erhua_variant
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
  
  def add_inline_entry_to_meanings(inline_entry)
    @meanings << Meaning.new("Also: %s" % [ inline_entry.to_str ], ["reference"])
  end
  
  def add_variant_entry_to_base_meanings(variant_entry)
    if variant_entry.is_erhua_variant?
      meaning_str = "Has Erhua variant: %s %s [%s]" % [variant_entry.headword_trad, variant_entry.headword_simp, variant_entry.pinyin]
    else
      meaning_str = "Has variant: %s %s [%s]" % [variant_entry.headword_trad, variant_entry.headword_simp, variant_entry.pinyin]
    end
    @meanings << Meaning.new(meaning_str,["reference"]) 
  end

  def add_base_entry_to_variant_meanings(base_entry)
    if is_erhua_variant?
      meaning_str = "Erhua variant of: %s %s [%s]" % [base_entry.headword_trad, base_entry.headword_simp, base_entry.pinyin]
    else
      meaning_str = "Variant of: %s %s [%s]" % [base_entry.headword_trad, base_entry.headword_simp, base_entry.pinyin]
    end
    @meanings << Meaning.new(meaning_str,["reference"]) 
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
    if inline_entry.headword_trad != nil
      return inline_entry
    else
      return nil
    end
  end
  
  def to_insert_sql
    insert_entry_sql = "INSERT INTO cards_staging (headword_trad,headword_simp,headword_en,reading,reading_diacritic,meaning,meaning_html,meaning_fts,classifier,tags,referenced_cards,is_reference_only,is_variant,is_erhua_variant,is_proper_noun,variant) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s',%s,'%s',%s,%s,%s,%s,%s,%s);"
#    serialised_cedict_hash = mysql_serialise_ruby_object(self)
    all_tags_list = Array.combine_and_uniq_arrays(all_tags).join($delimiters[:jflash_tag_coldata])

    return insert_entry_sql % [headword_trad, headword_simp, headword_en, pinyin, pinyin_diacritic,
        mysql_escape_str(meaning_txt), mysql_escape_str(meaning_html), mysql_escape_str(meaning_fts),
        (classifier ? "'"+mysql_escape_str(classifier)+"'" : "NULL"), all_tags_list,
        (references.empty? ? "NULL" : "'"+mysql_escape_str(references.join(";"))+"'"),
        (is_only_redirect? ? "1" : "0"),
        (has_variant? ? "1" : "0"), (is_erhua_variant? ? "1" : "0"),
        (is_proper_noun? ? "1" : "0"),
        (variant_of ? "'"+mysql_escape_str(variant_of)+"'" : "NULL")]
#        (variant_of ? "'"+mysql_escape_str(variant_of)+"'" : "NULL"), serialised_cedict_hash]
  end
  
  def to_update_sql
    raise "implement me"
  end
  
  def hydrate_from_hash(record = nil)
    init()
    
    # A little sanity checking on line
    if ((record.nil?) && (!record.kind_of? Hash))
     pp ("Record supplied on the Card Entry is either nil or is not a Hash type")
     return false
    end
    
    @id = record[:card_id] unless !record[:card_id]
    @headword_trad = record[:headword_trad] unless !record[:headword_trad]
    @headword_simp = record[:headword_simp] unless !record[:headword_simp]
    
    if record[:reading]
      reading = record[:reading]
      @pinyin_diacritic = Entry.get_pinyin_unicode_for_reading(reading)
      @pinyin = reading
    end
    
    # TODO: Serialize meaning objects as a hash and then restore?? MMA
    # Get the meanings (compbination with the meaning column and the meaning_fts)
    entire_meanings = Array.new()
    meanings = record[:meaning].split(";") unless !record[:meaning]
    meaning_fts = record[:meaning_fts].split(";") unless !record[:meaning_fts]
    # Remove the spaces and put them into a single array.
    entire_meanings.add_element_with_stripping_from_array!(meanings)
    entire_meanings.add_element_with_stripping_from_array!(meaning_fts)
    # Remove dupliacates
    @meanings = entire_meanings.uniq()
    
    # Get whether the card is a erhua variant
    erhua_variant = false
    erhua_variant = record[:is_erhua_variant] == 1 ? true : false unless !record[:is_erhua_variant]
    @is_erhua_variant = erhua_variant
    
    # Get whether the card is a variant.
    variant_of = false
    variant_of = record[:is_variant] == 1 ? true : false unless !record[:is_variant]
    @variant_of = variant_of
  end
  
  def ==(another_card_entry)
    # If the another_card_entry is not Entry type
    # just return with false.
    if (!another_card_entry.kind_of?(Entry))
      return false
    end
  
    return self.id == another_card_entry.id
  end  

  def similar_to?(entry, match_criteria = nil)
    # Make sure the entry is kind of Entry class-
    raise "You must pass an Entry subclass to this method!" unless entry.kind_of?(Entry)
    
    # Comparing the headword
    # NOTE: Please make sure that the entry is the one wanted to be matched from.
    # and self is the CARD.
    same_headword_trad = (headword_trad == entry.headword)
    same_headword_simp = (headword_simp == entry.headword)
    same_headword = same_headword_trad || same_headword_simp
    return false unless same_headword
    
    if match_criteria
      return match_criteria.call(self, entry, false)
    else
      return true
    end
  end
  
# EOF
end