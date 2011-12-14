class AddPriorityWordInCardsStaging < ActiveRecord::Migration
  def self.up
    add_column :cards_staging, :priority_word, :integer, { :limit => 1, :null => false, :default => 0 }
  end

  def self.down
    remove_column :cards_staging, :priority_word
  end
end
