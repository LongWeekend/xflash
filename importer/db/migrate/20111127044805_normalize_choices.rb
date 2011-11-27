class NormalizeChoices < ActiveRecord::Migration
  def self.up
    remove_column :tag_matching_resolution_choices, :human_readable
    remove_column :tag_matching_resolution_choices, :serialized_entry
  end

  def self.down
    add_column :tag_matching_resolution_choices, :human_readable, :string
    add_column :tag_matching_resolution_choices, :serialized_entry, :text
  end
end
