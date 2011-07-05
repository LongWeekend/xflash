class Book < Collection
  include Sluggable
  has_many :pages, :dependent => :destroy, :foreign_key => "collection_id"
  belongs_to :user
  attr_accessible :title, :description, :tags

	@@BookTypes = [ :collection, :book, :hidden, :draft, :privatebook, :privatecollection ]
	@@PrettyBookTypes = {
	  :collection => 'Collection'[:text_collection],
	  :book => 'Book'[:text_book],
	  :hidden => 'Hidden'[:text_hidden],
	  :draft => 'Draft'[:text_draft],
	  :privatebook => 'Private Book'[:text_private_book],
	  :privatecollection => 'Private Collection'[:text_private_collection]
	}

	def pretty_book_type?(enum)
		@@PrettyBookTypes[enum]
	end

	def book_types
		@@BookTypes
	end
	
  def tree
    Page.find_nested('collection_id', self.id, 25, 1)
  end

	def book_type_name?
    #	@@BookTypes.find {|k,v| v == self.book_type_id.to_s}[0].to_s
	end

	def self.book_type_name?(id)
		@@BookTypes.find {|k,v| v == id}
	end

	def self.book_type_id?(enum)
		type = @@BookTypes.find {|k,v| v == enum.to_s}[0]
	end

	def self.book_types?
		@@BookTypes
	end

end
