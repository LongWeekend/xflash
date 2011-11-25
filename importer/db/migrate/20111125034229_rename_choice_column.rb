class RenameChoiceColumn < ActiveRecord::Migration
  def self.up
    change_column(:tag_matching_resolutions, "entry_id", :integer)
    rename_column(:tag_matching_resolutions, "entry_id", "tag_matching_exception_id")
  end

  def self.down
    rename_column(:tag_matching_resolutions, "tag_matching_exception_id", "entry_id")
    change_column(:tag_matching_resolutions, "entry_id", :string)
  end
end
