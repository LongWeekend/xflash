require 'YAML'

class TagsBaseConfiguration
  
  ### Class Constructor
  def initialize (file_to_yaml_file, metadata_key="")
    @configuration = YAML.load_file(file_to_yaml_file)
    @configuration = @configuration[metadata_key] unless ((metadata_key == nil)||(metadata_key.strip().length()<=0))
    
    if (@configuration == nil)
      raise "Sorry I have to throw an exception as the metadata key (second parameter) supplied is not found in the file"
    end
    return self
  end
  
  def file_name
    return @configuration["file_name"]
  end

end