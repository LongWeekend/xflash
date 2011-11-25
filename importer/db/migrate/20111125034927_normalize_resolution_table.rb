class NormalizeResolutionTable < ActiveRecord::Migration
  def self.up
    add_column(:tag_matching_resolutions, "tag_matching_resolution_choice_id", :integer)
  end

  def self.down
    remove_column(:tag_matching_resolutions, "tag_matching_resolution_choice_id")
  end
end
