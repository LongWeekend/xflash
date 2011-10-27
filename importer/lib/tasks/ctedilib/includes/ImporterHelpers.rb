module ImporterHelpers
  
  def get_pinyin_unicode_for_reading(readings="", leave_spaces = false)
    ## TODO: Think about the tone-5
    ## http://en.wikipedia.org/wiki/Pinyin#Tones  
    # Only runs if the reading actually has something
    if ((readings) && (readings.strip().length() > 0))
      # Variable to persist the final result.
      result = ""
      
      # sometimes some sources use "u:" <u with collon>
      # but some other uses "v" character as 
      # it is not used in the pinyin
      umlaut_regex = /[uU]:|v/
      readings.gsub!(umlaut_regex) do |s|
        [252].pack('U*')
      end
      
      # Loop through the individual readings.
      readings.split($delimiters[:cflash_readings]).each do | reading |
        
        # Just to get the tone in string (even if it should be a number)
        tone = ""
        tone << reading.slice(reading.length()-1)
        if reading == "r5"
          # Exception for the 'r' sound and the tone will always be '5'
          # Just concatinate with the result
          result << "r"
        elsif reading == "xx5"
          #ignore these BS ones
        elsif reading == "m2" or reading == "m4"
          result << reading
        elsif (tone.match($regexes[:pinyin_tone]))
          found_diacritic = false
          # Get the reading without the number (tone)
          reading = reading.slice(0, reading.length()-1).downcase()
          
          vocals = reading.scan($regexes[:vocal])
          num_of_vocal = vocals.length
           
          vocal = ""
          if (num_of_vocal == 1)
            # Take the vocal, directly if there is only 1 vocal.
            vocal = vocals[0]
          else
            vocal = reading.scan($regexes[:diacritic_vowel1])[0]
            
            vocal = reading.scan($regexes[:diacritic_vowel2])[0] unless vocal
            if (vocal)
              # Get the "o" in the 'ou' scan.
              vocal = vocal[0].chr()
            end
            
            # If everything else fails, get the second vocal.
            vocal = vocals[1] unless vocal
          end
          
          if ((vocal) && (vocal.strip().length() > 0))
            diacritic = get_unicode_for_diacritic(vocal, tone)
            result << reading.sub(vocal, diacritic)
          else
            puts "The vocal to be sub with its diacritic is not found for readings: %s, vocals: %s, reading: %s and tone: %s" % [readings, vocals, reading, tone]
          end
        elsif (reading.match($regexes[:one_capital_letter]))
          # If there is a single letter reading, 
          # it is usually either an acronym or a single letter. (like ka-la-o-k) - Karaoke
          # Put them just as is
          result << reading
        elsif (reading.match($regexes[:pinyin_separator]))
          result << " %s " % [reading]
        else
          # Give the feedback if we dont know what to do
          # This should be a very rare cases. (Throw an exception maybe?)
          puts "There is no tone: %s defined for pinyin reading: %s in readings: %s" % [tone, reading, readings]
        end
        
        # Add a space if we were asked to
        result << " " if leave_spaces
      end
      return result.strip
    end

    # Back with nothing if there is no reading supplied
    return ""
  end
  
  def get_unicode_for_diacritic(vocal, tone)
    if vocal == "ü"
      vocal = "v"
    end
    the_vocal_sym = (vocal + tone).to_sym()
    return [$chinese_reading_unicode[the_vocal_sym]].pack('U*')
  end
  
  def fix_unicode_for_tone_3(pinyin)
    # GSUB accepts hashes on Ruby 1.9 but not 1.8.  We have it categorized in in additions as hash_gsub
    return pinyin.hash_gsub(/[ăĕĭŏŭ]/,{'ă'=>'ǎ','ĕ'=>'ě','ĭ'=>'ǐ','ŏ'=>'ǒ','ŭ'=>'ǔ'})
  end

  def prt_dotted_line(txt="")
    prt "---------------------------------------------------------------------#{txt}"
  end
  
  # <cf_style>Rockin it!</cf_style> - count run time of  bounded block and output it
  def tickcount(id="", verbose=$options[:verbose], tracking=false)
    from = Time.now
    prt "\nSTART: " + (id =="" ? "Anonymous Block" : id) + "\n" if verbose
    yield
    to = Time.now
    # track time stats?
    if tracking
      $ticks = {} if !$ticks
      if !$ticks[id]
        $ticks[id] = {}
        $ticks[id][:times] = 1
        $ticks[id][:total] = Float(to-from)
      else
        $ticks[id][:times] = $ticks[id][:times] + 1
        $ticks[id][:total] = ( ($ticks[id][:total] + Float(to-from)) / $ticks[id][:times] )
      end
      $ticks[id][:last] = {:from => from, :to => to}
    end
    if verbose
      prt "END: " + (id =="" ? "Anonymous Block" : id) + " time taken: #{(to-from).to_s} s"
      prt_dotted_line
    end
    return true
  end
  
  # Sourced from ThinkingSphinx pluing by Pat Allan (http://freelancing-god.github.com)
  # A fail-fast and helpful version of "system"
  def system!(cmd)
    unless system(cmd)
      raise <<-SYSTEM_CALL_FAILED
  The following command failed:
    #{cmd}

  This could be caused by a PATH issue in the environment of Ruby.
  Your current PATH:
    #{ENV['PATH']}
SYSTEM_CALL_FAILED
    end
  end

  ## Append text to file using sed
  def append_text_to_file(text, filename)
    `sed -e '$a\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end

  ## Prepend text to file using sed
  def prepend_text_to_file(text, filename)
    `sed -e '1i\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end

  # "puts" clone that outputs nothing when verbose mode is false!
  def prt(str)
    puts(str) if $options[:verbose]
  end

  # exit quickly
  def ex
    exit
  end
  
  # Removes string and any duplicate spaces
  def replace_no_gaps(str, replace, with)
    return str.gsub(replace, with).gsub(/ +/, ' ').strip
  end

  def exit_with_error(error, dump_me=nil)
    puts "ERROR! " + error
    pp dump_me if dump_me
    exit
  end
  
  # Loop counter to count aloud for you!
  def noisy_loop_counter(count, max=0, every=1000, item_name="records", atomicity=1)
    count +=1
    if count % every == 0 || (max > 0 && count == max)
      prt "Looped #{count/atomicity} #{item_name}" if count%atomicity == 0 ## display count based on atomicity
    end
    return count
  end

  # Returns source file name specified at CLI or dies with error
  def get_cli_source_file
    if !ENV.include?("src") || ENV['src'].size < 1
      exit_with_error("Source file not found.", ENV)
    else
      return ENV['src'].to_s
    end
  end

  # Returns specified attrib from command, dies with error if fail_if_undefined == true
  def get_cli_attrib(attrib, fail_if_undefined=false, bool=false)
    if ENV.include?(attrib)
      if bool
        return (ENV[attrib] ==0 || ENV[attrib] == "true" ? true : false)
      else
        return ENV[attrib]
      end
    elsif fail_if_undefined
      exit_with_error("Command line attribute not found #{attrib} !", ENV) if fail_if_undefined
    end
  end

end
