#
# ABOUT: ParallelTexts are for storing aligned texts
#
class ParallelText < Scrap

  has_one :scrap_page, :foreign_key => :cacheable_id, :conditions => ['cacheable_type = ?', ParallelText.to_s ]

  add_yaml_field :japanese
  validates_presence_of("japanese", :message => 'cannot be blank'[:error_field_blank])

  add_yaml_field :translated
  validates_presence_of("translated", :message => 'cannot be blank'[:error_field_blank])

  add_yaml_field :annotation
  ##validates_presence_of("annotation", :message => 'cannot be blank'[:error_field_blank])

  alias :base_japanese :japanese=

  def japanese=(value)
    # Copy self.japanese to self.title, for easy Sphinx indexing!
    self.title = value
    base_japanese(value)
  end

  def summary_text
    japanese[0..35] + " &gt; " + translated[0..35]
  end

end
