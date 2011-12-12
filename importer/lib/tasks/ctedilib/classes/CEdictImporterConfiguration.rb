class CEdictImporterConfiguration
  
  ### Class Constructor
  def initialize (yaml_file, new_dict_file)
    # File related toegther with the hash object of the last configuration
    @config_filename = File.dirname(__FILE__) + "/../../../../config/cedict_config/#{yaml_file}"
    @last_config = nil
    @counter = 0
    @file_exist = File.exist? @config_filename
    
    # Statistic
    @added = 0
    @removed = 0
    @changed = 0
    
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
  
  def dump
    # Cause this will add to the very back of the array
    yaml_obj = nil
    added_config = { @counter => @config }
    
    if @file_exist
      yaml_obj = YAML.load_file @config_filename
      yaml_obj.push added_config
    else
      yaml_obj = [added_config]
    end
          
    File.open @config_filename, 'w' do |out|
      YAML.dump yaml_obj, out
    end
  end
  
  def get_diff_result_with_previous_file
    previous_filename = File.dirname(__FILE__) + "/../../../../data/cedict/" + self.old_filename
    current_filename = File.dirname(__FILE__) + "/../../../../data/cedict/" + @config["filename"]
    
    # Only do the diff if both files actually exist
    result = nil
    if (File.file? previous_filename) && (File.file? current_filename)
      timestamp = DateTime.now.strftime "%d%m%y-%H%M"
      result = File.dirname(__FILE__) + "/../../../../data/cedict/migration_history/diff#{timestamp}.txt"
      `diff '#{previous_filename}' '#{current_filename}' > '#{result}'`
    end
    
    return result
  end
  
  def add_number_of_added (n)
    @added += n
  end
  
  def add_number_of_changed (n)
    @changed += n
  end
  
  def add_number_of_removed (n)
    @removed += n
  end
  
  def added
    return @added
  end
  
  def changed
    return @changed
  end
  
  def removed
    return @removed
  end
  
  def old_filename
    return @last_config["filename"] unless @last_config == nil
    return ""
  end
  
end