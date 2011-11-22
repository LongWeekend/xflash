class ForumsController < ApplicationController

  before_filter :login_required, :except => [ :index, :show ]
  before_filter :authorized? ### Admin Only Controller , :only => [ :new, :create, :edit, :update ]
  before_filter :load_forum, :except => [ :index, :create ]
  before_filter :load_forums, :only => [ :index ]
  before_filter :load_forum_topics, :only => [ :show, :update ]

  layout "search"

  def index
    respond_to do |format|
      format.html { return }
      format.js { render :template => 'forums/index', :layout => false and return }
      format.xml { return }
    end
  end

  def show
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'show', :layout => false and return }
      format.xml { render :xml => @forum.to_xml and return }
    end
  end

  def new
    @forum = Forum.new
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'new', :layout => false and return }
      format.xml { return }
    end
  end

  def create
    return if cancelled?
    begin
      @forum = Forum.new(params[:forum])
      @forum.user = current_user
      @forum.save!
      respond_to do |format|
        format.html { redirect_to forums_path and return }
        format.js { load_forums and index and return }
        format.xml { return }
      end
    rescue
      #Re-Display on error
      respond_to do |format|
        format.html { return }
        format.js { render :action => 'new', :layout => false and return }
        format.xml  { return }
      end
    end
  end

  def edit
  respond_to do |format|
      format.html { return }
      format.js { render :action => 'edit', :layout => false and return }
      format.xml { return }
    end
  end

  def update
    return if cancelled?
    begin
      @forum.update_attributes!(params[:forum])
      assign_protected_values
      @forum.save!
      #On success
      respond_to do |format|
        format.html { redirect_to forums_path and return }
        format.js { redirect_to forums_path(:format => :js) }
        format.xml { head 200 }
      end
    rescue
      #Re-Display on error
      respond_to do |format|
        format.html { render :action => 'edit' and return }
        format.js { render :action => 'edit', :layout => false and return }
        format.xml { }
      end
    end
  end

  protected
    alias authorized? admin?

    def assign_protected_values
      return unless admin?
      # Only admins can delete
      @forum.suspended = params[:forum][:suspended]
      @forum.sticky = params[:forum][:sticky]
      @forum.deleted = params[:forum][:deleted]
    end

    def load_forum
      @forum = Forum.find(params[:id]) if params[:id]
      ## needed? # session[:forum_page]=nil
    end

    def load_forums
      @forums = Forum.find(:all, :order => "updated_at", :conditions => ['deleted_at IS NULL'], :order => 'sticky_flag DESC, updated_at DESC')
    end

    def load_forum_topics
      page = 1
      @forum_topics = ForumTopic.paginate(:page => page, :per_page => 25, :conditions => ['parent_id = ? AND deleted_at IS NULL', @forum.id], :order => 'sticky_flag DESC, updated_at desc')
    end

    def cancelled?
      if params[:cancel]
        respond_to do |format|
          format.html { redirect_to forums_path }
          format.js  { redirect_to forums_path(:format => :js)}
          format.xml { }
        end
        true
      else
        return false
      end
    end
end