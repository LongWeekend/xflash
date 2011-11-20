#### CEDICT PARSER #####
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
    
    # These store entries that are redirects, but also have content in their own right
    @erhua_variant_entries = []
    @variant_entries = []
    
    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|
      
      entry = CEdictEntry.new
      
      # Use exception handling to weed out bad entries
      begin
        result = entry.parse_line(line)
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
      rescue EntryParseException => e
        prt "Could not parse line #%s: %s" % [line_no, line]
        prt "Message: %s\n" % e.message
        prt "Backtrace: %s\n" % e.backtrace.inspect
      rescue ToneParseException => e
        prt "Could not parse line #%s: %s" % [line_no, line]
        prt "Message: %s\n" % e.message
      rescue MeaningParseException => e
        prt "Could not parse line #%s: %s" % [line_no, line]
        prt "Message: %s\n" % e.message
      end
    end
    
    # Now handle any funkiness with variants
    
    return entries
  end
  
  def merge_references_into_base_entries(base_entries,ref_entries)
    i = 0
    total = ref_entries.count
    
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
          base_entry.add_inline_entry_to_meanings(inline_entry)
          
          # We can break from this loop here because we only match 1-to-1
          break
        end
      end
    end
    return base_entries
  end
  
  # Semi-private method to mux together variant & regular entries (goes both ways)
  def _mux_variant_entries_and_base_entries(base_entries,variant_entries,base_into_variant = false)
    matched = 0
    total = variant_entries.count
    
    # Loop through the list of all erhua entries
    variant_entries.each do |variant_entry|
      inline_variant_entry = Entry.parse_inline_entry(variant_entry.variant_of)
      base_entries.each do |base_entry|
        if base_entry.inline_entry_match?(inline_variant_entry)
          if base_into_variant
            variant_entry.add_base_entry_to_variant_meanings(base_entry)
          else
            base_entry.add_variant_entry_to_base_meanings(variant_entry)
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
    return variant_entries, base_entries
  end
  
  def add_variant_entries_into_base_entries(base_entries,variant_entries)
    # Gah I hate the double return here, but it kinda works well MMA
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,false)
    return base
  end

  def add_base_entries_into_variant_entries(variant_entries,base_entries)
    # Gah I hate the double return here, but it kinda works well MMA
    var, base = _mux_variant_entries_and_base_entries(base_entries,variant_entries,true)
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
