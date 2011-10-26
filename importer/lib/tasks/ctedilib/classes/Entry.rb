class Entry

  include ObjectSpace

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
      if meaning_hash[:tags].size > 0
        all_tags << meaning_hash[:tags]
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
  
  def has_variant
    return ((@variant_of == false) ? false : true)
  end
  
  def is_erhua_variant
    @is_erhua_variant
  end

  def is_only_redirect?
    return (meanings.empty? && (references.empty? == false))
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
  
  def parse_inline_entry(line = "")
    inline_entry = InlineEntry.new
    inline_entry.parse_line(line)
    if inline_entry.headword_trad != nil
      return inline_entry
    else
      return nil
    end
  end
  
  def to_insert_sql
    insert_entry_sql = "INSERT INTO cards_staging (headword_trad,headword_simp,headword_en,reading,reading_diacritic,meaning,meaning_html,meaning_fts,classifier,tags,referenced_cards,is_reference_only,is_variant,is_erhua_variant,is_proper_noun,variant,cedict_hash) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s',%s,'%s',%s,%s,%s,%s,%s,%s,'%s');"
    serialised_cedict_hash = mysql_serialise_ruby_object(self)
    all_tags_list = Parser.combine_and_uniq_arrays(all_tags).join($delimiters[:jflash_tag_coldata])

    return insert_entry_sql % [headword_trad, headword_simp, headword_en, pinyin, pinyin_diacritic,
        mysql_escape_str(meaning_txt), mysql_escape_str(meaning_html), mysql_escape_str(meaning_fts),
        (classifier ? "'"+mysql_escape_str(classifier)+"'" : "NULL"), all_tags_list,
        (references.empty? ? "NULL" : "'"+mysql_escape_str(references.join(";"))+"'"),
        (is_only_redirect? ? "1" : "0"),
        (has_variant ? "1" : "0"), (is_erhua_variant ? "1" : "0"),
        (is_proper_noun? ? "1" : "0"),
        (variant_of ? "'"+mysql_escape_str(variant_of)+"'" : "NULL"), serialised_cedict_hash]
  end
end