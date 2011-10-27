class InlineEntry < Entry

  def parse_line(line = "")
    killer_regex = /(\w+)\|{0,1}(\w*)(\[([a-zA-Z0-5\s]+)\]){0,1}/
    match_found = false
    line.scan(killer_regex) do |inline_entry|
    
      # we only want the first result from the regex, break out of this loop if we have it
      break if match_found
      
      # entry #2 contains the pinyin with the hard brackets, but we need that capture in the regex
      @headword_trad = (inline_entry[0] != "") ? inline_entry[0] : nil; 
      @headword_simp = (inline_entry[1] != "") ? inline_entry[1] : nil;
      @pinyin        = (inline_entry[3] != "") ? inline_entry[3] : nil;
      match_found = true
    end
    return line
  end

end