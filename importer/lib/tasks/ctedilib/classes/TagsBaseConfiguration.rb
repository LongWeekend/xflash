require 'YAML'

class TagsBaseConfiguration
  
  ### Class Constructor
  def initialize (file_to_yaml_file)
    @configuration = YAML.load_file(file_to_yaml_file)
    
    #p 'Initialised'
    p @configuration
    return self
  end
  
end