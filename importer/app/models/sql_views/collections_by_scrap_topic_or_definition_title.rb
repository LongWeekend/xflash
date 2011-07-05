#
# ABOUT: Model for accessing the view "v_collections_by_scrap_topic_or_definition_title"
#
class CollectionsByScrapTopicOrDefinitionTitle < ActiveRecord::Base
  set_table_name "v_collections_by_scrap_topic_or_definition_title"

  #thinking sphinx
  define_index do
    indexes :text, :sortable => true
    indexes :text2, :sortable => true
    has :id
  end
end