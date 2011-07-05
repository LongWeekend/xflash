############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#    --- Source Processor lib file ---
############################################

# We now require the require Levenshtein distance gem
require 'levenshtein'

#
# (Hash) self.analyse_edict_tags : Calls and aggregates tag analysis data
#
def self.analyse_edict_tags(line)
  if @all_tags.nil?
    @all_tags = {}
    @all_tags[:pos] = []
    @all_tags[:lang] = []
    @all_tags[:tag] = []
  end
  results = process_edict_tag_data(line)
  @all_tags[:pos] << results[:pos].uniq if !results[:pos].nil?
  @all_tags[:lang] << results[:lang].uniq if !results[:lang].nil?
  @all_tags[:tag] << results[:tag].uniq if !results[:tag].nil?
  return @all_tags
end

#
# (Hash) self.process_edict_tag_data : Returns validated tag data separate to line, also removes validated tags from line
#
def self.process_edict_tag_data(line ="")
  return if line == ""
  good_pos_tags = []
  good_lang_tags = []
  good_tag_tags = []
  antonyms = ""

  line.scan(@regexes[:tag_like]) do |tag_txt|
    tag_txt = tag_txt.to_s
    original_tag = '(' + tag_txt + ')'
    tag_txt.split(',').each do |tag|
      tag = tag.to_s.strip
      tag = transform_tag?(tag)
      lang_tag = transform_tag?(tag.scan(@regexes[:lang_tag]).to_s)
      if tag.scan(@regexes[:lang_tag]).size > 0
        origin_word = tag.scan(@regexes[:lang_tag_origin_word]).to_s.strip
        if origin_word.length > 0
          inline_lang_tag = "cf. " + origin_word 
        end
      else
        inline_lang_tag = ""
      end
      antonym_tag_contents = transform_tag?(tag.scan(@regexes[:antonym]).to_s)

      if antonym_tag_contents != ""
        antonyms = antonym_tag_contents
      elsif lang_tag != "" and @good_tags[:lang].include?(lang_tag) and !@good_tags_not_inlined.include?(lang_tag)
        good_lang_tags << lang_tag
        line = line.gsub("(#{tag})", "#{inline_lang_tag}")
        # line = line.gsub("(#{tag})", "#{inline_lang_tag} (#{lang_tag})") ### Reinsert clean lang tag (not needed now!)
      elsif @good_tags[:pos].include?(tag) and !@good_tags_not_inlined.include?(tag)
        good_pos_tags << tag
        line = line.gsub(original_tag, "").gsub("  ", " ")
      elsif @good_tags[:tag].include?(tag) and !@good_tags_not_inlined.include?(original_tag)
        good_tag_tags << tag
        line = line.gsub(original_tag, "").gsub("  ", " ")
      else
        if @tag_ignore_list.include?(tag) or tag.to_i > 0 or tag.index("See ") == 0
          # Skip ignore list tags, numeric tags or "See" references
        elsif tag.scan(@regexes[:bad_lang]).to_s != "" and !@tag_ignore_list.include?(lang_tag)
          # Store possible new tags
          if @possible_lang_tags.has_key?(lang_tag)
            @possible_lang_tags[lang_tag] = @possible_lang_tags[lang_tag] + 1
          else
            @possible_lang_tags[lang_tag] = 1
          end
        elsif @bad_tags.has_key?(tag)
          @bad_tags[tag] = @bad_tags[tag]+1
        else
          @bad_tags[tag] = 1
        end

      end
    end
  end

  line.gsub!(/\s{1},/, ',') ### Replace 'space-comma' with 'comma' only
  line.gsub!("  ", " ") ### Remove runs double of spaces
  line.gsub!("//", "/") ### Remove double slashes

  processed_line_hash = { :description => line, :pos => good_pos_tags.uniq, :lang => good_lang_tags.uniq, :tag => good_tag_tags.uniq, :antonyms => antonyms }
  return processed_line_hash
end

