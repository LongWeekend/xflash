class HumanParseExceptionHandler

  # MAIN METHODS
  def get_human_result_for_string(input_str, exception_type_str)
    raise "Impromper input to get_human_result_for_string, input must be String" unless input_str.kind_of?(String)
    raise "Impromper input to get_human_result_for_string, second param must be String" unless exception_type_str.kind_of?(String)

    # Initialize
    connect_db

    # Check the database to see if we have any objects that match it -- quick return if YES
    escaped_input_str = mysql_escape_str(input_str)
    escaped_exc_str = mysql_escape_str(exception_type_str)
    resolution = $cn.execute("SELECT resolution_string FROM parse_exceptions WHERE input_string = '%s' AND exception_type = '%s' LIMIT 1" % [escaped_input_str, escaped_exc_str]).each do |rec|
      return rec[0]
    end
    
    # OK, didn't find anything, so insert a new row
    insert_sql = "INSERT INTO parse_exceptions (input_string, exception_type, created_at, updated_at) VALUES ('%s','%s',NOW(),NOW()) ON DUPLICATE KEY UPDATE updated_at = NOW()" % [escaped_input_str, escaped_exc_str]
    $cn.execute(insert_sql)
    # Return false, nothing found
    return false
  end
  
  def add_human_result_for_string(input_str, exception_type_str, corrected_str)
    connect_db
    escaped_input_str = mysql_escape_str(input_str)
    escaped_exc_str = mysql_escape_str(exception_type_str)
    escaped_corrected_str = mysql_escape_str(corrected_str)
    insert_sql = "UPDATE parse_exceptions SET resolution_string = '%s' WHERE input_string = '%s' AND exception_type = '%s'" % [escaped_corrected_str, escaped_input_str, escaped_exc_str]
    $cn.execute(insert_sql)
  end
  
  # STATIC METHODS FOR DATABASE
  
  def self.truncate_exception_tables
    connect_db
    $cn.execute("TRUNCATE TABLE parse_exceptions")
  end
  
end