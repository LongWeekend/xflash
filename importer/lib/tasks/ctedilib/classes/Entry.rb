class Entry

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
    @pinyin = ""
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
  
  def id
    @id
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

  def is_only_redirect
    return ((meanings.empty? == true) && (references.empty? == false))
  end
  
  def references
    @references
  end

end