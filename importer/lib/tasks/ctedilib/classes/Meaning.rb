class Meaning

  @variant
  @variant_erhua
  @reference
  @meaning
  @tags
  
  # If this is true, this meaning shouldn't be considered for the full text search
  @skip_fts

  def initialize(meaning = "",tags = [])
    @reference = false
    @variant = false
    @skip_fts = false
    @is_erhua = false
    @tags = tags
    @meaning = meaning
  end
  
  def parse(meaning = "")
    # Use the one from the initializer if there isn't any on the parse call
    meaning = @meaning if meaning = ""
    
    # First, strip out any references - this populates @reference
    meaning = strip_reference_from_meaning_str(meaning)
    meaning = strip_variants_from_meaning_str(meaning)
    
    # Get our tags (both full and partial match)
    tags_by_type = parse_tags_from_meaning_str(meaning)
    
    # Snag the fully matching tags, then put them all together
    fully_matching_tags = tags_by_type[:full_match]
    
    if (!fully_matching_tags.empty?)
      meaning = strip_tags_from_meaning_str(meaning,fully_matching_tags)
    end
    
    all_tags = tags_by_type[:full_match]
    partial_tags = tags_by_type[:partial_match]
    partial_tags.each do |tag|
      all_tags << tag if tag.empty? == false
    end
    
    all_tags = transform_tags(all_tags)
    all_tags.each do |tag|
      @tags << tag if tag.empty? == false
    end
    @meaning = meaning
    
    # TODO: should this take an argument?
    @tags << "abbr" if found_abbreviation?
  end

  # Helper function to prevent the above method from getting out-of-control large
  # TAG DETECTION
  
  def parse_tags_from_meaning_str(meaning = "")
  
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
  
  def strip_tags_from_meaning_str(meaning = "",tags = [])
    tags.each do |this_tag|
      search_string = " (%s)" % this_tag
      meaning.gsub!(search_string,"")
    end
    return meaning
  end
  
  # VARIANT DETECTION
    
  def strip_variants_from_meaning_str(meaning_str)

    has_meaning = true

    # Always try erhua first!
    variant_regex = /^erhua variant of (\w+(\||\s)*\w*)([\[\]a-zA-Z:0-9\s]*)[,\s]*(.+)*$/
    meaning_str.scan(variant_regex) do |variant|
      @is_erhua = true
      @variant = variant[0]                             # Headword
      @variant = @variant + variant[2] if variant[2]    # Reading if not nil
      has_meaning = (variant[3] != nil)                 # A meaning afterward?
    end

    # Now regular variants
    variant_regex = /^variant of (\w+(\||\s)*\w*)([\[\]a-zA-Z:0-9\s]*)[,\s]*(.+)*$/
    meaning_str.scan(variant_regex) do |variant|
      @variant = variant[0]                             # Headword
      @variant = @variant + variant[2] if variant[2]    # Reading if not nil
      has_meaning = (variant[3] != nil)                 # A meaning afterward?
    end

    if @variant
      if has_meaning
        # Parse out the meaning & leave it behind
        start_index = meaning_str.index(",") + 2
        return meaning_str[start_index..meaning.length]
      else
        return ""
      end
    else
      # Just parrot out what we got in
      return meaning_str
    end
  end
  
  def transform_tags(tags = [])
    new_tags = []
    tags.each do |tag|
      if @@tag_transformations.has_key?(tag)
        new_tags << @@tag_transformations[tag]
      else
        new_tags << tag
      end
    end
    return new_tags
  end

  # ABBR DETECTION
  
  def found_abbreviation?
    # Quick return if bad input
    return false if (@meaning == "")
    
    abbr_regex = /abbr\./
    @meaning.scan(abbr_regex) do |match|
      return true
    end
    return false
  end

  # CLASSIFIER DETECTION

  def classifier
    # Quick return if bad input
    return false if (@meaning == "")

    classifier_regex = /CL:(.+)/
    @meaning.scan(classifier_regex) do |cl|
      @skip_fts = true
      return cl[0]
    end
    return false
  end
  
  # REFERENCE DETECTION
  
  def strip_reference_from_meaning_str(meaning_str = "")
    false_positive_regex = /see you/
    meaning_str.scan(false_positive_regex) do |false_positive|
      # If we have a false positive just return
      return meaning_str
    end
    ref_regex = /\Asee (also |)([^a-zA-Z0-9\s]+)(\[[\sA-Za-z0-9]+\])*\z/
    stripped = false
    meaning_str.scan(ref_regex) do |reference|
      stripped = true
      @reference = ("%s%s" % [reference[1],reference[2]])
    end

    if stripped
      return ""
    else
      return meaning
    end
  end
  
  # HELPERS
  
  def ==(obj)
    return (obj.meaning == @meaning && obj.tags.eql?(@tags))
  end
  
  def reference
    @reference
  end

  def meaning
    @meaning
  end
  
  def variant
    @variant
  end
  
  def is_erhua?
    @is_erhua
  end
  
  def should_skip_fts?
    @skip_fts
  end
  
  def tags
    @tags
  end
  
  def is_redirect_only?
    return ((@variant_erhua or @variant or @reference) and (@meaning == ""))
  end
  
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


end