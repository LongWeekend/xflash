##################################################
# RiTunes 0.00
##################################################

require 'mechanize'
require 'json'
require 'nokogiri'

load File.dirname(__FILE__) + "/tedilib3/_modules.rb"
load File.dirname(__FILE__) + "/tedilib3/classes/_bulk_sql.rb"
  
module RiHelpers

  def configure_ritunes
    # Call inside task to override rails defaults
    $options = {}
    $options[:default_break_point] = 0
    $options[:verbose] = true
    $options[:force_utf8] = false
    $options[:cache_fu_on] = false
    $options[:mysql_port] = 3306
    $options[:mysql_name] = "ritunes"
    $options[:mysql_host] = "localhost"
    $options[:mysql_username] ="root"
    $options[:mysql_password] = ""
  end

  # Create a validation token that iTunes Store will accept
  def get_validation_seed(url, user_agent)
    require 'base64'
    require 'digest/md5'
    random_str  = "%04X04X" % [(rand * 0x10000), (rand * 0x10000)]
    static = Base64.decode64("ROkjAaKid4EUF5kGtTNn3Q==")
    matches = url.scan(/.*\/.*\/.*(\/.+)$/)
    url_end = (matches.size > 0 ? matches[0] : '?')
    digest  = Digest::MD5.hexdigest([url_end, user_agent, static, random_str].join("") )
    return random_str + '-' + digest.to_s.upcase
  end
  
  def get_itunes_headers(url, store_front=nil, user_agent=nil)
    store_front = "143457" if store_front.nil?
    user_agent = "iTunes/9.2 (Macintosh; Intel Mac OS X 10.6.4) AppleWebKit/533.16" if user_agent.nil?
    return {
      "X-Apple-Tz" => "7200",
      "X-Apple-Store-Front" => store_front,
      "Accept-Language" => "en-us, en;q=0.50",
      "X-Apple-Validation" => get_validation_seed(url, user_agent),
      "Accept-Encoding" => "gzip, x-aes-cbc",
      "Connection" => "close",
      "Host" => "ax.phobos.apple.com.edgesuite.net"
    }
  end

  def get_itunes_countries
    ["us", "gb", "jp", "au", "ca"]
  end

  def search_itunes_private(options_hash, dump=false)

    private_base_url = "http://ax.search.itunes.apple.com/WebObjects/MZSearch.woa/wa/advancedSearch?"
    private_api_query_str = "media=software&softwareTerm=#{options_hash[:term]}&softwareDeveloper=&genreIndex=#{options_hash[:genreIndex]}&deviceTerm=AllDevices"
    search_url = private_base_url + private_api_query_str
    
    bot = Mechanize.new do |agent| 
      agent.pre_connect_hooks << lambda do |params|
        get_itunes_headers(search_url).each { |k,v| params[:request][k] = v }
      end
    end

    pp search_url
    bot.get(search_url) do |page|
      doc = Nokogiri::XML(page.body, nil,'UTF-8')
      pp doc
    end
    
    debugger
    return doc

  end

  def search_itunes_public(options_hash, dump=false)

    # Lookup URL
    # http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStoreServices.woa/wa/wsLookup?id=296430281

    # Searches that work ...
    # ?attribute=genreTerm&entity=software&term=Education
    # ?attribute=keywordsTerm&entity=software&term=japanese+flash
    # ?attribute=keywordsTerm&entity=software&term=japanese+flash

    public_base_url_str  = "http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStoreServices.woa/wa/wsSearch?"
    country_codes_array = get_itunes_countries
    search_options_hash = { 
      :term => "term",
      :output => "output", 
      :lang => "lang",
      :offset => "offset",
      :output => "output",
      :entity => "entity"
    }
    recs_per_page = 500
    limit = options_hash[:limit].to_i if options_hash.has_key?(:limit)

    # Order sensitive criteria
    options_hash[:entity]    = "software" if !options_hash.has_key?(:entity)
    options_hash[:attribute] = "keywordsTerm" if !options_hash.has_key?(:attribute)
    param_str = "attribute=#{options_hash[:attribute]}&entity=#{options_hash[:entity]}"

    if options_hash[:attribute] == "keywordsTerm"
      keywords = options_hash[:term]
    else
      keywords = ""
    end

    # remove processed items from hash
    options_hash.delete(:entity)
    options_hash.delete(:attribute)

    # Process other options
    search_options_hash.each do |key, attrib|
      param_str = param_str + "&#{attrib}=#{options_hash[key]}" if options_hash.has_key?(key) and !options_hash[key].nil? and options_hash[key].size > 0
    end

    # Order matters, append these!
    param_str = param_str + "&limit=#{recs_per_page}"
    param_str = param_str + "&country=#{options_hash[:country]}" if options_hash.has_key?(:country) && country_codes_array.index(options_hash[:country])
    result_array = process_paged_search(public_base_url_str, param_str, keywords, recs_per_page, limit, dump)
    return result_array
  end

  def process_paged_search(search_url, search_params, keywords, recs_per_page=500, limit=0, dump=false)
    if limit > recs_per_page
      pages = (limit - (limit % recs_per_page)) / recs_per_page + (limit % recs_per_page == 0 ? 0 : 0)
    else
      pages = 1
    end

    rank = 0
    for page_no in 1..pages
      search_url= search_url + search_params + "&offset=#{page_no*recs_per_page - recs_per_page+1}"
      result_array = []
      prt "\n" + search_url + "\n"

      bot = Mechanize.new do |agent| 
        agent.user_agent_alias = 'Mac Safari' 
      end
  
      bot.get(search_url) do |page|
        result_array = get_result_array(page)
      end
  
      if result_array and result_array.size > 0
        # log results to mysql
        connect_db
        search_id  = get_sql_log_search(search_params)
        bulkSQL = BulkSQLRunner.new(0, 10000)
        rank = (page_no-1)*recs_per_page

        result_array.each do |rec|
          rank += 1
          get_sql_log_publisher( rec )
          bulkSQL.add( get_sql_log_app(rec) )
          bulkSQL.add( get_sql_log_publisher(rec) )
          bulkSQL.add( get_sql_log_keywords(rec['trackId'], keywords) )
          bulkSQL.add( get_sql_log_metadata(rec) )
          bulkSQL.add( get_sql_log_rankings(rank, rec['trackId'], search_id) )
        end
        bulkSQL.flush

        if dump
          # show details
          dump_search(options_hash[:term], result_array)
        else
          # report highlights
          prt "Retrieved: #{result_array.size} recs for '#{search_params}'"
        end
    
        # Get outta here if we're done!
        prt "-----------------"
        prt rank
        prt (recs_per_page*page_no)
      end
      break if rank < (recs_per_page*page_no)
    end
    return result_array
  end

  def empty_logging_tables
    connect_db
    $cn.execute('TRUNCATE TABLE apps')
    $cn.execute('TRUNCATE TABLE keyword_index')
    $cn.execute('TRUNCATE TABLE metadata')
    $cn.execute('TRUNCATE TABLE rankings')
    $cn.execute('TRUNCATE TABLE searches')
  end

  def get_sql_log_app(rec)
    return "INSERT IGNORE INTO apps (app_id, publisher_id, name) VALUES (#{rec['trackId']}, #{rec['artistId']}, '#{mysql_escape_str(rec['trackName'])}');"
  end

  def get_sql_log_publisher(rec)
    return "INSERT IGNORE INTO publishers (publisher_id, name) VALUES (#{rec['artistId']}, '#{mysql_escape_str(rec['artistName'])}');"
  end

  def get_sql_log_search(search_string)
    connect_db
    tmp = []
    country = "WW"
    search_string.split('&').sort.each do |a|
      country = a.split('=')[1].upcase if a.index("country=")
      tmp << a if a.index("limit=").nil? and a.index("country=").nil? # do not include country or limit
    end

    search_string = tmp.join('&')
    existing_search_id = 0
    $cn.execute("SELECT search_id FROM searches WHERE search_string = '#{search_string}' AND country = '#{country}'").each do |search_id|
      existing_search_id = search_id
    end

    if existing_search_id != 0
      return existing_search_id
    else
      return $cn.insert("INSERT IGNORE INTO searches (search_string, country) VALUES ('#{search_string}', '#{country}')")
    end
  end
  
  def get_sql_log_rankings(rank, app_id, search_id)
    return "INSERT INTO rankings (app_id, search_id, rank, date) VALUES (#{app_id}, #{search_id}, #{rank}, '#{Time.now.to_s(:db)}');"
  end

  def get_sql_log_keywords(app_id, keywords)
    sql = []
    keywords.gsub('+',' ').split(' ').each do |kw|
      sql << "INSERT IGNORE INTO keyword_index (app_id, keyword) VALUES (#{app_id}, '#{mysql_escape_str(kw)}');"
    end
    return sql.join("\n")
  end
  
  def get_sql_log_metadata(rec)
    return "INSERT INTO metadata (app_id, price, date) VALUES (#{rec['trackId']}, '#{rec['price'].to_i}', '#{Time.now.to_s(:db)}');"
  end

  def dump_search(kw, result_array)
    kw = "[BLANK]" if kw.nil?
    prt "KEYWORDS: #{get_humanized_keywords(kw)}"
    prt "------------------------------------------------\n"
    count=0
    result_array.each do |r|
      count+=1
      prt "#{count}\t#{r["trackName"]}\t#{r["trackId"]}\t#{r["price"]}\t#{r[:version]}\t#{r[:releaseDate]}"
    end
  end
  
  def itunes_result_keys
    return ["price",
     "trackViewUrl",
     "genreIds",
     "sellerName",
     "artistId",
     "artworkUrl100",
     "trackName",
     "wrapperType",
     "screenshotUrls",
     "primaryGenreName",
     "artworkUrl60",
     "trackContentRating",
     "supportedDevices",
     "contentAdvisoryRating",
     "releaseDate",
     "version",
     "fileSizeBytes",
     "sellerUrl",
     "artistName",
     "artistViewUrl",
     "description",
     "languageCodesISO2A",
     "primaryGenreId",
     "ipadScreenshotUrls",
     "genres",
     "trackCensoredName",
     "trackId"]
  end

  def observation_price_high?(price)
    (price.to_i > 10)
  end

  def observation_name_overlong?(name)
    (name.size > 40)
  end

  def get_results(page)
    page.body["results"]
  end

  def get_results_count(page)
    page.body["results"].size
  end

  def get_mechanized_keywords_array(kw_arr)
    kw_arr.join("+").gsub(" ", "+")
  end
  
  def get_humanized_keywords(kw_str)
    kw_str.gsub("+", " ")
  end

  def get_result_array(page)
    JSON.parse(page.body)["results"]
  end

  def create_ritunes_tables(tables_arr=[], create_all=false)

    create_statements ={}
    create_statements["searches"] ="\\
    CREATE TABLE `searches` (\\
      `search_id` int(11) NOT NULL AUTO_INCREMENT,\\
      `search_string` varchar(255) NOT NULL,\\
      `country` varchar(2) DEFAULT NULL,\\
      PRIMARY KEY (`search_id`),\\
      UNIQUE KEY `search_string` (`search_string`),\\
      KEY `search_string_2` (`search_string`)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;"
    
    create_statements["searches"] ="\\
    CREATE TABLE `rankings` (\\
      `search_id` int(11) NOT NULL,\\
      `app_id` int(11) NOT NULL,\\
      `rank` int(11) DEFAULT '0',\\
      `date` datetime NOT NULL,\\
      UNIQUE search_string_country (search_string, country)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["publishers"] ="\\
    CREATE TABLE `publishers` (\\
      `publisher_id` int(11) NOT NULL,\\
      `name` varchar(255) DEFAULT NULL,\\
      PRIMARY KEY (`publisher_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    
    create_statements["metadata"] ="\\
    CREATE TABLE `metadata` (\\
      `id` int(11) NOT NULL AUTO_INCREMENT,\\
      `app_id` int(11) DEFAULT NULL,\\
      `price` int(11) DEFAULT NULL,\\
      `date` datetime DEFAULT NULL,\\
      PRIMARY KEY (`id`)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=2001 DEFAULT CHARSET=utf8;"
    
    create_statements["keyword_index"] ="\\
    CREATE TABLE `keyword_index` (\\
      `id` int(11) NOT NULL AUTO_INCREMENT,\\
      `app_id` int(11) DEFAULT NULL,\\
      `keyword` varchar(255) DEFAULT NULL,\\
      PRIMARY KEY (`id`),\\
      UNIQUE keyword_app_id (app_id, keyword)\\
    ) ENGINE=MyISAM AUTO_INCREMENT=2001 DEFAULT CHARSET=utf8;"
    
    create_statements["apps"] ="\\
    CREATE TABLE `apps` (\\
      `app_id` int(11) NOT NULL,\\
      `publisher_id` int(11) NOT NULL,\\
      `name` varchar(255) NOT NULL,\\
      PRIMARY KEY (`app_id`)\\
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
    connect_db

    # Create tables we are told to make
    tables_arr = create_statements.keys.collect {|i| i} if create_all
    tables_arr.each do |table_nm|
      if tables_arr.index(table_nm) and !mysql_table_exists(table_nm)
        $cn.execute(create_statements[table_nm])
      end
    end

  end

end


namespace :ritunes do

  include DatabaseHelpers
  include ImporterHelpers
  include RiHelpers

  desc "Run search against iTunes Search API"
  task :spoof => :environment do
    
    configure_ritunes
    pp search_itunes_private({ :term => "Education", :genreIndex => 4, :limit => 100 })

  end
  
  desc "Run search against iTunes Search API"
  task :search => :environment do
    
    configure_ritunes
    keyword_stack = ["flash cards", "flash", "learn", "study", "proficiency test", "vocab", "vocabulary"]
    domain_keyword = "japanese"
    country_arr = get_itunes_countries[0..3]

    # empty storage tables
    empty_logging_tables if get_cli_attrib('empty')

    country_arr.each do |geo|

      # search and buffer
      results_array = []

      # get first 5000 in keyword domain 
      results_array << search_itunes_public({ :term => domain_keyword, :country => geo, :limit => 5000  })

      # get first 5000 in education
      results_array << search_itunes_public({ :term => "Education", :attribute => "genreTerm", :country => geo, :limit => 5000 })

      # process keyword stack
      keyword_stack.each do |kw|

        # collect keywords
        kw_arr = []
        kw_arr << domain_keyword
        kw_arr << kw
        kw = get_mechanized_keywords_array(kw_arr)

        # search and buffer
        results_array << search_itunes_public({ :term =>kw, :country => geo, :limit => 1000})

      end
    end

  end

end