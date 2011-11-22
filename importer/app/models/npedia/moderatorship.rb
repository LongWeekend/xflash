class Moderatorship < ActiveRecord::Base
  belongs_to :user
  belongs_to :forum, :foreign_key => "collection_id"
  before_create { |r| count(:all, :conditions => ['collection_id = ? and user_id = ?', r.collection_id, r.user_id]).zero? }
end