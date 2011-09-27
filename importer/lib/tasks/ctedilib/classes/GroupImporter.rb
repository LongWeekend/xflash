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
  
  def tear_down_groups
    # Try to connect to the database first
    connect_db
    
    # Execute some of the tearing down script
    $cn.execute("TRUNCATE TABLE group_tag_link")
    $cn.execute("TRUNCATE TABLE groups_staging")
    $cn.execute("TRUNCATE TABLE card_tag_link")
    $cn.execute("TRUNCATE TABLE tags_staging")
  end
  
  def run
    # Tearing down the existing groups and tags first
    tear_down_groups
        
    # Try opening the connection to the database
    connect_db
    
    # Get the first root to traverse to which is the values of the "study_sets" key on the yml file.
    # with the owner as -1 to mark that as the root of all groups.
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
            insert_tag(metadata, group_id)
      end
    end # End if to ensure the values is type-of Hash
  end
  
  def insert_tag(metadata, group_id)
    configuration = TagConfiguration.new(metadata[:file], metadata[:metadata_key])
    results = nil
    # if there is a source needed to be parse first
    # parse that first
    if (configuration.file_name != nil)
      test_file_path = File.dirname(__FILE__) + configuration.file_name
      # Get the designated parser for the tag 
      parser = configuration.file_parser.constantize.new(test_file_path)
      results = parser.run()
    end

    # Get the class of the importer used
    # and try to constantize / instantiate it from there
    importer = configuration.file_importer.constantize.new(results, configuration)
    inserted_tag_id = importer.import()
    
    # Link the tag to the group.
    link_tag_group(group_id, inserted_tag_id)
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
  
  def link_tag_group(group_id, tag_id)
    # Try to connect to the database first
    connect_db
    
    # Prepare the insert statement and execute it.
    insert_query = "INSERT INTO group_tag_link(group_id, tag_id) VALUES(#{group_id}, #{tag_id})"
    $cn.execute(insert_query)
  end
  
end