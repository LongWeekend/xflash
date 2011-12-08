require 'test/unit'

class ParserTest < Test::Unit::TestCase

  def test_parse_diff
    line_hash = Parser.diff("old_file.txt","new_file.txt")
    # Added, removed, changed
    assert_equal(3, line_hash.count)
    
    added_lines = line_hash[:added]
    added_entries = Parser.new(added_lines).run
    # Then we could add these to the DB as-is.
    
    removed_lines = line_hash[:removed]
    removed_entries = Parser.new(removed_lines).run
    # We could search the DB and remove these easily.
    
    # Changed would be harder... :( we have to pair the add/remove entries together.
    changed_entries = []
    changed_line_sets = line_hash[:changed]
    changed_line_sets.each do |added_lines, removed_lines|
      added_entries = Parser.new(added_lines).run
      removed_entries = Parser.new(removed_lines).run
      changed_entries << [:added => added_entries, :removed => removed_entries]
    end
  end
  
end
