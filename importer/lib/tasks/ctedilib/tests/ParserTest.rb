require 'test/unit'

class ParserTest < Test::Unit::TestCase

  def test_parse_diff
    diff_parser = CEdictDiffParser.new("test_data/test_diff_cedict_old.u8", "config.yml")
    line_hash = diff_parser.run
    diff_parser.dump
    
    diff_parser = CEdictDiffParser.new("test_data/test_diff_cedict_new.u8", "config.yml")
    line_hash = diff_parser.run
    diff_parser.dump
    
    # Added, removed, changed
    assert_equal(3, line_hash.count)
    
    # We could search the DB and add these easily.
    added_lines = line_hash[:added]
    added_parser = CEdictParser.new(added_lines)
    new_entries = added_parser.run
    
    added_obj_count = new_entries.count + added_parser.reference_only_entries.count + added_parser.variant_only_entries.count + added_parser.variant_entries.count + added_parser.erhua_variant_entries.count
    assert_equal(added_obj_count, added_lines.count)
    
    # Get the base of the entire cards library.
    base = EntryCache.new.card_entries_array
    # These two are categorised as 'changed'/'updated'
    added_reference_entries = added_parser.merge_references_into_base_entries(base, added_parser.reference_only_entries)
    added_variant_entries = added_parser.merge_references_into_base_entries(base, added_parser.variant_only_entries)
    
    added_parser.merge_references_into_base_entries(new_entries, added_parser.reference_only_entries)
    added_parser.merge_references_into_base_entries(new_entries, added_parser.variant_only_entries)
    
    prt_dotted_line
    entries = new_entries + base
    muxed_base_entries_with_new_variant = added_parser.add_variant_entries_into_base_entries(base, added_parser.variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.variant_entries)
    muxed_variant_entries = added_parser.add_base_entries_into_variant_entries(added_parser.variant_entries, entries)
    
    muxed_base_entries_with_new_erhua = added_parser.add_variant_entries_into_base_entries(base, added_parser.erhua_variant_entries)
    added_parser.add_variant_entries_into_base_entries(new_entries, added_parser.erhua_variant_entries)
    muxed_erhua_entries = added_parser.add_base_entries_into_variant_entries(added_parser.erhua_variant_entries, entries)
    
    changed = added_reference_entries + added_variant_entries + muxed_base_entries_with_new_variant + muxed_base_entries_with_new_erhua
    
    added = new_entries + muxed_variant_entries + muxed_erhua_entries
    
    
    
    # We could search the DB and remove these easily.
    removed_lines = line_hash[:removed]
    removed_parser = CEdictParser.new(removed_lines)
    removed_entries = removed_parser.run
    
    removed_reference_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.reference_only_entries)
    removed_variant_entries = removed_parser.unmerge_references_from_base_entries(base, removed_parser.variant_only_entries)
    
    removed_parser.unmerge_references_from_base_entries(removed_entries, removed_parser.reference_only_entries)
    removed_parser.unmerge_references_from_base_entries(removed_entries, removed_parser.variant_only_entries)
    
    entries = removed_entries + base
    muxed_base_entries_with_removed_variant = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.variant_entries)
    removed_parser.rem_variant_entries_from_base_entries(new_entries, removed_parser.variant_entries)
    muxed_variant_entries = removed_parser.rem_variant_entries_from_base_entries(removed_parser.variant_entries, entries)
    
    muxed_base_entries_with_removed_erhua = removed_parser.rem_variant_entries_from_base_entries(base, removed_parser.erhua_variant_entries)
    removed_parser.rem_variant_entries_from_base_entries(new_entries, removed_parser.erhua_variant_entries)
    muxed_erhua_entries = removed_parser.rem_variant_entries_from_base_entries(removed_parser.erhua_variant_entries, entries)
    
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
