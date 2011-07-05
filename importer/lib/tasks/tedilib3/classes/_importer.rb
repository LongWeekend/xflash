#### IMPORTER BASE CLASS #####
class Importer

  include ImporterHelpers
  include DatabaseHelpers

  @sql_command_buffer = []

  ### Class Constructor
  #####################################
  def initialize(data, entry_type)
    ### Instance config vars
    @config = {}
    @config[:data] = data
    @config[:entry_type] = entry_type
    @config[:skipped_data] = []

    # Defaults, use setters to change
    @config[:sql_buffer_size] = 30000
    @config[:noisy_debug] = true
    @config[:skip_empty_meanings] = false
    @config[:sql_debug] = false
    return self
  end

  # DESC: Abstract method, call 'super' from child class to use built-in functionality
  def import(&block)
    # Sanity check
    if !@config[:data]
      exit_with_error("Importer not configured correctly.", @config)
    end

    bulkSQL = BulkSQLRunner.new(config[:data].size, @config[:sql_buffer_size], @config[:sql_debug])
    @config[:data].each do |rec|
      bulkSQL.add( block.call(rec) )
    end
  end
  
  # Public Setters & Getter
  #####################################
  def set_sql_buffer_size(size)
   @config[:sql_buffer_size] = size
  end
  
  def set_noisy_debug(enabled)
    @config[:noisy_debug] = (enabled ? true : false)
  end

  def set_skip_empty_meanings(enabled)
    @config[:skip_empty_meanings] = (enabled ? true : false)
  end

  def set_sql_debug(enabled)
    @config[:sql_debug] = (enabled ? true : false)
  end

  def get_skipped_meanings
    @config[:skipped_data]
  end

  # DESC: Abstract method for exporting to target database
  def self.export_staging_db
    prt "WARNING - I should be overridden with a method to export staging data to its final destination!"
  end
  
  # DESC: Add Romaji, ACCEPTS force=(true|false : regenerates existing romaji, sentences)
  # REQUIRES: Array of cards_readings like this {:card_id=>"73648", :reading=>"ばかもの"}
  def self.separate_romaji_readings(existing_readings_hash=nil, forced=true)

    # Sanity check
    return if existing_readings_hash.nil?
    connect_db

    # A whole mess of temporary files
    utf_src_fn = "juman_tmp_src.utf"
    euc_src_fn = "juman_tmp_src.euc"
    euc_out_fn = "juman_tmp_out.euc"
    utf_out_fn = "juman_tmp_out.utf"
    tmp_sql_fn = 'tmp_sql_updates.sql'

    separated_reading_data = []
    bad_readings = []
    result_data = []

    tickcount("Processing Reading Separation Data (using Juman morphological analyser)") do

      # NB: You must have JUMAN and ICONV installed for this to work.
      #     ICONV comes default on most UNIX systems
      #     JUMAN is avaiable here: http://www433.elec.ryukoku.ac.jp/~yokomizo/ntool/install.html

      prt "Creating temporary kana reading file"
      utf_src_outf = File.open(utf_src_fn, 'w')
      existing_readings_hash.each do |card_id,rec|
        # TODO: 1 Write out each headword/reading with a different identifier
        #       2 JUMAN convert
        #       3 Read results and match back to source hash
        #       4 Do unspaced checksum (MUST MATCH edict sourced, unspaced romaji)
        utf_src_outf.write("[#{card_id}]#{rec[:reading]}\t#{rec[:headword]}\n")
      end
      utf_src_outf.close

      # Init empty files, ICONV/JUMAN don't seem to do this??
      File.open(euc_out_fn,'w'){ |f| f.write('') }
      File.open(utf_out_fn,'w'){ |f| f.write('') }

      # convert UTF8 src to EUC with ICONV at CLI
      # ... make sure your path is correct!
      prt "/sw/bin/iconv -f UTF-8 -t EUC-JP #{utf_src_fn} > #{euc_src_fn}"
      `/sw/bin/iconv -f UTF-8 -t EUC-JP #{utf_src_fn} > #{euc_src_fn}`
      # NB: Inline conversions using Kconv were unreliable, so we use ICONV

      # execute JUMAN at CLI
      # ... make sure your path is correct!
      prt "/usr/local/bin/juman -e < #{euc_src_fn} > #{euc_out_fn}"
      `/usr/local/bin/juman -e < #{euc_src_fn} > #{euc_out_fn}`

      # convert EUC output to UTF8 with ICONV at CLI
      # ... make sure your path is correct!
      prt "/sw/bin/iconv -f EUC-JP -t UTF-8 #{euc_out_fn} > #{utf_out_fn}"
      `/sw/bin/iconv -f EUC-JP -t UTF-8//IGNORE #{euc_out_fn} > #{utf_out_fn}`

      # Read in juman results in utf8 format, delete tmp files
      lines = File.open(utf_out_fn, 'r')
      File.delete(utf_src_fn)
      File.delete(euc_src_fn)
      File.delete(euc_out_fn)

      separated_reading_from_reading = ""
      separated_reading_from_hw = ""
      debug_lines = ""
      line_count = 0
      not_matched_line_count = 0
      entry_count = 1
      curr_card_id = 0
      curr_section = "reading"
      
      lines.each do |line| 
        ##  DEBUG OFF ## debug_lines = debug_lines + line
        
        # Change mode and skip (tab delimits reading from headword)
        if line.scan(/^\t \t \t/).size > 0
          curr_section = "headword"

        # Process the line data
        elsif line != "EOS\n"

          # Split on spaces, and get the second item in array
          data_pos1 = line.split(' ')[0].to_s.strip.strip
          data_pos2 = line.split(' ')[1].to_s.strip.strip
          data_pos4 = line.split(' ')[3].to_s.strip.strip

          if (id_pattern_match = data_pos1.match(/\[(\d+)\]/))
            curr_card_id = id_pattern_match[1]
          end
            
          # Detect particle HA and transliterate into WA
          # EX OUTPUT:  は は は 助詞 9 副助詞 2 * 0 * 0 NIL
          if data_pos1 == "は" && data_pos2 == "は" && data_pos4 == "助詞"
            data_pos1 = "わ" # sub in WA for particle HA
          end

          # Skip additional info lines returned by Juman
          if data_pos1 != "@" && data_pos1 != "/" && data_pos1 != "\\"
            # Add to recompiled string, skip first entry, it's the Card ID da-yo!
            if line_count > 0
              if curr_section == "reading"
                separated_reading_from_reading = separated_reading_from_reading + data_pos2 + " "
              elsif curr_section == "headword"
                separated_reading_from_hw = separated_reading_from_hw + data_pos2 + " "
              end
            end
            line_count+=1
          end
        
        else

          # Add to stack if entry is divisible
          if line_count > 2 || forced || existing_readings_hash[curr_card_id][:romaji].nil? || existing_readings_hash[curr_card_id][:romaji] == ""
            if curr_card_id != ""
              
              # Accuracy Check - If spaced romaji matches original, else roll it back to unspaced version
              if separated_reading_from_reading.gsub(' ', '') == separated_reading_from_hw.gsub(' ', '')
                tmp_reading = separated_reading_from_hw
              else
                tmp_reading = separated_reading_from_reading
                not_matched_line_count = not_matched_line_count+1
                ##prt separated_reading_from_reading.gsub(' ', '') + " --------DID NOT MATCH--------- " + separated_reading_from_hw.gsub(' ', '')
              end

              # Do not add if reading contains kanji still (a bad conversion!)
              if !tmp_reading.match($regexes[:all_common_kanji])
                separated_reading_data << { :card_id => curr_card_id, :reading => tmp_reading }
              else
                separated_reading_data << { :card_id => curr_card_id, :reading => "" }
                bad_readings << { :card_id => curr_card_id, :reading => tmp_reading }
              end
            end
          end

          # Clear loop tracking
          separated_reading_from_reading = ""
          separated_reading_from_hw = ""
          curr_section = "reading"
          debug_lines = ""
          line_count = 0
          useful_line_count = 0
          entry_count+=1
        end

      end

      if not_matched_line_count > 0
        prt_dotted_line
        prt "Conversions not matching source reading: #{not_matched_line_count}\n"
      end

      if bad_readings.length > 0
        prt_dotted_line
        prt "Card IDs Failing Juman Converison = #{bad_readings.size}\n"
        ## bad_readings.each { |line| prt line[:card_id].to_s }
      end

    end

    prt "\nCollecting spaced romaji strings"
    
    separated_entry_count =0
    separated_reading_data.each do |entry|
      card_id = entry[:card_id]
      reading = entry[:reading]
      romaji_str = Kana2rom::kana2rom(Kana2rom::kata2hira(reading.to_s))

      # Try converting reading without spaces when 'little x' encountered (hanging chiisai tsu)
      if !romaji_str.index("x").nil?
        reading_no_spaces = reading.to_s.gsub(" ","")
        retried_romaji_str = Kana2rom::kana2rom(Kana2rom::kata2hira(reading_no_spaces))
        
        # Revert to unspaced reading if we cannot get rid of 'little x' (hanging chiisai tsu)
        if retried_romaji_str.index("x").nil?
         reading = reading_no_spaces
         romaji_str = retried_romaji_str
        else
          prt "Persistent little 'x' detected: " + reading + " >>> " + romaji_str + "."
        end
      end

      ##romaji_str.gsub!(/(,[\s]?)/, ', ') # Make sure commas are followed by precisely one space --- NO LONGER NEEDED???? 27 May 2010
      romaji_str = romaji_str # Escape single quotes since we are using the mysql command line
      separated_entry_count = separated_entry_count+1
      result_data << { :orig_headword => existing_readings_hash[card_id][:headword], :orig_reading => existing_readings_hash[card_id][:reading], :card_id => card_id, :romaji => romaji_str }
    end

    prt "Separated entries buffered: #{separated_entry_count}"
    prt_dotted_line

    File.delete(utf_out_fn)
    return result_data
  end

  # UTIL: Simliar string contained in string?
  def self.util_contains_similar_string?(str1,str2)

    # Homogenize the comparison strings
    str1.gsub!($regexes[:parenthetical], "")
    str2.gsub!($regexes[:parenthetical], "")
    str1.gsub!("'", "")
    str2.gsub!("'", "")
    str1.gsub!($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses])
    str2.gsub!($regexes[:whitespace_padded_slashes], $delimiters[:jflash_glosses])
    str1.strip!
    str2.strip!
    str1.gsub!($regexes[:leading_trailing_slashes], "")
    str2.gsub!($regexes[:leading_trailing_slashes], "")
    str1.gsub!($regexes[:duplicate_spaces], "")
    str2.gsub!($regexes[:duplicate_spaces], "")
    str1.strip!
    str2.strip!

    # Look for one string in the other
    duplicate = !str1.strip.downcase.index(str2.strip.downcase).nil?
    if !duplicate
      duplicate = !str2.strip.downcase.index(str1.strip.downcase).nil?
    end

    # Try the Levenshtein distance algo
    if !duplicate

      ldistance = (Levenshtein.distance(str1.strip.downcase, str2.strip.downcase).to_f / (str1.strip).size.to_f) *100
      #prt "LDISTANCE: "+ldistance.to_i.to_s
      #prt "orig "+str1
      #prt "new  "+str2
      #prt_dotted_line("\n")

      if ldistance < 33.333
        puts "Duplicate avoided: '"+ str1.to_s + "'  >>> >>>  " + str2 + "#{ldistance.to_s}"
        puts "^^^^^^^^^^^^^^^^^"
        duplicate = true
      end
    end

    return duplicate
  end

  # XFORMATION: Remove common English stop words from string
  def self.xfrm_to_romaji(str)
    Kana2rom::kana2rom( Kana2rom::kata2hira(str) )
  end

  # XFORMATION: Remove common English stop words from string
  def self.xfrm_remove_stop_words(str)
   stop_words = ['I', 'me', 'a', 'an', 'am', 'are', 'as', 'at', 'be', 'by','how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'than', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will', 'with', 'the']
   results = []
   str.gsub!($regexes[:inlined_tags], "") ## remove tag blocks
   str.split(' ').each do |sstr|
     # remove non word characters from string
     results << sstr unless stop_words.index(sstr.gsub(/[^a-zA-Z|\s]/, '').strip)
   end
   return results.flatten.compact.join(' ')
  end

  # XFORMATION: Extracts an English headword from a string
  def self.xfrm_extract_en_headword(first_meaning_string)
    return first_meaning_string.gsub("'" , "''").gsub('  ', ' ').gsub('/', ' / ').split("/").first.strip
  end

  # XFORMATION: Move parenthetical prefixes to the end gloss string
  def self.xfrm_reorder_parentheticals(gloss)
    if (tmp = gloss.scan($regexes[:leading_parenthetical])).size > 0
      g= (gloss.gsub(tmp.to_s, '') + ' ' + tmp.to_s).strip
    else
      g= gloss.gsub($regexes[:duplicate_spaces], " ")
    end
    return g.gsub($regexes[:duplicate_spaces], " ")
  end

  # ACCEPTS: query options hash, block to process caching
  # RETURNS: hash of cached rows as set by block
  # REQUIRES: block to return a obj
  def self.cache_sql_query(options, &block)
    connect_db
    cache_data = {}
    cnt = 0
    options[:where].gsub!(/^WHERE/)
    options[:where] = (options[:where].length > 0 ? "WHERE #{options[:where]}": "")
    tickcount("Caching Query") do
      results = $cn.select_all("SELECT #{options[:select]} FROM #{options[:from]} #{options[:where]}")
      results.each do |sqlrow|
        block.call(sqlrow, cache_data)
        cnt = noisy_loop_counter(cnt, results.size)
      end
    end
    prt "Cached #{cnt} SQL records\n\n"
    return cache_data
  end

end