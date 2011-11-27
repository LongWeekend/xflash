class AddEntriesForeignKey < ActiveRecord::Migration
  def self.up
    add_column :tag_matching_resolution_choices, :entry_id, :integer
  end

  def self.down
    remove_column :tag_matching_resolution_choices, :entry_id
  end
end
