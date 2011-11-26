class Entry < ActiveRecord::Base
  set_table_name "cards_staging"
  primary_key = "card_id"
end