#
# (Hash) self.process_edict_entry : Processes each EDICT2 line
#
def self.process_edict_entry(line)
  #Get all headwords
  return if line.index("/").nil? # Rough check to see if it conforms to EDICT format
  headwords = line[0..line.index(" ")-1]
  headwords = headwords.strip
  headwords.gsub!(@regexes[:tag_like],"") # remove tag like occurrences in headwords

  #Get primary headword
  arr_headwords = headwords.split(';')
  headword = arr_headwords[0]

  #Get secondary headwords
  if arr_headwords.length > 1 
    arr_headwords.delete_at(0)
    other_headwords = arr_headwords.join(';')
  else
    other_headwords = ""
  end

  # Store headword
  ### NOISY DEBUG puts "Duplicate key for #{headword}" if @edict2_data.has_key?(headword)
  if !@edict2_data.has_key?(headword)
    @edict2_data[headword] = { :other_headwords => other_headwords, :usages => [], :original => line }
  else
    ohw = @edict2_data[headword][:other_headwords]
    @edict2_data[headword][:other_headwords] = (ohw != "" ? ohw + ";" + other_headwords : other_headwords)
    @edict2_data[headword][:original] = @edict2_data[headword][:original] + "\n" + line
  end

  #Get readings & usages
  readings = line.scan(@regexes[:inside_hard_brackets]).to_s
  readings = headword if readings.length < 1 || !readings.index("（").nil? # Catch dodgey source file readings
  readings.gsub!(@regexes[:tag_like],"") # Kill anything in brackets inside the reading block, TEdi3 will handle these!
  usages = line.scan(@regexes[:usages]).to_s

  #recompile usages, splitting into one per line
  if usages[@regexes[:block_marker]].nil?
    # remove good tags, clean up
    recompiled_usages = usages
  else
    recompiled_usages = ""
    first_loop = true
    usages.split("/").each do |u|
      if u != ""
        start_of_usage = u[@regexes[:block_marker]].nil?
        if first_loop and start_of_usage
          recompiled_usages = u
        elsif start_of_usage
          recompiled_usages = recompiled_usages + " / " + u
        else
          recompiled_usages = recompiled_usages + "\n" + u
        end
        first_loop = false
      end
    end
  end

  recompiled_usages.each_line do |usage|
    if usage != "\n"

      # Clean line breaks etc
      usage.strip!

      # move to end of string
      reading_specifier_annotation = usage.scan(@regexes[:reading_specifier_annotation])
      if reading_specifier_annotation.size > 0
        usage = usage.gsub(@regexes[:reading_specifier_annotation],"").strip +  " " + reading_specifier_annotation[0][0].to_s.strip
      end

      # Create a manual loop to check for annotations. Make sure it checks for balanced braces!!!
      new_usage = ""
      ins = false
      nested_found = false
      nesting_level=0
      usage.each_char { |s| 
        # Remove not nested braces
        if nesting_level == 0 || (nesting_level == 1 && s == ")") || (nesting_level > 0 && s != "(" && s != ")")
          #puts "level #{nesting_level}: "+s + "  +"
          new_usage = new_usage + s
          #else
          #puts "level #{nesting_level}: "+s + "  -"
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
          puts "ERROR: Braces over-closed!!!"
          debugger
        end
      }
      if nesting_level != 0
        puts "ERROR: Reached end of line without finding closing brace!!!"
        debugger
      end
      if new_usage != usage
        nested_found = true
        #puts ""
        #puts "Old Usage: "+ usage
        #puts "New Usage: "+ new_usage
        usage = new_usage
      end
      # move parenthesized bits to end of string 
      alternative_annotations = usage.scan(@regexes[:alternative_annotations])
      if alternative_annotations.size > 0
        usage = usage.gsub(@regexes[:alternative_annotations],"").strip +  " " + alternative_annotations[0][0].to_s.strip
      end

      # find references and remove from line
      references = usage[@regexes[:reference]]
      usage.gsub(@regexes[:reference],"").gsub("   ", " ").gsub("  ", " ")
      results = process_edict_tag_data(usage)
      antonyms = (results[:antonyms].to_s != "" ? results[:antonyms].to_s : "")
      if !references.nil?
        references = references.gsub("(See ","").gsub(")","")
      else
        references = ""
      end

      # Use the first occuring tags in the line, if none found for current line
      #puts "blank >>> " + usage if (results[:pos].to_s =="" and results[:lang].to_s =="" and results[:tag].to_s == "")
=begin        
      if (results[:pos].to_s =="" and results[:lang].to_s =="" and results[:tag].to_s == "") and @edict2_data[headword][:usages].length > 0
        prev = @edict2_data[headword][:usages][@edict2_data[headword][:usages].length-1]
        pos = prev[:pos_tags]
        lang = prev[:lang_tags]
        tag = prev[:tag_tags]
      else
        pos = results[:pos]
        lang = results[:lang]
        tag = results[:tag]
      end
