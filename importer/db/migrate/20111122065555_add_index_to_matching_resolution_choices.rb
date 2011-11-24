class AddIndexToMatchingResolutionChoices < ActiveRecord::Migration
  def self.up
    add_index :tag_matching_resolution_choices, "base_entry_id", :unique => false 
  end

  def self.down
    remove_index :tag_matching_resolution_choices, "base_entry_id"
  end
end
