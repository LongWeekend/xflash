class RenameTagsToEntryTags < ActiveRecord::Migration
  def self.up    
    rename_column (:card_staging, "tags", "entry_tags")
  end

  def self.down
    rename_column (:card_staging, "entry_tags", "tags")
  end

end
