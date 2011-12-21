class CEdictParser < Parser

  @reference_only_entries
  @variant_only_entries

  # TODO: MMA is this necessary?
  # Alias the base class' method 
  alias :run_super :run

  def run
    entries = []
    # These store entries that are simply redirects
    @reference_only_entries = []
    @variant_only_entries = []
    @human_exception_handler = HumanParseExceptionHandler.new
    
    # These store entries that are redirects, but also have content in their own right
    @erhua_variant_entries = []
    @variant_entries = []
    
    # Use this for when we have an exception and want to retry
    @rescued_line = false
    
    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|
      
      entry = CEdictEntry.new
      # Use exception handling to weed out bad entries
      begin
      
        # this is the normal behavior, we are just using the normal line
        if @rescued_line == false
          result = entry.parse_line(line)
        else
          result = entry.parse_line(@rescued_line)
          @rescued_line = false
        end
        if result
          # Handle classifier expansion
          entry.add_classifier_to_meanings
          
          # Determine which array to put it in based on its type
          if entry.is_only_redirect?
            if entry.has_variant?
              @variant_only_entries << entry
            else
              @reference_only_entries << entry
            end
          else
            if entry.has_variant?
              if entry.is_erhua_variant?
                @erhua_variant_entries << entry
              else
                @variant_entries << entry
              end
            else
              entries << entry
            end
          end
        end
      rescue Exception => e
        if @rescued_line == false
          @rescued_line = @human_exception_handler.get_human_result_for_string(line,e.class.name)
          if @rescued_line
            retry
          else
            prt "Could not parse line #%s: %s (msg: %s)" % [line_no, line,e.message]
          end
        else
          prt "Rescued line was not false but exception caught -- this means we may have infinite loop!"
          @rescued_line == false
        end
      end
    end
    
    # Now handle any funkiness with variants
    return entries
  end
  
  def unmerge_references_from_base_entries(base_entries,ref_entries)
    return self._relationship_reference_with_base_entries(base_entries,ref_entries,false)
  end
  
  def _relationship_reference_with_base_entries(base_entries,ref_entries,merge=true)
    i = 0
    total = ref_entries.count
    affected_entries = []
    
    ref_entries.each do |ref_entry|
      # Get the right reference (reference or variant)
      ref = ref_entry.references[0] if ref_entry.references.count > 0
      ref = ref_entry.variant_of if (ref_entry.has_variant? or ref_entry.is_erhua_variant?)
      inline_entry = Entry.parse_inline_entry(ref)
      
      # Now loop through the base entries and match it
      base_entries.each do |base_entry|
        # Now merge & remove if the cards match (so we don't loop over it again)
        if base_entry.inline_entry_match?(inline_entry)
          i = i + 1
          # This can take some time, so print out a log every 10 entries
          if ((i % 10) == 0)
            prt "Matched %d of %d reference entries" % [i, total]
          end
          
          if (merge)
            base_entry.add_ref_entry_into_meanings(ref_entry)
          else
            base_entry.rem_ref_entry_from_meanings(ref_entry)
          end
          affected_entries << base_entry
          
          # We can break from this loop here because we only match 1-to-1
          break
        end
      end
    end
    
    # Returning only the entries which reference have been added.
    return affected_entries
  end
  
  def merge_references_into_base_entries(base_entries,ref_entries)
    return self._relationship_reference_with_base_entries(base_entries,ref_entries,true)
  end
  
  # Semi-private method to mux together variant & regular entries (goes both ways)
  def _mux_variant_entries_and_base_entries(base_entries,variant_entries,base_into_variant = false,add = true)
    matched = 0
    total = variant_entries.count
    muxed_base_entries = []
    muxed_variant_entries = []
    
    # Loop through the list of all erhua entries
    variant_entries.each do |variant_entry|
      inline_variant_entry = Entry.parse_inline_entry(variant_entry.variant_of)
      base_entries.each do |base_entry|
        if base_entry.inline_entry_match?(inline_variant_entry)
          if base_into_variant
            muxed_variant_entries << variant_entry
            variant_entry.add_base_entry_to_variant_meanings(base_entry) if add
            variant_entry.rem_base_entry_from_variant_meanings(base_entry) if !add
          else
            muxed_base_entries << base_entry
            base_entry.add_variant_entry_to_base_meanings(variant_entry) if add
            base_entry.rem_variant_entry_from_base_meanings(variant_entry) if !add
          end
          matched = matched + 1
          
          # This can take some time, so print out a log every 100 entries
          if ((matched % 100) == 0)
            prt "Cross-referenced %d of %d entries" % [matched, total]
          end
          
          # Since we found a match, there's no reason to keep looping through this.
          break
        end
      end
    end
    return muxed_variant_entries, muxed_base_entries
  end
  
  def add_variant_entries_into_base_entries(base_entries,variant_entries)
    # Gah I hate the double return here, but it kinda works well MMA
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,false,true)
    return base
  end

  def add_base_entries_into_variant_entries(variant_entries,base_entries)
    # Gah I hate the double return here, but it kinda works well MMA
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,true,true)
    return var
  end
  
  def rem_variant_entries_from_base_entries(base_entries,variant_entries)
    # I just knew that we can do double return...
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,false,false)
    return base
  end
  
  ### This is'nt needed as the variant is to be deleted anyway.
  def rem_base_entries_from_variant_entries(variant_entries,base_entries)
    # I just knew that we can do double return...
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,true,false)
    return var
  end
  
  def reference_only_entries
    @reference_only_entries
  end

  def variant_only_entries
    @variant_only_entries
  end
  
  def erhua_variant_entries
    @erhua_variant_entries
  end
  
  def variant_entries
    @variant_entries
  end
end
