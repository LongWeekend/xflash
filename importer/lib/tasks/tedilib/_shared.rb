############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#  --- Shared functions library file ---
############################################

require 'ya2yaml' # This gem is required!

# Import Options
@options[:import_user_id] = 1
@options[:english_lang_id] = Language.find_by_name("English").id
@options[:japanese_lang_id] = Language.find_by_name("Japanese").id
@options[:statuses] = BatchJob.import_statuses


#-------------------------------------------------------------------
# Get CLI Parameters
#-------------------------------------------------------------------

# Fetch "to" command line or set to default
def get_cli_break_point
  if ENV.include?("to") && ENV['to'] && ENV['to'].to_i > 0
    return ENV['to'].to_i
  else
    return @options[:default_break_point]
  end
end

# Empty tables or not
def get_cli_empty_tables
  return ( ENV.include?("kill") && ENV['kill'] )
end

# Silent or Not
def get_silent
  return ( ENV.include?("silent") && ENV['silent'] )
end

# Fetch "start" from command line or set to default
def get_cli_start_point
  if ENV.include?("from") && ENV['from'] && ENV['from'].to_i > 0
    return ENV['from'].to_i
  else
    return 1
  end
end

# Fetch "type" from command line or set to default
def get_cli_type
  if ENV.include?("type") && ENV['type']
    return ENV['to'].to_s
  else
    return ""
  end
end

# Fetch "force" command from or set default
def get_cli_forced
  if ENV.include?("force") && ENV['force']
    return true
  else
    return false
  end
end

# Fetch "worker" number from command line
# Not implemented everywhere!
def get_worker_id
  if ENV.include?("worker") && ENV['worker']
    return ENV['worker']
  else
    return 0
  end
end

# Fetch "memcached" from command line
def get_memcached_enabled
  if ENV.include?("memcached") && ENV['memcached']
    return true
  else
    return false
  end
end

