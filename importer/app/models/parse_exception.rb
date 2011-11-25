class ParseException < ActiveRecord::Base

  def self.all_unresolved
    where("resolution_string IS NULL")
  end

end
