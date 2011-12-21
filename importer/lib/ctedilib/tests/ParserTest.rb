require 'test/unit'

class ParserTest < Test::Unit::TestCase

  def test_parse_diff
    diff_parser = DiffParser.new("test_data/test_diff_cedict_old.u8", "config.yml")
    line_hash = diff_parser.run
    diff_parser.dump
    
    prt "\nCEDICT Diff Parse (1) - Initial Difference file parsing"
    prt_dotted_line
    diff_parser = DiffParser.new("test_data/test_diff_cedict_new.u8", "config.yml")
    line_hash = diff_parser.run
    diff_parser.dump
    
    # Added, removed, changed
    assert_equal(3, line_hash.count)
    
    # Get the base of the entire cards library.
    prt "\nCEDICT Diff Parse (2) - Get all the existing cards object from database"
    prt_dotted_line
    base = EntryCache.new.card_entries_array
    
    # We could search the DB and add these easily.
    prt "\nCEDICT Diff Parse (3) - Added line parsing"
    prt_dotted_line
    added_lines = line_hash[:added]
    added_parser = CEdictParser.new(added_lines)
    new_entries = added_parser.run
    prt "\nResult : %d line(s) has been added in the new file.\nNew base-entries: %d" % [added_lines.count, new_entries.count]
    
    added_obj_count = new_entries.count + added_parser.reference_only_entries.count + added_parser.variant_only_entries.count + added_parser.variant_entries.count + added_parser.erhua_variant_entries.count
    assert_equal(added_obj_count, added_lines.count)

    prt "\nCEDICT Diff Parse (4) - (Merge 'reference-only' Entries: %s reference, %s variant to the new entries)" % [added_parser.reference_only_entries.count, added_parser.variant_only_entries.count]
    prt_dotted_line    
    added_parser.merge_references_into_base_entries(new_entries, added_parser.reference_only_entries)
    added_parser.merge_references_into_base_entries(new_entries, added_parser.variant_only_entries)
    
    # These two are categorised as 'changed'/'updated'
    prt "\nCEDICT Diff Parse (5) - (Merge 'reference-only' Entries: %s reference, %s variant to the existing entries)" % [added_parser.reference_only_entries.count, added_parser.variant_only_entries.count]
    prt_dotted_line
    added_reference_entries = added_parser.merge_references_into_base_entries(base, added_parser.reference_only_entries)
    added_variant_entries = added_parser.merge_references_into_base_entries(base, added_parser.variant_only_entries)
    
    entries = new_entries + base
    prt "\nCEDICT DIff Parse (6) - (Cross-Referencing %d Variants to both existing entries and new entries)" % [added_parser.variant_entries.count]
    prt_dotted_line
    muxed_base_entries_with_new_variant = added_parser.add_variant_entries_into_base_entries(base, added_parser.variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.variant_entries)
    muxed_variant_entries = added_parser.add_base_entries_into_variant_entries(added_parser.variant_entries, entries)
    
    prt "\nCEDICT DIff Parse (7) - (Cross-Referencing %d Erhua Variants to both existing entries and new entries)" % [added_parser.erhua_variant_entries.count]
    prt_dotted_line
    muxed_base_entries_with_new_erhua = added_parser.add_variant_entries_into_base_entries(base, added_parser.erhua_variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.erhua_variant_entries)
    muxed_erhua_entries = added_parser.add_base_entries_into_variant_entries(added_parser.erhua_variant_entries, entries)
    
    # We could search the DB and remove these easily.
    prt "\nCEDICT Diff Parse (8) - Removed line parsing"
    prt_dotted_line
    removed_lines = line_hash[:removed]
    removed_parser = CEdictParser.new(removed_lines)
    removed_entries = removed_parser.run
    prt "\nResult : %d line(s) has been removed in the new file.\nRemoved base-entries: %d" % [removed_lines.count, removed_entries.count]
    
    ### On the removal of the reference, only check against the exisiting entries on the db. There is no need in checking to the base which gets removed (removed_entries),
    ### Because it gets removed anyway. This is a slightly different from the 'add' section above.
    prt "\nCEDICT Diff Parse (9) - (Un-Merge 'reference-only' Entries: %s reference, %s variant from the existing entries)" % [removed_parser.reference_only_entries.count, removed_parser.variant_only_entries.count]
    prt_dotted_line
    # These two are getting updated as well as the reference is unmerged
    removed_reference_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.reference_only_entries)
    removed_variant_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.variant_only_entries)

    prt "\nCEDICT Diff Parse (10) - (Cross-Referencing %d Variants and %d Erhua Variants to the existing entries for removal)" % [removed_parser.variant_entries.count, removed_parser.erhua_variant_entries.count]
    prt_dotted_line    
    # These two are getting updated cause somewhere in their meaning has changed, cause some of them is getting removed.
    muxed_base_entries_with_removed_variant = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.variant_entries)
    muxed_base_entries_with_removed_erhua = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.erhua_variant_entries)
    
    ## TO-DO Actually cross reference between the removed and added. If either one is crossed, meaning that they should be in 'changed' section
    
    ## These are added
    added = new_entries + muxed_variant_entries + muxed_erhua_entries
    
    ## These are changed
    changed = added_reference_entries + added_variant_entries + 
              removed_reference_entries + removed_variant_entries +
              muxed_base_entries_with_new_variant + muxed_base_entries_with_new_erhua +
              muxed_base_entries_with_removed_variant + muxed_base_entries_with_removed_erhua
    
    ## This are deleted
    removed = removed_entries + removed_parser.variant_only_entries + removed_parser.reference_only_entries + removed_parser.variant_entries + removed_parser.erhua_variant_entries

    prt_dotted_line    
    prt "\nCEDICT Diff Parse (RESULT)\nAdded   : %d\nRemoved : %d\nUpdated : %d\n" % [added.count, removed.count, changed.count]
    prt_dotted_line
    
    # Changed would be harder... :( we have to pair the add/remove entries together.
    # changed_entries = []
    # changed_line_sets = line_hash[:changed]
    # changed_line_sets.each do |added_lines, removed_lines|
    #  added_entries = Parser.new(added_lines).run
    #  removed_entries = Parser.new(removed_lines).run
    #  changed_entries << [:added => added_entries, :removed => removed_entries]
    #end
  end
  
end
