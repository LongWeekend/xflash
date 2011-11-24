class RenameBaseEntryIdOnTagMatchingResolutionChoices < ActiveRecord::Migration
  def self.up
    rename_column (:tag_matching_resolution_choices, "base_entry_id", "tag_matching_exception_id")
  end

  def self.down
    rename_column (:tag_matching_resolution_choices, "tag_matching_exception_id", "base_entry_id")
  end
end
