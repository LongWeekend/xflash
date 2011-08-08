# Single entry class - based on active record?
class CEdictEntry < Entry

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
    @meanings = get_meanings(@line_to_parse)
    
    return true
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
  
    ref_regex = /see (also |)(.+)/
    stripped = false
    meaning.scan(ref_regex) do |reference|
      stripped = true
      @references << reference[1]
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

end