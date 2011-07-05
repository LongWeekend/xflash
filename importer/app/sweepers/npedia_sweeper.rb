class NpediaSweeper < ActionController::Caching::Sweeper
  observe ScrapTopic, Scrap

  def after_create(record)
    expire_cache_for(record)
  end
  
  def after_update(record)
    expire_cache_for(record)
  end
  
  def after_destroy(record)
    expire_cache_for(record)
  end

  private
  def expire_cache_for(record)
    # Expire these pages
# PLEASE TEST THESE!  
    expire_page(:controller => "scraps", :action => "show_scrap_topic", :scrap_topic_id => record.slug) if record.is_a?(ScrapTopic)
    expire_page(:controller => "book_pages", :action => "show_page", :book_id => record.book.slug, :id => record.slug) if record.is_a?(Page)
    expire_action(:controller => "scraps", :action => "edit", :id => record.id) if record.is_a?(Scrap)
    expire_fragment(:controller => "tags", :action => "index")
    expire_fragment(%r{tags/*}) ## This is a little inaccurate
  end
end