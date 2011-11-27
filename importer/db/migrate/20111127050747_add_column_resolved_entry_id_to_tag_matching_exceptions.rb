class AddColumnResolvedEntryIdToTagMatchingExceptions < ActiveRecord::Migration
  def self.up
    add_column :tag_matching_exceptions, :resolved_entry_id, :integer
    remove_column :tag_matching_exceptions, :resolved_serialized_entry
  end

  def self.down
    remove_column :tag_matching_exceptions, :resolved_entry_id
    add_column :tag_matching_exceptions, :resolved_serialized_entry, :text
  end
end
