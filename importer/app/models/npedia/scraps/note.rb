#
# ABOUT: Notes are exactly that!
# 
class Note < Scrap

  add_yaml_field :body
  validates_presence_of("body", :message => 'cannot be blank'[:error_field_blank])

end
