class RenameTagsToEntryTags < ActiveRecord::Migration
  def self.up    
    rename_column (:cards_staging, "tags", "entry_tags")
  end

  def self.down
    rename_column (:cards_staging, "entry_tags", "tags")
  end

end
