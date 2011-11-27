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
    $cn.execute("TRUNCATE TABLE cards_html") if mysql_table_exists("cards_html")
#   $cn.execute("TRUNCATE TABLE card_tag_link") if mysql_table_exists("card_tag_link")
  end

  # DESC: Abstract method, call 'super' from child class to use built-in functionality
  def import(data = [])
      
    bulkSQL = BulkSQLRunner.new(data.size, @config[:sql_buffer_size], @config[:sql_debug])
    data.each do |rec|
      sql = rec.to_insert_sql
      bulkSQL.add( sql + "\n" )
    end
    prt "Inserted #{data.count} entries"
  end
  
  def update_serialized_entries_with_card_id
    $cn.execute("SELECT * from cards_staging").each do |rec|
      cedict_entry = mysql_deserialise_ruby_object(rec[:cedict_hash])
      cedict_entry.id = rec[:id]
      $cn.execute(cedict_entry.to_update_sql)
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

  def set_sql_debug(enabled)
    @config[:sql_debug] = (enabled ? true : false)
  end

end
