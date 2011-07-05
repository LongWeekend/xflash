class TagCache < ActiveRecord::Base
  has_one :tag
  set_table_name "tag_cache"
end