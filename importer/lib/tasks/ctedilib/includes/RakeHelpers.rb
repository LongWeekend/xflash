module RakeHelpers

  # Fetch "to" command line or set to default
  def get_cli_break_point
    if ENV.include?("to") && ENV['to'] && ENV['to'].to_i > 0
      return ENV['to'].to_i
    else
      return $options[:default_break_point]
    end
  end

  # Empty tables or not
  def get_cli_empty_tables
    return ( ENV.include?("kill") && ENV['kill'] )
  end

  # Silent or Not
  def get_silent
    return ( ENV.include?("silent") && ENV['silent'] )
  end

  # Fetch "start" from command line or set to default
  def get_cli_start_point
    if ENV.include?("from") && ENV['from'] && ENV['from'].to_i > 0
      return ENV['from'].to_i
    else
      return 1
    end
  end

  # Fetch "type" from command line or set to default
  def get_cli_type
    if ENV.include?("type") && ENV['type']
      return ENV['type'].to_s
    else
      return ""
    end
  end

  # Fetch "force" command from or set default
  def get_cli_forced
    if ENV.include?("force") && ENV['force']
      return true
    else
      return false
    end
  end

  # Fetch regex from command line or set to default
  def get_cli_regex
    if ENV.include?("rex")
      if ENV['rex'].scan(/\/.+\//)
        rex = Regexp.new ENV['rex'].scan(/\/(.+)\//).to_s
      else
        rex = ENV['rex']
      end
    else
      rex = $regexes[:antonym]
    end
    return rex
  end

  # Get debug directive from command line
  def get_cli_debug
    if ENV.include?("debug")
      if ENV["debug"] == "false" || ENV["debug"] == "0"
        $options[:verbose] = false
      else
        $options[:verbose] = true
      end
    else
      # default is on!
      $options[:verbose] = true
    end
  end

  # Get extra tags specified at the command line
  def get_cli_tags
    if ENV.include?("add_tags") && ENV['add_tags']
      return ENV['add_tags'].downcase.split(',').collect {|s| s.strip }
    else
      return nil
    end
  end
  
end