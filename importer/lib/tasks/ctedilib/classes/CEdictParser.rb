#### CEDICT PARSER #####
class CEdictParser < Parser

  @reference_only_entries
  @variant_only_entries

  # TODO: MMA is this necessary?
  # Alias the base class' method 
  alias :run_super :run

  def run
    entries = []
    @reference_only_entries = []
    @variant_only_entries = []
    # Call 'super' method to process loop for us
    super do |line, line_no, cache_data|
      
      entry = CEdictEntry.new
      
      # Use exception handling to weed out bad entries
      begin
        # Don't process comments
        if line.index("#") == 0
          prt "Skipping comment on line #%s: %s" % [line_no, line]
        else
          entry.parse_line(line)
          
          # Determine which array to put it in based on its type
          if entry.is_only_redirect?
            if entry.has_variant?
              @variant_only_entries << entry
            else
              @reference_only_entries << entry
            end
          else
            entries << entry
          end
        end
      rescue Exception => e
        prt "Could not parse line #%s: %s" % [line_no, line]
        prt "Message: %s\n" % e.message
        prt "Backtrace: %s\n" % e.backtrace.inspect
      end
    end
    
    # Now handle any funkiness with variants
    
    return entries
  end
  
  def merge_references_into_base_entries(base_entries,ref_entries)
    tmp_ref = Array.new(ref_entries)
    # Loop through the list of all entries
    base_entries.each do |base_entry|
      # Then compare that entry to each of our referenced entries
      tmp_ref.each do |ref_entry|
        # Get the right reference (reference or variant)
        ref = ref_entry.references[0] if ref_entry.references.count > 0
        ref = ref_entry.variant_of if (ref_entry.has_variant? or ref_entry.is_erhua_variant?)
        inline_entry = Entry.parse_inline_entry(ref)
        
        # Now merge & remove if the cards match (so we don't loop over it again)
        if base_entry.inline_entry_match?(inline_entry)
          pp "Matched reference entry %s to %s" % [ref_entry, base_entry]
          base_entry.add_inline_entry_to_meanings(inline_entry)
          ref_entries.delete(ref_entry)
        end
      end
    end
    return base_entries
  end
  
  def reference_only_entries
    @reference_only_entries
  end

  def variant_only_entries
    @variant_only_entries
  end
end
