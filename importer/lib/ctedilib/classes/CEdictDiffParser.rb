class CEdictDiffParser
  
  @config_filename
  @last_config
  @counter
  @diff_filename
  @written_to_file
  @file_exist
    
  @added_lines
  @removed_lines
  @config
  
  ### Class Constructor
  def initialize (new_dict_file, yaml_file)
    # File related toegther with the hash object of the last configuration
    @config_filename = Rails.root.join("config/cedict_config/#{yaml_file}").to_s
    @last_config = nil
    @counter = 0
    @diff_filename = nil
    @written_to_file = false
    @file_exist = File.exist? @config_filename
    
    # Statistic
    @added_lines = []
    @removed_lines = []
    
    # Read the last configuration if there is one.
    if @file_exist
     yaml_obj = YAML.load_file @config_filename
     @counter = yaml_obj.length
     @last_config = yaml_obj[@counter-1][@counter-1]
    end
    
    # Preparation for the current configuration
    @config = {}
    @config["filename"] = new_dict_file
    @config["date"] = DateTime.now
    @config["added"] = 0
    @config["removed"] = 0
    @config["changed"] = 0
    
    return self
  end
  
  ### Run method, when this is run, it will populate the added and removed array and then
  ### return with the hash containing line, ready to be parsed by the CEdictParser.
  def run
    # Try to get the diff_filename and open it for the comparison
    # And if this is the first time the import is run, there wont be any diff_filename whatsoever, so we loop from the file directly =)
    get_diff_from_previous_file unless (@diff_filename != nil) && !(@diff_filename == "")
    
    # If this is run for the first time, we are not gonna have the diff_file, so
    # What we are doing is to read all of the lines, and put them under "added" section
    if (File.file? @diff_filename)
      # Parse the diff file
      parse_diff 
    else
      # We read it from the file directly
      parse_file
    end
    
    # Return with the hash representation of the difference
    return self.line_diff
  end
  
  ### Return with the hash :added, :removed and :changed containing line
  ### in CEdictParser-friendly format
  def line_diff
    return { :added => @added_lines, :removed => @removed_lines }
  end
  
  ### parse the file directly from the source as this is the first
  ### added action. 
  def parse_file
    filename = full_path_from_edict_file(@config["filename"])
    ### Get all the line into memory
    file_obj = File.new(filename, "r")
    file_obj.each do |line|
      @added_lines.push line
    end
  end
  
  ### Parse the diff_filename diff' result file and
  ### categorising them based on whether they should be added or removed
  def parse_diff
    # If there is a file, do some initialisation
    file_obj = File.new(@diff_filename, "r")
    temp_a = temp_r = nil 
    
    # Then for each line found on the diff file
    # Do some bucket-ing between added and removed
    file_obj.each do |line|
      
      line = line.chomp!
      if line.match $regexes[:diff_info]
        # We are doing this 'diff' block-by-block 
        # As initially it is planned to cross-reference the added/removed right per block 
        # as it is easier and cheaper. Well, this structure is retained if we decided to have 
        # 'extra' action when we finish with a 'diff' block
        # Pushing the temporary 'lines' back to where it should belong
        @added_lines.concat temp_a unless temp_a == nil
        @removed_lines.concat temp_r unless temp_r == nil
        
        # reset the temporary variable
        temp_a = []
        temp_r = []
      end #End if line.match $regexes[:diff_info]
      
      processed_line = ""
      if line.start_with? ">", "<"
        sign = line.slice!(0).chr
        processed_line = line.strip.chomp
        
        # Get me out of here, comment is useless for this.
        next unless !processed_line.start_with? "#" 
          
        if sign == ">"
          # Should be put under added temporarily
          temp_a.push processed_line
        elsif sign == "<"
          # Should be put under removed temporarily
          temp_r.push processed_line
        end
      end #End if line.start_with? ">", "<"
    end #End for-each
  end
  
  ### This method will dump the new operation back to the YAML file.
  ### together with the information/meta like the date,
  ### how many has changed, added or removed. 
  def dump
    # Don't try to log it twice.
    raise 'This Difference has been logged into the config file. Please don\'t try to log it again.' unless !@written_to_file

    # Some preparation for consistencies in the numbers.
    yaml_obj = nil
    added_config = { @counter => @config }
    
    # If this is the first time ever logging the operation, get the dict inside the array.
    # If not, push the dict into the back of the array.
    if @file_exist
      yaml_obj = YAML.load_file @config_filename
      yaml_obj.push added_config
    else
      yaml_obj = [added_config]
    end
          
    File.open @config_filename, 'w' do |out|
      YAML.dump yaml_obj, out
    end
    @written_to_file = true
  end
  
  ### This method will try to generate the diff file
  ### comparing the new edict file from the old one.
  ### This method only needed to run once in every "import" operation.
  def get_diff_from_previous_file
    result = ""
    if (@diff_filename == nil)
      # Get both the filename for logging.
      previous_filename = self.full_path_from_edict_file(self.old_filename)
      current_filename = self.full_path_from_edict_file(@config["filename"])

      # Only do the diff if both files actually exist
      if (File.file? previous_filename) && (File.file? current_filename)
        # We want to add the timestamp as part of the diff filename
        timestamp = DateTime.now.strftime "%d%m%y-%H%M"
        result = Rails.root.join("data/cedict/migration_history/diff#{timestamp}.txt").to_s
        `diff '#{previous_filename}' '#{current_filename}' > '#{result}'`
      end
    end
    
    @diff_filename = result
    return @diff_filename
  end
  
  ### Handy method for returning the full path of an cedict file
  def full_path_from_edict_file(filename="")
    return Rails.root.join("data/cedict/#{filename}").to_s
  end
  
  ### This method will sync the number of added, removed and changed with the
  ### length of each of those array.
  def sync_statistic
    @config["added"] = @added_lines.length
    @config["removed"] = @removed_lines.length
    @config["changed"] = 0
  end
  
  def diff_filename
    return @diff_filename
  end
  
  def added
    return @added_lines
  end
  
  def removed
    return @removed_lines
  end
  
  def update_data_with (new_added, new_changed, new_removed)
    @config["added"] = new_added.length
    @config["removed"] = (new_removed) ? new_removed.length : 0
    @config["changed"] = (new_changed) ? new_changed.length : 0
  end
    
  def old_filename
    return @last_config["filename"] unless @last_config == nil
    return ""
  end
  
end