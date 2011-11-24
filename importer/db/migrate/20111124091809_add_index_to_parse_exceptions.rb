class AddIndexToParseExceptions < ActiveRecord::Migration
  def self.up
    add_index :parse_exceptions, ["input_string","exception_type"], { :unique => true, :name => "input_string_and_type_unique" }
  end

  def self.down
    remove_index :parse_exceptions, :name => "input_string_and_type_unique"
  end

end
