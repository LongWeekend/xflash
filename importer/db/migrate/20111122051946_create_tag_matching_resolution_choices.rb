class CreateTagMatchingResolutionChoices < ActiveRecord::Migration
  def self.up
    create_table :tag_matching_resolution_choices do |t|
      t.string :base_entry_id
      t.string :human_readable
      t.text :serialized_entry

      t.timestamps
    end
  end

  def self.down
    drop_table :tag_matching_resolution_choices
  end
end
