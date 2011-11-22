#
# ABOUT: Definitions are for storing dictionary entries
#
class Definition < Scrap

  add_yaml_field :usage
  validates_presence_of("usage", :message => 'cannot be blank'[:error_field_blank])

  add_yaml_field :readings
  validates_presence_of("readings", :message => 'cannot be blank'[:error_field_blank])

  alias :base_readings :readings=

  def readings=(value)
    # Copy self.readings to self.title, for easy Sphinx indexing!
    self.title = value
    base_readings(value)
  end

  def formatted_readings
    txt = (readings.nil? ? scrap_topic.title : readings)
    "[" + txt.split(/ /).join("] [") + "]"
  end

  def summary_text
    formatted_readings + " " + usage[0..35]
  end
end
