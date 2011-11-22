class Page < Scrap

  belongs_to :book, :foreign_key => "collection_id", :counter_cache => :child_count
  validates_uniqueness_of :title, :message => 'Title is already in use in scope'[:error_unique_value_duplicate], :scope => :collection_id
  validates_presence_of :title, :message => 'Field cannot be blank'[:error_field_blank]
  validates_presence_of :content, :message => 'Field cannot be blank'[:error_field_blank]
  attr_accessible :title, :content, :tags, :parent_id, :attributions
  attr_readonly :book_id

  def book_id
    self.collection_id
  end

  def book_id=(value)
    self.collection_id = value.to_i
  end

end
