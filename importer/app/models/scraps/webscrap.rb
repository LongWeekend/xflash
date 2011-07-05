#
# ABOUT: WebScraps are excerpts selected by users from relevant web pages (human contributed spidering)
# 
class Webscrap < Scrap

  add_yaml_field :url
  validates_presence_of("url", :message => 'Field cannot be blank'[:error_field_blank])

  add_yaml_field :excerpt
  validates_presence_of("excerpt", :message => 'Field cannot be blank'[:error_field_blank])

  add_yaml_field :description

end
