class CreateTagMatchingResolutions < ActiveRecord::Migration
  def self.up
    create_table :tag_matching_resolutions do |t|
      t.string :entry_id
      t.text :serialized_entry
      t.string :resolution_type

      t.timestamps
    end
  end

  def self.down
    drop_table :tag_matching_resolutions
  end
end
