class GroupImporter
  
  include ImporterHelpers
  
  ### Class Constructor
  def initialize (yaml_file)
    path_to_yaml_file = File.dirname(__FILE__) + "/../../../../config/groups_config/#{yaml_file}"
    @configuration = YAML.load_file(path_to_yaml_file)
    @counter = 0
    
    if (@configuration == nil)
      raise "Sorry I have to throw an exception as the file seems broken"
    end
    return self
  end
  
  def insert_link
    insert_query = "INSERT INTO group_tag_link(group_id, tag_id) VALUES(%s, %s)"
  end
  
  def insert_query
    insert_query = "INSERT INTO groups_staging(group_name, owner_id, recommended) VALUES('%s', %s, %s)"
  end
  
  def tear_down_groups
    # Try to connect to the database first
    connect_db
    
    # Execute some of the tearing down script
    $cn.execute("TRUNCATE TABLE groups_staging")
    $cn.execute("TRUNCATE TABLE group_tag_link")
  end
  
  def run
    connect_db
    first_root = @configuration["study_sets"]
    insert_group_or_tag(first_root, -1)
    
  end
  
  
  def insert_group_or_tag(values, owner_id)
    
    # Ensure that we only have parsed data processed
    if values.kind_of? Hash
      
      metadata = Hash.new()
      group_id = owner_id
      # Traverse through its keys
      values.each do |key, value|
        if key == "name"
          #Insert it as group
          group_id = insert_group(value, owner_id)
        elsif key == "file" || key == "metadata_key"
          key_sym = key.to_sym()
          metadata[key_sym] = value
        else
          # Recurse as it might still has nested groups or tags
          insert_group_or_tag(value, group_id)
        end
      end # In the end of traversing the key and value
      
      if metadata[:file] != nil && metadata[:file].strip().length > 0 &&
         metadata[:metadata_key] != nil && metadata[:metadata_key].strip().length > 0
         # If body and insert it as tag
            insert_tag(metadata)
      end
      
    end # End if to ensure the values is type-of Hash
  end
  
  def insert_tag(metadata)
    configuration = TagsBaseConfiguration.new(metadata[:file], metadata[:metadata_key])

    test_file_path = File.dirname(__FILE__) + configuration.file_name
    parser = CSVParser.new(test_file_path)
    results = parser.run()

    importer = Tags800WordsImporter.new(results, configuration)
    importer.import()
  end
    
  def insert_group(value, owner_id)
    # Make sure there is connection to the database
    connect_db
    # If the group is recommended, put a fixnum 1 in the name value as array
    recommended = 0
    name = ""
    if value.kind_of? Array
      name = value[0]
      recommended = value[1]
    else
      name = value
    end
    # Inserting to the groups table
    insert_query = "INSERT INTO groups_staging(group_id, group_name, owner_id, recommended) VALUES(%s,'%s', %s, %s)"
    inserted_group_id = @counter
    @counter = @counter+1
    $cn.execute(insert_query % [inserted_group_id, name, owner_id, recommended])
          
    return inserted_group_id
    #raise "Failed inserting to the group_staging with the group_name: #{group_name}, owner_id:#{owner_id} and recommended: #{recommended}\nInsert query: #{insert_query}\nSelect Query: #{select_query}"
  end
  
end