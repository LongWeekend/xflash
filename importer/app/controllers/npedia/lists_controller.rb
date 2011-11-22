class ListsController < ApplicationController
  before_filter :login_required_ajax
  before_filter :load_list

  def load
    @list_keys, @list_items = @list.items
    respond_to do |format|
      format.js { render :partial => "scraps/list_item_ajax", :layout => false }
    end
  end

  def empty_list
    List.find_by_name_and_user_id(params[:name], current_user.id).delete if(params[:name])
    render :json => (true).to_json
  end

  def new
    #placeholder
  end
  
  def rename
    #placeholder
  end

  def delete
    #placeholder
  end
  
  def remove_item
    #add support for BULK removal of items (e.g. JSON data like this {{"Scrap",999},{"ScrapTopic",9}} )
    active_list = List.find_by_name_and_user_id(params[:name], current_user.id)
    if active_list
      if params[:scrap_id]
        listable_type = 'Scrap'
        listable_id = params[:scrap_id]
      elsif params[:scrap_topic_id]
        listable_type = 'ScrapTopic'
        listable_id = params[:scrap_topic_id]
      end
      item = ListItem.find_by_list_id_and_listable_id_and_listable_type(active_list.id, listable_id, listable_type)
      item.remove_from_list
      item.delete
      render :json => (true).to_json
    end
  end
  
  def toggle
    #add support for BULK toggling of items
    if(params[:name])
      if params[:scrap_topic_id]
        @list_item = ListItem.find_or_initialize_by_list_id_and_listable_type_and_listable_id(@list.id, 'ScrapTopic', params[:scrap_topic_id])
      elsif params[:scrap_id]
        @list_item = ListItem.find_or_initialize_by_list_id_and_listable_type_and_listable_id(@list.id, 'Scrap', params[:scrap_id])
      end
      if @list_item.new_record?
        @list_item.save!
      else
        @list_item.delete
      end
      @list_keys, @list_items = @list.items
    end
    render :partial => "scraps/list_item_ajax", :layout => false
  end

  def list_contains
    # This is broken for parallel texts!
    if logged_in? and params[:name] and params[:scrap_topic_id]
      scrap_topic = ScrapTopic.find_by_slug_cache(params[:scrap_topic_id])
      @list_items = [] and return if scrap_topic.nil?
      active_list = List.find_by_name_and_user_id(params[:name], current_user.id)
      stopics = scrap_topic.scraps.collect { |s| s.id.to_s }.join(",")
      condition = "(listable_type = 'ScrapTopic' AND listable_id = #{scrap_topic.id})"
      condition = condition + "OR (listable_type = 'Scrap' AND listable_id IN (#{stopics})) " if stopics.length > 0
      @list_items = active_list.list_items.find(:all, :conditions => condition)
    else
      @list_items = []
    end
    render :json => @list_items.to_json
  end

  protected
    def login_required_ajax
      if !logged_in?
        render_401 and return
      end
    end
    def load_list
      @list = List.find_or_create_by_user_id_and_name(current_user.id, params[:name]) if(params[:name])
    end
end