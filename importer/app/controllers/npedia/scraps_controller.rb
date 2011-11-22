class ScrapsController < ApplicationController

  before_filter :scrap_user_logged_in?, :except => [:show, :show_scrap_topic, :update, :new] ## Calls to update handle auth checks locally
  before_filter :autoload_scrap_data, :only => [:show_scrap_topic, :edit_scrap_topic, :update_scrap_topic, :show, :new, :create, :edit, :update]
  layout "search"

  include Sluggable
  include TiddlerActions

  #
  # ScrapsController > show_scrap_topic : Render scrap topic to browser
  #
  def show_scrap_topic
    render_404 and return if @scrap_topic.nil?
    @scraps = @scrap_topic.scraps if @scrap_topic

    flash[:notice] = 'This topic is empty, please add some scraps.'[:msg_empty_topic_add_scraps] if @scraps.length == 0
    respond_to do |format|
      format.html { render :action => 'scrap_topic' and return }
      format.js { render :action => 'scrap_topic', :layout => false and return }
      format.xml { return }
    end
  end

  #
  # ScrapsController > new_scrap_topic : Render new scrap topic form to browser
  #
  def new_scrap_topic
    @scrap_topic = ScrapTopic.new
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'new_scrap_topic', :layout => false and return }
      format.xml { return }
    end
  end

  #
  # ScrapsController > create_scrap_topic : Create new scrap topic and render to browser
  #
  def create_scrap_topic
    @scrap_topic = ScrapTopic.new
    @scrap_topic.title = params[:scrap_topic][:title].strip
    @scrap_topic.user_id = current_user.id
    begin
      ScrapTopic.transaction do
        tag = Tag.find_or_create_by_name(params[:scrap_topic][:title].strip)
        @scrap_topic.save!
        respond_to do |format|
          format.html do
            flash[:notice] = 'Topic successfully created'[:msg_topic_created]
            redirect_to scrap_topic_path(@scrap_topic.slug)
          end
          format.js { show_scrap_topic and return }
          format.xml { return }
        end
      end
    rescue
      respond_to do |format|
        format.html { render :action => 'new_scrap_topic' and return }
        format.js { render :action => 'new_scrap_topic', :layout => false and return }
        format.xml { return }
      end
    end
  end

  #
  # ScrapsController > edit_scrap_topic : Render edict scrap topic form to browser
  #
  def edit_scrap_topic
    if can_modify_scrap_topic?
      respond_to do |format|
        format.html { return }
        format.js { render :action => 'edit_scrap_topic', :layout => false and return }
        format.xml { return }
      end
    else
      render_401 and return
    end
  end

  #
  # ScrapsController > update_scrap_topic : Update scrap topic and render to browser -- NOT IMPLEMENTED!
  #
  def update_scrap_topic
    # Not allowed for now
    render_401 and return
  end

  #
  # ScrapsController > show : Render scrap to browser, right now only used by ParallelText scraps
  #
  def show
    render_404 and return if @scrap.nil?
    respond_to do |format|
      format.html { redirect_to show_scrap_path(@scrap.slug) and return }
      format.js { render :action => "scrap", :layout => false and return }
      format.xml { return }
    end
  end

  #
  # ScrapsController > new : Render new scrap form to browser
  #
  def new
    return if !scrap_user_logged_in?(true) # check if logged in!
    scrap_type = params[:type].downcase
    if !scrap_type.nil?
      @scrap = Definition.new if scrap_type == "definition"
      @scrap = ParallelText.new if scrap_type == "parallel_text"
      @scrap = Bookmark.new if scrap_type == "bookmark"
      @scrap = Webscrap.new if scrap_type == "webscrap"
      @scrap = Note.new if scrap_type == "note"
    end
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'new', :layout => false and return }
      format.xml { return }
    end
  end

  #
  # ScrapsController > create : Create the new scrap and render it to browser
  #
  def create
    return if cancelled?
    begin
      if params[:scrap][:type] == "ParallelText"
        @scrap = ParallelText.new(params[:scrap])
        @scrap.scrap_topic = Corpus.by_language(params[:scrap][:language_id])
      else
        if params[:scrap][:type] == "Definition"
          @scrap = Definition.new(params[:scrap])
        elsif params[:scrap][:type] == "Webscrap"
          @scrap = Webscrap.new(params[:scrap])
        elsif params[:scrap][:type] == "Bookmark"
          @scrap = Bookmark.new(params[:scrap])
        else
          @scrap = Note.new(params[:scrap])
        end
        if @scrap_topic.nil? or  @scrap_topic.id == nil
          #Initiatlize a new scrap topic!
          @scrap.scrap_topic = init_scrap_topic(params[:scrap_topic_title], current_user.id)
        else
          #Assign existing scrap topic
          @scrap.scrap_topic = @scrap_topic
        end
      end
      @scrap.save!(current_user)
      if @scrap.class.to_s =="ParallelText"
        respond_to do |format|
          format.html { redirect_to show_scrap_path(@scrap.slug) and return }
          format.js { render :action => "scrap", :layout => false and return }
          format.xml { return }
        end
      else
        respond_to do |format|
          format.html {  redirect_to scrap_topic_path(@scrap.scrap_topic.slug) and return }
          format.js { @scraps = @scrap_topic.scraps if !@scrap_topic.scraps.nil?; render :action => "scrap_topic", :layout => false and return }
          format.xml { return }
        end
      end
      
    rescue
      #
      # Re-Display On Error      
      respond_to do |format|
        format.html { render :action => "new" and return  }
        format.js { render :partial => "scrap_form", :layout => false and return }
        format.xml { return }
      end
    end
  end
  
  #
  # ScrapsController > edit : Updates current scrap and renders it to browser
  #
  def edit
    respond_to do |format|
      format.html { render :action => "edit" and return  }
      format.js { render :partial => "scrap_form", :layout => false and return }
      format.xml { return }
    end
  end

  #
  # ScrapsController > update : Updates current scrap and renders it to browser
  #
  def update
    if params[:cancel]
      if @scrap.class.to_s =="ParallelText"
        display_inline_scrap
      else
        display_inline_scrap_topic
      end
      return # redisplay the scrap inline
    end
    return if !scrap_user_logged_in? # check if logged in!
    old = @scrap.attributes.to_yaml
    @scrap.update_attributes(params[:scrap])
    mod = @scrap.attributes.to_yaml
    begin
      @scrap.save!(current_user) if mod != old
      if @scrap.class.to_s =="ParallelText"
        display_inline_scrap
      else
        display_inline_scrap_topic
      end
    rescue
      #
      # Re-Display On Error
      edit and return
    end
  end

  protected
    #
    # ScrapsController > display_inline_scrap : Renders the current scrap or scrap topic to the browser
    #
    def display_inline_scrap_topic
      respond_to do |format|
        format.html { redirect_to scrap_topic_path(@scrap.scrap_topic.slug) and return }
        format.js {  @scraps = @scrap_topic.scraps if @scraps.nil?; render :partial => "scrap", :layout => false and return }
        format.xml { return }
      end
    end

    def display_inline_scrap
      respond_to do |format|
        format.html { redirect_to show_scrap_path(@scrap.slug) and return }
        format.js { render :partial => "scrap", :layout => false and return }
        format.xml { return }
      end
    end

    #
    # (scrap_topic) init_scrap_topic : Creates a scrap topic based on the new slug
    #
    def init_scrap_topic(title, user_id)
      @scrap_topic = ScrapTopic.find_or_create_by_title(:title => title, :user_id => user_id, :parent_id => 0)
    end

    #
    # (true) autoload_scrap_data : Loads scrap / scrap_topic data into request scope
    #
    def autoload_scrap_data
      #
      # Get ScrapTopic identifier from the querystring
      if params[:scrap_topic_title]
        scrap_topic_title = params[:scrap_topic_title]
      elsif params[:scrap_topic_id]
        if params[:scrap_topic_id].class == Array
          scrap_topic_id = params[:scrap_topic_id][0]
        else
          scrap_topic_id = params[:scrap_topic_id]
        end
      end

      #
      # TRY getting @scrap_topic by id
      if scrap_topic_id.to_i > 0
        @scrap_topic = ScrapTopic.find_by_id(scrap_topic_id.to_i)
      #
      # TRY getting @scrap_topic by slug
      else
        scrap_topic_id = params[:scrap_topic_title] if params[:scrap_topic_title]
        @scrap_topic = ScrapTopic.find_by_slug_cache(scrap_topic_id)
      end

      #
      # TRY getting @scrap by slug/id
      if params[:id]
        if params[:id].to_i > 0
          @scrap = Scrap.find_by_id(params[:id].to_i)
          @scrap_topic = @scrap_topic if @scrap and @scrap_topic.nil?
        elsif params[:id]
          @scrap = Scrap.find_by_slug_cache(params[:id])
          @scrap_topic = @scrap_topic if @scrap and @scrap_topic.nil?
        end
      end

      #
      # Get @scrap_topic from @scrap if @scrap_topic not set
      @scrap_topic ||= @scrap.scrap_topic if @scrap
      return true
    end

    #
    # (boolean) can_modify_scrap_topic? : Return true if current user can modify the scrap
    #
    def can_modify_scrap_topic?
      return (admin? or @scrap_topic.scraps.length == 0 or (logged_in? and @scrap_topic.user_id == current_user.id))
    end

    #
    # (boolean) scrap_user_logged_in? : Renders "tiddler status msg" or "tiddler msg" if not logged in
    #
    def scrap_user_logged_in?(error_in_empty_tiddler = false)
      if !logged_in?
        message = '<h3>'+'Please login first'[:error_login_first] + '</h3>'
        respond_to do |format|
          format.html { flash[:error] = message and render :action => 'create', :status => :unauthorized and return false }
          format.js { 
            if error_in_empty_tiddler
              render :partial => "layouts/message", :status => :unauthorized, :locals => {:message => message}, :layout => false
            else
              render :partial => "layouts/status_message", :status => :unauthorized, :locals => {:message => message}, :layout => false
            end
            return false
          }
          format.xml { return false }
        end
      else
        return true
      end
    end

end