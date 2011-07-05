class List < ActiveRecord::Base
  belongs_to :user
  has_many :list_items, :order => "position DESC", :dependent => :delete_all
  
  def items
    #Compile comma delimited key lists
    s_keys = ""; st_keys = ""; item_keys = ""
    list_items = self.list_items
    list_items.each do |l|
      s_keys = s_keys + l.listable_id.to_s + ',' if l.listable_type == 'Scrap'
      st_keys = st_keys +l.listable_id.to_s + ',' if l.listable_type == 'ScrapTopic'
      item_keys = item_keys + l.id.to_s + ','
    end

    #Retrieve from database
    @scraps = {}; @scrap_topics = {}
    if !st_keys.chomp!(',').nil?
      scrap_topics = ScrapTopic.find :all, :conditions => "id IN (#{st_keys})"
      scrap_topics.each { |st| @scrap_topics[st.id] = st }
    end
    if !s_keys.chomp!(',').nil?
      scraps  = Scrap.find :all, :include => :scrap_topic, :conditions => "id IN (#{s_keys})"
      scraps.each { |s| @scraps[s.id] = s }
    end

    #Store the data into hashes
    @items = {}
    list_items.each do |l|
      @items[l.id] = @scraps[l.listable_id] if l.listable_type == 'Scrap'
      @items[l.id] = @scrap_topics[l.listable_id] if l.listable_type == 'ScrapTopic'
    end
    return eval("[#{item_keys.chomp!(',')}]"), @items
  end
  
end