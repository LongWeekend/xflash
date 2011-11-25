class RedoResolutionTable < ActiveRecord::Migration
  def self.up
    drop_table("tag_matching_resolutions")
    add_column(:tag_matching_exceptions,"should_ignore", :boolean, {:null => false, :default => 0} )
    add_column(:tag_matching_exceptions,"resolved_serialized_entry", :text)
  end

  def self.down
    remove_column(:tag_matching_exceptions,"should_ignore")
    remove_column(:tag_matching_exceptions,"resolved_serialized_entry")
    create_table("tag_matching_resolutions", {"tag_matching_exception_id" => :integer,"serialized_entry" => :text,"resolution_type" => :string, "tag_matching_resolution_choice_id" => :integer })
  end
end
