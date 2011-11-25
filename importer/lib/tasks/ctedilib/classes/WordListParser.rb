class WordListParser < Parser

  # Alias the base class' method 
#  alias :run_super :run


  def run(entry_class = 'Entry')
    entries = []
    @human_exception_handler = HumanParseExceptionHandler.new

    # Call 'super' method to process loop for us
    super() do |line, line_no, cache_data|
      
      entry = entry_class.constantize.new
      
      # Use exception handling to weed out bad entries
      begin
        # Don't process comments
        if line.index("#") == 0
          print "Skipping comment on line #%s: %s" % [line_no, line]
        else
          if @rescued_line == false
            result = entry.parse_line(line)
          else
            result = entry.parse_line(@rescued_line)
            @rescued_line = false
          end
          if result
            entries << entry
          end
        end
      rescue Exception => e
        if @rescued_line == false
          @rescued_line = @human_exception_handler.get_human_result_for_string(line,e.class.name)
          if @rescued_line
            retry
          else
            prt "Could not parse line #%s: %s (msg: %s)" % [line_no, line,e.message]
          end
        else
          prt "Rescued line was not false but exception caught -- this means we may have infinite loop!"
          @rescued_line == false
        end
      end
    end
    return entries
  end
end