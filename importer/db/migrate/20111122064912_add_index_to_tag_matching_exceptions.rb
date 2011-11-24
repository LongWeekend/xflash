class AddIndexToTagMatchingExceptions < ActiveRecord::Migration
  def self.up
    add_index :tag_matching_exceptions, "entry_id", :unique => true
  end

  def self.down
    remove_index :tag_matching_exceptions, :column => "entry_id"
  end
end
