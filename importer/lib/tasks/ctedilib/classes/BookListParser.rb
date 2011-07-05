#### CEDICT PARSER #####
class BookListParser < Parser

  # Alias the base class' method 
  alias :run_super :run

  def run
    entries = []
    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|
      
      entry = BookEntry.new
      
      # Use exception handling to weed out bad entries
      begin
        # Don't process comments
        if line.index("#") == 0
          print "Skipping comment on line #%s: %s" % [line_no, line]
        else
          entry.parse_line(line)
          entries << entry
        end
      rescue Exception
        print "Could not parse line #%s: %s" % [line_no, line]
      end
    end
    return entries
  end

  #---------------------------------------------------

  # THIS MIGHT BE USEFUL FOR LATER - CFLASH?? in case we get other word lists from other sources
  # DESC: Gets headwords/readings from unmatched JLPT file and collates with matching entries from second file
  def run_collate_unmatched_jlpt(new_fn, umatched_fn)

    unmatched_count=0
    err_count=0
    out_count=0

    new_file = File.open(new_fn)
    new_data_headword_idx = {}
    new_file.each do |line|
      next if line.index("/").nil?
      line.strip!
      headword_str = self.class.get_headwords(line).join($delimiters[:edict2_headwords])
      reading_str = self.class.get_readings(line).join($delimiters[:edict2_readings])
      # replace reading with headword if it contains zenkaku parens
      if reading_str.scan("（").size > 0
        new_reading_str = headword_str
        line.gsub!("["+reading_str+"]", "["+new_reading_str+"]")
      end
      new_data_headword_idx[headword_str] = line
    end

    # setup out file for unmatched entries
    errors_fn = umatched_fn.gsub("_unmatched.txt","") + "_unmatchable.txt"
    File.delete(errors_fn) if File.exist?(errors_fn) # delete old tmp files
    errorf= File.open(errors_fn, "w")

    # setup out file for matches
    out_fn = umatched_fn.gsub("_unmatched.txt","") + "_rematched.txt"
    File.delete(out_fn) if File.exist?(out_fn) # delete old tmp files
    outf = File.open(out_fn, "w")

    # Call run's super to process loop for us
    run_super do |line, line_no, cache_data|

      line.strip!
      unmatched_count+=1

      if line.index("/").nil?
        prt "Empty entry found for #{headword_str}"
        err_count+=1
        errorf.write(line +"\n")
        next
      end

      headword_str = self.class.get_headwords(line).join($delimiters[:edict2_headwords])
      reading_str = self.class.get_readings(line).join($delimiters[:edict2_readings])

      if reading_str.scan($regexes[:not_kana_nor_basic_punctuation]).size > 0
        # Invalid characters found in reading
        prt "Invalid characters found in reading #{reading_str}"
        err_count+=1
        errorf.write(line +"\n")
      elsif new_data_headword_idx.has_key?(headword_str)
        # Output matched lines
        out_count+=1
        new_line = new_data_headword_idx[headword_str]
        outf.write(new_line +"\n")
      else
        # Headword is not in new file
        prt "Entry not found for #{headword_str}"
        err_count+=1
        errorf.write(line +"\n")
      end
    end

    prt "Here are the results..."
    prt_dotted_line
    prt "Total entries retried        : #{unmatched_count}"
    prt "Total entries matched        : #{out_count}"
    prt "Total entries unable to match: #{err_count}"
    prt ""

    errorf.close
    outf.close
    
  end

end