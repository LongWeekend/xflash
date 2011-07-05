#
# ABOUT: Bookmarks are links to related or relevant data
#
class Bookmark < Scrap

  add_yaml_field :url
  validates_presence_of("url", :message => 'cannot be blank'[:error_field_blank])
  alias :base_url :url=
  
  def url=(value)
    self.url = value.to_str.strip.gsub(/[\r\n|\n]/, "").gsub(/(http|https|mailto|ftp|nntp)\:\/\//, '')
    base_url(value)
  end

end
