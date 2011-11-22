class BatchJob < ActiveRecord::Base

  def self.import_statuses
    statuses = {}
    statuses["not_imported"] = 0
    statuses["completed"] = 1
    statuses["linked"] = 2
    statuses["inserted"] = 3
    return statuses
  end

end