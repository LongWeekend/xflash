class CreateTagMatchingExceptions < ActiveRecord::Migration
  def self.up
    create_table :tag_matching_exceptions do |t|
      t.string :entry_id
      t.string :human_readable
      t.text :serialized_entry

      t.timestamps
    end
  end

  def self.down
    drop_table :tag_matching_exceptions
  end
end