=end
      # Do not repeat tags (this is only good for Npedia not jFlash 1.0)
      pos = results[:pos]
      lang = results[:lang]
      tag = results[:tag]
      
      description = results[:description].gsub(@regexes[:reference],"").gsub(@regexes[:block_marker], "").gsub("  ", " ").strip
      description = description.gsub(@regexes[:leading_trailing_slashes], "").gsub(@regexes[:leading_spaces], "").gsub(@regexes[:trailing_spaces], "").gsub(@regexes[:slash_at_end_of_line], "")

      # Add to hash if not a precise usage/headword duplicate
      duplicate_usage = false
      if @options[:merge_similar] && @edict2_data[headword][:usages]
        @edict2_data[headword][:usages].each do |u|
          if u[:description].strip.downcase.scan(/\b#{description.strip.downcase}\b/).size >0
            ldistance = Levenshtein.distance(u[:description].strip.downcase, description.strip.downcase)
            ld2 = (ldistance.to_f / (u[:description].strip).size.to_f) *100
            if ld2 < 33.333
              puts "Duplicate avoided: '"+u[:description].to_s + "'  >>> >>>  " + description
              puts ldistance.to_s + "  " + ld2.to_s
              puts "^^^^^^^^^^^^^^^^^"
              u[:tag_tags] = ([] << u[:tag_tags] << tag).flatten.uniq
              u[:pos_tags] = ([] << u[:pos_tags] << lang).flatten.uniq
              u[:lang_tags] = ([] << u[:lang_tags] << pos).flatten.uniq
              duplicate_usage = true
            end
          end
        end
      end
      if !duplicate_usage
        @edict2_data[headword][:usages] << { :readings => readings, :description => description, :references => references, :antonyms => antonyms, :pos_tags => pos, :lang_tags => lang, :tag_tags => tag } if usage.length > 0 and description !=""
        @edict2_count = @edict2_count+1
      end

    end
  end
  return true
end

#
# (Hash) self.process_tanc_entry : Processes each TANC line
#
def self.process_tanc_entry(line_hash)
  return if !line_hash[:a].match(/^#/).nil? and !line_hash[:b].match(/^#/).nil? #Skip commented out line pairs
  if line_hash[:b] != ""
    line_a = line_hash[:a].gsub("A: ", "").gsub(@regexes[:tanc_id_block], "").strip
    line_b = line_hash[:b].gsub("B: ", "").strip
    japanese, translated = line_a.split("\t") #split on tab
    japanese = japanese.gsub(@regexes[:tanc_tag_non_numeric],"").strip
    translated = translated.gsub(@regexes[:tanc_id_block], "")
    tag = line_a.scan(@regexes[:tanc_tag_non_numeric]).to_s
    references = line_b.scan(@regexes[:tanc_b_line_reference_block])
    references_array = []
    if references.length > 0
      references.each do |r|
        scrap_topic = r.gsub(@regexes[:tag_like], "").gsub(@regexes[:inside_hard_brackets], "") #remove any readings in parentheses
        references_array << { scrap_topic => r.scan(@regexes[:inside_hard_brackets])[0].to_s } # put the usage no into hash
      end
    end
    pp tag if tag.length > 1

    ## Set globals and exit
    @tanc_data << { :japanese => japanese, :translated => translated, :line_b => line_b, :tag => tag, :references => references_array }
  end
  return true
end

#
# (Hash) self.analyse_tanc_tags : Calls and aggregates TANC tag analysis data
#
def self.analyse_tanc_tags(line_hash)
  # PC 2009-05-21 ... This looks like it's broken!!!
  line = line_hash[a]
  return line
end

#
# (Hash) self.process_edict : Calls process lines, alias
#
def self.process_edict(mode="extract", from=1, to=0, &block)
  if block_given?
    return process_lines("edict2", mode, from, to, yield)
  else
    return process_lines("edict2", mode, from, to)
  end
end

#
# (Hash) self.process_tanc : Calls process lines, alias
#
def self.process_tanc(mode="extract", from=0, to=0, &block)
  if block_given?
    return process_lines("tanc", mode, from, to, yield)
  else
    return process_lines("tanc", mode, from, to)
  end
end

#
# (Hash) self.process_lines : Main processing block for file data extraction
#
def self.process_lines(import_type, mode, from, to, &block)
  line_count = 0
  counted = 0
  current_line_pair = {}  
  
  #Track execution time
  tickcount("Read " + (import_type == "tanc" ? "Tanaka Corpus": "Edict2") + " Source File") do
    default_src = (import_type == "tanc" ? @options[:default_tanc_source] : @options[:default_edict_source])
    source_data = File.new((ENV.include?("src") && FileTest.exists?(ENV['src']) ? ENV['src'] : default_src), "r")
    while line = source_data.gets do

      if line_count == 0 
        if import_type == "edict2"
          # Support headerless EDICT2 files
          line_count=line_count+1 if !(/Japanese-English Electronic Dictionary Files/ =~ line).nil?
        elsif import_type != "edict2"
          line_count=line_count+1
        end
      end

      line = Kconv.toutf8(line).strip if @options[:force_utf8]  ### Force to utf8 (might be slow??)
      line = line.gsub(/\{/,"(").gsub(/\}/, ")")  ### Replace {} with ()
      
      if line_count >= from
        #------------------------------------------------
        if import_type == "tanc"
          if line.scan(/A\: /).size > 0
            current_line_pair[:a] = line
            current_line_pair[:b] = ""
          elsif line.scan(/B\: /).size > 0
            current_line_pair[:b] = line
            if mode == "extract"
              process_tanc_entry(current_line_pair)
            elsif mode =="analyse"
              analyse_tanc_tags(current_line_pair)
            else #mode =="scan"
              yield(current_line_pair[:a]) if block_given?
            end
          end
        #------------------------------------------------
        elsif import_type =="edict2"
          if mode == "extract"
            process_edict_entry(line)
          elsif mode =="analyse"
            analyse_edict_tags(line)
          else #mode =="scan"
            yield(line) if block_given?
          end
        end
        #------------------------------------------------
        puts ">>>  #{line_count}  lines read at #{Time.now})" if line_count % 500 == 0 unless @options[:silent]
      end
      line_count=line_count+1
      break if line_count > to and to > 0

    end
  end

  if import_type == "edict2"
    return { :data => @edict2_data, :tags => @all_tags, :count => @edict2_count}
  elsif import_type == "tanc"
    return { :data => @tanc_data, :tags => @all_tanc_tags, :count => @tanc_count}
  end

end