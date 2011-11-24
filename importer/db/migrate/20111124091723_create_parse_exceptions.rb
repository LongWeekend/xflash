class CreateParseExceptions < ActiveRecord::Migration
  def self.up
    create_table :parse_exceptions do |t|
      t.string :input_string
      t.string :exception_type
      t.string :resolution_string

      t.timestamps
    end
  end

  def self.down
    drop_table :parse_exceptions
  end
end