# Fetch regex from command line or set to default
def get_cli_regex
  if ENV.include?("rex")
    if ENV['rex'].scan(/\/.+\//)
      rex = Regexp.new ENV['rex'].scan(/\/(.+)\//).to_s
    else
      rex = ENV['rex']
    end
  else
    rex = @regexes[:antonym]
  end
  return rex
end


#-------------------------------------------------------------------
# Database Helpers
#-------------------------------------------------------------------

#
# (true) empty_tables : Clears out specific tables
#
def empty_tables
  ## Careful where you use this!!
  tickcount("Deleting old data (collections/scraps/revisions/taggings/tags/scrap_pages)") do
    @cn.execute("TRUNCATE TABLE collections")
    @cn.execute("TRUNCATE TABLE batch_jobs")
    @cn.execute("TRUNCATE TABLE scraps")
    @cn.execute("TRUNCATE TABLE revisions")
    @cn.execute("TRUNCATE TABLE taggings")
    @cn.execute("TRUNCATE TABLE links")
  end
  return true
end

def delete_incomplete(table)
  @cn.execute("DELETE FROM #{table} WHERE import_status <> #{@options[:statuses]["completed"]} and import_status <> #{@options[:statuses]["not_imported"]}")
  puts "Deleted incomplete import items from #{table}" unless @options[:silent]
  return true
end

def disable_keys(table)
  @cn.execute("ALTER TABLE #{table} DISABLE KEYS")
  return true
end

def enable_keys(table)
  @cn.execute("ALTER TABLE #{table} DISABLE KEYS")
  return true
end

def commit_imported_recs(table, import_id)
  @cn.execute("UPDATE #{table} SET import_status = #{@options[:statuses]["completed"]} WHERE import_status = #{@options[:statuses]["inserted"]} AND import_batch_id = #{import_id}")
  return true
end

def finalise_batch(current_batch)
  return current_batch.update_attribute("completed_at", Time.now)
end

def get_existing_scrap_topics_hash(conditions="")
  # conditions = independant SQL conditions
  conditions = " " + conditions + " AND " if conditions!= ""
  if !@scrap_topics_hash
    @scrap_topics_hash = {}
    tickcount("SELECT of all Existing ScrapTopics") do
      scrap_topics = @cn.execute("SELECT id, title FROM collections WHERE #{conditions} type ='ScrapTopic'")
      scrap_topics.each do |id,title| 
        @scrap_topics_hash[title] = id
      end
    end
  end
  return @scrap_topics_hash
end

#-------------------------------------------------------------------
# Misc Helpers
#-------------------------------------------------------------------

# <cf_style>Rockin it!</cf_style> Counts run time of the bounded block and outputs it
def tickcount(id = "", noisy = true)
  from = Time.now
  puts "\n"
  puts "> START: " + (id =="" ? "Anonymous Block" : id) unless @options[:silent]
  yield
  to = Time.now
  @ticks[id] = { :from => from, :to => to, :total => to-from } if id
  puts "> END: " + (id =="" ? "Anonymous Block" : id) + " time taken: #{(to-from).to_s} s" unless @options[:silent]
  puts "---------------------------------------------------------------------\n"
  return true
end

# Dump the key from the hash supplied within range specified, eg. cross_section(results[:data], 1, 1500, :antonym)
def cross_section(hsh, from, to, token)
  cnt = 0
  hsh.each do |k,v|
    cnt = cnt + 1
    break if cnt > to
    puts cnt.to_s + ". " + v[token] if v[token].to_s != "" and cnt >= from
  end
  return true
end

# Scan file and count using command line specified regex
def scan_source_file(import_type="edict2", mode="noisy")
  counted = 0
  rex = get_cli_regex
  # Pass block to function ... there really is no price for awesomeness!!!
  results = process_lines(import_type, "scan", get_cli_start_point, get_cli_break_point) do |line|
    if line.scan(rex).length > 0
      counted = counted + 1
      times = line.scan(rex).length.to_s
      if mode=="noisy"
        puts counted.to_s + ".  " + times +" times " + line
      else
        puts line
      end
    end
  end
  return counted
end

# Transforms tag or not, according to @tag_transformations entries
def transform_tag?(tag)
  if @tag_transformations.has_key?(tag)
    return @tag_transformations[tag]
  else
    return tag
  end
end

def format_definition(read, use, type="YAML")
  if type == "xml"
    #XML!
    xml = {}
    xml = {"readings" => ["#{read}"], "usage" => ["#{use}"] }
    return XmlSimple.xml_out(xml, 'RootName' => 'data')
  else
    #YAML!
    yml = {"readings" => ["#{read}"], "usage" => ["#{use}"] }
    return yml.ya2yaml
  end
end

def format_parallel_text(jpn, trns, ann, type ="YAML")
  if type == "xml"
    #XML!
    xml = {"japanese" => ["#{jpn}"], "translated" => ["#{trns}"], "annotation" => ["#{ann}"] }
    # convert to XML using module and return
    return XmlSimple.xml_out(xml, 'RootName' => 'data')
  else
    #YAML!
    yml = {"japanese" => ["#{jpn}"], "translated" => ["#{trns}"], "annotation" => ["#{ann}"] }
    return yml.ya2yaml
  end
end

def jflash_import_db_connect(dbname)
  ActiveRecord::Base.establish_connection (
     :adapter  => "mysql",
     :database => dbname,
     :port     => 3306,
     :host     => "localhost",
     :encoding => "utf8",
     :username => "root",
     :password => ""
   )
   return ActiveRecord::Base.connection()
end

def mysql_cli_file_import(db, username, pw, fn)
  # Run mysql from command line!
  puts "==== Opening Command Line ====\n" unless @options[:silent]
  pw = (pw.size > 1 ? "-p #{pw} " : "")
  if username.nil?
    username = "-u root "
  else
    username = "-u #{username} "
  end
  puts "mysql -h localhost #{username} #{pw}--default_character_set utf8 #{db} < #{fn}"
  system("mysql -h localhost #{username} #{pw}--default_character_set utf8 #{db} < #{fn}")
end

# Sourced from http://groups.google.com/group/comp.lang.ruby/browse_thread/thread/6fbc7db779aa5a2c
# Hashes a string with very low chance of overlap
def ap_hash( str, len=str.length )
  hash = 0
  len.times{ |i|
    if (i & 1) == 0
      hash ^= (hash << 7) ^ str[i] ^ (hash >> 3)
    else
      hash ^= ~( (hash << 11) ^ str[i] ^ (hash >> 5) )
    end
  }
  return hash & 0x7FFFFFFF
end

# Sourced from ThinkingSphinx pluing by Pat Allan (http://freelancing-god.github.com)
# a fail-fast, hopefully helpful version of system
def system!(cmd)
  unless system(cmd)
    raise <<-SYSTEM_CALL_FAILED
The following command failed:
  #{cmd}

This could be caused by a PATH issue in the environment of cron/passenger/etc. Your current PATH:
  #{ENV['PATH']}
SYSTEM_CALL_FAILED
  end
end

#
# Wrapper for calling a Sphinx Update of All Indexes
#
def update_all_sphinx_indexes
   update_sphinx_index("--all")
end

#
# Wrapper for calling a Sphinx Update of Specified Indexes
#
def update_sphinx_index(idx)
  config = ThinkingSphinx::Configuration.instance
  cmd = "#{config.bin_path}#{config.indexer_binary_name} --config #{config.config_file} #{idx} --rotate"
  cmd << " --quiet" if @options[:silent]
  system!(cmd)
end

#
# mysql_col_exists
#
def mysql_col_exists(table_col_str)
  tmp = table_col_str.split('.')
  table = tmp[0]
  col = tmp[1]
  return !@cn.select_one("SHOW COLUMNS FROM #{table} WHERE Field = '#{col}'").nil?
end

#
# Remove most common English stop words from string
#
def remove_stop_words(str)
 stop_words = ['I', 'me', 'a', 'an', 'am', 'are', 'as', 'at', 'be', 'by','how', 'in', 'is', 'it', 'of', 'on', 'or', 'that', 'than', 'the', 'this', 'to', 'was', 'what', 'when', 'where', 'who', 'will', 'with', 'the']
 result = []
 str.split(' ').each do |sstr|
   result << sstr unless stop_words.index(sstr)
 end
 return result.flatten.join(' ')
end