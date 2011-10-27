class CEdictImporter

  include ImporterHelpers
  include DatabaseHelpers

  @sql_command_buffer = []
  
  ### Class Constructor
  #####################################
  def initialize
    ### Instance config vars
    @config = {}
 
    # Defaults, use setters to change
    @config[:sql_buffer_size] = 30000
    @config[:noisy_debug] = true
    @config[:sql_debug] = false
    return self
  end
  
  # DESC: Removes all data from import staging tables (should be run before calling import)
  def empty_staging_tables
    connect_db
    prt "Removing all data from CEDICT import staging table (cards_staging)\n\n"
    $cn.execute("TRUNCATE TABLE cards_staging")
#   $cn.execute("TRUNCATE TABLE cards_html") if mysql_table_exists("cards_html")
#   $cn.execute("TRUNCATE TABLE card_tag_link") if mysql_table_exists("card_tag_link")
  end

  # RETURNS: Existing cards and adds them into a hash
  def cache_existing_cards(table ="cards_staging", where ="")
    lookup = self.cache_sql_query( { :select => "card_id, headword_trad", :from => table, :where => where } ) do | sqlrow, cache_data |
      # We are not taking data from multiple sources
      card_type = 0
      cache_data[card_type] = {} if !cache_data[card_type]
      # Store rows in hash, deserialise stored Ruby Obj
      cache_data[card_type][sqlrow['headword_trad']] = [] if !cache_data[card_type][sqlrow['headword_trad']]
      cache_data[card_type][sqlrow['headword_trad']] << sqlrow['card_id']
    end
    return lookup
  end
    
  # Creates tables in the database from a passed in array of tags
  def create_tags_staging(tags = {})
    connect_db
    bulkSQL = BulkSQLRunner.new(tags.size, 30000, false)
    insert_tag_sql = "INSERT INTO tags_staging (tag_name,tag_type,short_name,description,source_name,source,visible,count,parent_tag_id,force_off) VALUES ('%s','%s','%s','%s','%s','%s',%s,%s,%s,%s);"
    tags.each do |key, tag_data|
      bulkSQL.add(insert_tag_sql % [key,"",key,key,key,key,"1",tag_data[:count],"0","0"])
    end
  end

  # DESC: Empty and update the headword/card_id 
  def create_headword_index

    connect_db
    $cn.execute("TRUNCATE TABLE idx_cards_by_headword_staging")
    bulkSQL = BulkSQLRunner.new(0, 0)

    tickcount("Recreating Headword Keyword-Index") do
      $cn.execute("SELECT card_id, headword_trad, reading FROM cards_staging").each do | card_id, headword, reading |
        bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{headword}');")
        reading.split($delimiters[:jflash_readings]).each do |keyword|
          bulkSQL.add("INSERT INTO idx_cards_by_headword_staging (card_id, keyword) values (#{card_id}, '#{keyword}');")
        end
      end
    end
    
    bulkSQL.flush
  end

  # DESC: Abstract method, call 'super' from child class to use built-in functionality
  def import(data = [])
    new_counter = 0
      
    bulkSQL = BulkSQLRunner.new(data.size, @config[:sql_buffer_size], @config[:sql_debug])
    data.each do |rec|
      sql = rec.to_insert_sql
      new_counter = new_counter + 1
      bulkSQL.add( sql + "\n" )
    end
    prt "Inserted #{new_counter}"
  end
  

  # Public Setters & Getter
  #####################################
  def set_sql_buffer_size(size)
   @config[:sql_buffer_size] = size
  end
  
  def set_noisy_debug(enabled)
    @config[:noisy_debug] = (enabled ? true : false)
  end

  def set_sql_debug(enabled)
    @config[:sql_debug] = (enabled ? true : false)
  end

end
