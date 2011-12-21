#### PARSER BASE CLASS #####
class Parser

  include DatabaseHelpers
  include ImporterHelpers
  require 'nokogiri'

  ### Class Constructor
  #####################################
  def initialize(file_name, from=0, to=0, category_tags_list=[])
    @from_rec_no = from # support from/to
    @to_rec_no = to # support from/to
    @source_file = File.open(file_name, 'r')
    @source_file_name = file_name
    @source_file_ext =File.extname(file_name)
    if @source_file_ext.downcase ==".xml"
      # XML mode, read in immediately and close stream
      @source_xml = Nokogiri::XML(@source_file, nil, 'UTF-8')
      @source_data_object = @source_xml # Should be defined later
      @source_file.close
    else
      # Txt files, open stream and close later!
      @source_data_object = @source_file
    end
    # Category tags added via the command line
    @category_tags_array = (category_tags_list.nil? ? [] : category_tags_list.split(",").flatten)
  end
  
  ### Class Constructor
  #####################################
  def initialize(lines, from=0, to=0)
    # Call the other initializer if "lines" is a string (=filename)
    if lines.kind_of? String
      initialize(lines, from, to, [])
      return
    end
  
    @from_rec_no = from # support from/to
    @to_rec_no = to # support from/to
    @source_file = nil
    @source_file_name = nil
    @source_file_ext = nil
    @source_data_object = lines
    
    # Category tags added via the command line
    @category_tags_array = []
  end
  
  # DESC: Abstract method, call 'super' from child class to use built-in functionality
  def run(&block)
    cache_data = {}
    loop_count = 1

    ## Sexy "import data reader" loop
    ###################################
    tickcount("Processing import data records") do
      @source_data_object.each do |rec|
        # Supports record skipping
        if loop_count >= @from_rec_no && (loop_count <= @to_rec_no || @to_rec_no == 0)
          block.call(rec, loop_count, cache_data)
        end
        loop_count = noisy_loop_counter(loop_count, 0, 1000, item_name="records")
        if loop_count > @to_rec_no && @to_rec_no != 0
          prt "Exited loop at line #{loop_count}"
          break
        end
      end
    end
    return cache_data
  end

end
