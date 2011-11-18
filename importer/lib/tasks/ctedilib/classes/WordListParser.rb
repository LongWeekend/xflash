class WordListParser < Parser

  # Alias the base class' method 
  alias :run_super :run

  def run(entry_class = 'Entry')
    entries = []
    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|
      
      entry = entry_class.constantize.new
      
      # Use exception handling to weed out bad entries
      begin
        # Don't process comments
        if line.index("#") == 0
          print "Skipping comment on line #%s: %s" % [line_no, line]
        else
          result = entry.parse_line(line)
          if result
            entries << entry
          end
        end
      rescue Exception
        # TODO: This is one of the places we want to have a "help me" with the database,
        # Beast migration style (MMA 11.18.2011)
        print "Could not parse line #%s: %s" % [line_no, line]
      end
    end
    return entries
  end
end