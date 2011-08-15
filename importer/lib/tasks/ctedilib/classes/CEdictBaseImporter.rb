#### IMPORTER BASE CLASS #####
class CEdictBaseImporter

  include ImporterHelpers
  include DatabaseHelpers

  @sql_command_buffer = []

  ### Class Constructor
  #####################################
  def initialize (data)
    ### Instance config vars
    @config = {}
    @config[:data] = data
    # MMA - not sure this is used anymore
    @config[:entry_type] = 0
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

    bulkSQL = BulkSQLRunner.new(@config[:data].size, @config[:sql_buffer_size], @config[:sql_debug])
    @config[:data].each do |rec|
      bulkSQL.add( block.call(rec) )
    end
  end
  
  # ACCEPTS: query options hash, block to process caching
  # RETURNS: hash of cached rows as set by block
  # REQUIRES: block to return a obj
  def cache_sql_query(options, &block)
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
  def xfrm_remove_stop_words(str)
   stop_words = ['I', 'me', 'a', 'an', 'am', 'are', 'as', 'at', 'be', 'by','how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'than', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will', 'with', 'the']
   results = []
   str.gsub!($regexes[:inlined_tags], "") ## remove tag blocks
   str.split(' ').each do |sstr|
     # remove non word characters from string
     results << sstr unless stop_words.index(sstr.gsub(/[^a-zA-Z|\s]/, '').strip)
   end
   return results.flatten.compact.join(' ')
  end

  def self.xfrm_extract_en_headword(first_meaning_string)
    if first_meaning_string.length > 0
      return first_meaning_string.gsub("'","''").gsub('  ',' ').gsub('/', ' / ').split("/").first.strip
    else
      return first_meaning_string
    end
  end

end
