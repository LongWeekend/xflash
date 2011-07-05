#### TANAKA CORPUS PARSER #####
class TancParser < Parser

  #MMA - Added common endings to list - auxilary verbs etc
  @@keyword_stop_list_arr = ["は","か","が","に","乃","と","だ","へ","です", "を", "私", "よ", "で", "も","には","にも","から","しか","でも","より","し","ので","たい","ね","な","や","さ","わ",
                             "でしょう","でした","である","為る","為れる","有る","在る","しまう",
                             "此の","其の","あの","どの","此処","其処","彼処","此れ","其れ","何処","何れ"]

  # Overrides base class init
  def initialize(file_name, from=0, to=0, category_tags_list=[])
    @card_lookup = {}
    super(file_name, from, to, category_tags_list)
    set_line_count_atomicity(2) ## TWO LINES per record in Tanaka Corpus
  end

  def run
    sentence_data_array = []
    loop_count = 0
    line_a = ""
    line_b = ""

    tickcount("Parsing Tanaka Corpus example sentences") do

      # Get keyword indexed hash of cards to import
      #################################################
      import_all = false
      index_alt_headwords = false
      ##sql_where = "ptag=1 AND card_type=#{$options[:card_types]['DICTIONARY']}"
      sql_where = "card_type=#{$options[:card_types]['DICTIONARY']}"

      if !import_all
        @card_lookup = Importer.cache_sql_query( { :select => "card_id, headword, alt_headword, reading, ptag", :from => "cards_staging", :where => sql_where } ) do | sqlrow, cache_data |
          cache_data = {} if !cache_data

          cache_data[sqlrow['headword']] = [] if !cache_data[sqlrow['headword']]
          cache_data[sqlrow['headword']] << sqlrow['card_id']

          if index_alt_headwords
            sqlrow['alt_headword'].split($delimiters[:jflash_headwords]).each do |h|
              cache_data[h] = [] if !cache_data[h]
              cache_data[h] << sqlrow['card_id']
            end
          end

        end
      end

      # Call 'super' method to process loop for us
      #################################################
      super do |line, line_no, cache_data|

        # Loop Control
        loop_count = loop_count+1
        if (loop_count % 2) == 1
          line_a = line
        else
          line_b = line
          next if self.class.entry_commented_out?(line_a, line_b)
          tanc_en_id, tanc_ja_id = self.class.get_tanc_identifiers(line_a)
          sentence_quality_checked = self.class.quality_check_marker_found?(line_b)

          line_a = line_a.gsub("A: ", "").gsub($regexes[:tanc_id_block], "").strip
          line_b = line_b.gsub("B: ", "").strip

          tag = self.class.get_gender_tag(line_a)
          ##line_a = self.class.clean_gender_tag(line_a)

          japanese, translated = line_a.split($delimiters[:tanc_translated_pair])
          japanese = japanese.gsub($regexes[:tanc_tag_non_numeric],"").strip ## clean up jpn string
          translated = translated.split($delimiters[:tanc_tagret_language_pair])[0].to_s.strip  ## target language string
          references_array = line_b.split($delimiters[:tanc_refs_array])
          
          # Process B line references and make array of hashes containing card data
          processed_references_array = []
          card_lookup_matched = false
          if references_array.length > 0
            references_array.each do |ref|
              data = self.class.process_reference(ref)
              card_lookup_matched = true if @card_lookup.has_key?(ref)
              # Add to array if not empty
              processed_references_array << data if !data.empty?
            end
          end

          ##if sentence_quality_checked
          if import_all or card_lookup_matched
            sentence_data_array << { :tanc_en_id => tanc_en_id, :tanc_ja_id => tanc_ja_id, :japanese => japanese, :translated => translated, :tag => tag, :references => processed_references_array, :checked => sentence_quality_checked }
          end
        end

      end
    end
    
    return sentence_data_array
  end
  
  # DESC: Returns M or F tag at end of line
  def self.get_gender_tag(line_a)
    return line_a.scan($regexes[:tanc_tag_non_numeric]).to_s
  end

  # DESC: removes the gender tag from the line
  def self.clean_gender_tag(line_a)
    return line_a.gsub($regexes[:tanc_tag_non_numeric], "")
  end

  # DESC: Determines if the ~ quality checked marker is found on the string?
  def self.quality_check_marker_found?(str)
    return (str.scan(/~/).size > 0 ? true : false)
  end
  
  # DESC: Determines if current line is commented out?
  def self.entry_commented_out?(line_a, line_b)
    return (!line_a.match(/^#/).nil? and !line_b.match(/^#/).nil?) #Skip commented out line pairs
  end

  # DESC: Returns tatoeba project IDs
  def self.get_tanc_identifiers(line_a)
    tanc_id_block = line_a.scan($regexes[:tanc_id_block]).to_s.split($delimiters[:tanc_id_pair])
    tanc_en_id = tanc_id_block[0]
    tanc_ja_id = (tanc_id_block.size > 1 ? tanc_id_block[1] : 0)
    return tanc_en_id, tanc_ja_id
  end
  
  # DESC: Process a single reference and return a hash
  #References look like this:  様(よう){ような}
  #The kanji 様 is the index_word,
  #(よう) is the reading 
  #{ような} is the way it actually appears in the sentence (sentence_word), may be inflected, etc
  #Sense numbers are in hard brackets [1] and they are optional
  #Checked has a tilde somewhere in the B line
  def self.process_reference(ref)
    data = {}
    index_word = ref.gsub($regexes[:tag_like_text], "").gsub($regexes[:inside_hard_brackets], "").gsub("~","").strip
    if !@@keyword_stop_list_arr.index(index_word)
      checked = quality_check_marker_found?(ref)
      ref.gsub!("~", "") #remove quality check marker
      data = { 
        :index_word => index_word,
        :sentence_word => ref.scan($regexes[:inside_braces]).to_s,
        :reading => ref.scan($regexes[:inside_parens]).to_s.strip,
        :sense_number => ref.scan($regexes[:tanc_tag_numeric]).to_s,
        :checked => checked
      }
    end
    return data
  end
  
end