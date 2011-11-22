class Monitorship < ActiveRecord::Base
  belongs_to :user
  belongs_to :forum_topic, :foreign_key => "collection_id"
end
