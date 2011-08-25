require 'YAML'

class TagsBaseConfiguration
  
  ### Class Constructor
  def initialize (yaml_file, metadata_key="")
    path_to_yaml_file = File.dirname(__FILE__) + "/../../../../config/tags_config/#{yaml_file}"
    @configuration = YAML.load_file(path_to_yaml_file)
    @configuration = @configuration[metadata_key] unless ((metadata_key == nil)||(metadata_key.strip().length()<=0))
    
    if (@configuration == nil)
      raise "Sorry I have to throw an exception as the metadata key (second parameter) supplied is not found in the file"
    end
    return self
  end
  
  def file_name
    return @configuration["file_name"] 
  end
  
  def file_dump_trace
    return @configuration["file_dump_trace"] unless (@configuration["file_dump_trace"] == nil)
    return false
  end
  
  def tag_name
    return @configuration["tag_name"] 
  end
    
  def tag_type
    return @configuration["tag_type"]
  end
  
  def short_name
    return @configuration["short_name"]
  end
  
  def description
    return @configuration["description"]
  end
  
  def source_name
    return @configuration["source_name"]
  end
  
  def source
    return @configuration["source"]
  end
  
  def visible
    return @configuration["visible"]
  end
  
  def parent_tag_id
    return @configuration["parent_tag_id"]
  end
  
  def force_off
    return @configuration["force_off"]
  end
  
  def to_s
  	# Get the name of the class in string.
    class_name_str = self.class().to_s()
    
    # Concatenate the entire class instance variables and
    # its values.
    ivars = "["
    self.instance_variables.each do |var|
    	val = self.instance_variable_get(var)
    	if (val.kind_of?(Array))
    		val = val.join("//")
    	end
		ivars << var + ": " + val.to_s() + "\n"
    end
    ivars[ivars.length-1] = "]"
    
    # Constructs the string and return it back
    result = "<%s: 0x%08x>\n%s\n\n"
  	return result % [class_name_str, self.object_id, ivars]
  end

end