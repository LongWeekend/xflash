#### BULK SQL RUNNER ####
#### Adds support for bulk inserting SQL at command line ####
class BulkSQLRunner
  
  include DatabaseHelpers
  
  def initialize(max_records=0, sql_buffer_size=1000, sql_debug=false)
    @sql_buffer_size = sql_buffer_size # buffer size 0 means manual flush expected
    @max_records = max_records
    @loop_count = 0
    @sql_line_count = 0
    @sql_execution_count = 0
    @sql_debug = sql_debug
    @buffered_sql_array = []
  end 
  
  # Add SQL commands to buffer
  def add(*args)
    @loop_count = @loop_count+1
    @sql_line_count = @sql_line_count+1
    @buffered_sql_array << args.to_s
    if @loop_count == @max_records || @sql_line_count == @sql_buffer_size && @sql_buffer_size != 0
      flush
    end
  end
  
  # Execute buffered SQL commands 
  def flush(sql_debug=false)
    @sql_execution_count = @sql_execution_count +1
    prt "Inserting #{@sql_execution_count * @sql_buffer_size - @sql_buffer_size + (@loop_count==@max_records?0:1)} ~ #{@loop_count} of #{(@max_records > @loop_count ? @max_records : @loop_count)}"
    if !sql_debug && !@sql_debug
     mysql_run_query_via_cli(@buffered_sql_array.join("\n"))
    else
      prt @buffered_sql_array.join("\n")
    end
    @buffered_sql_array = []
    @sql_line_count = 0
  end
end
