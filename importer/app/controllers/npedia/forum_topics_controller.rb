#
# ABOUT: Forum Topics controller, also creates first post for new forum topics
#
class ForumTopicsController < ApplicationController
  before_filter :find_forum_and_topic, :except => [:index, :new, :create]
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :prevent_further_changes, :only => [:update, :vote_up, :vote_down, :solve_question, :destroy]

  include TiddlerActions
  
  layout "search"

  def index
    # redirect to forums controller
    respond_to do |format|
      format.html { redirect_to forum_path(params[:forum_id]) }
      format.js { render :action => 'index', :layout => false and return }
      format.xml { return }
    end
  end

  def show
    load_forum_topic
    update_last_seen_at
    @monitorship = Monitorship.find_by_user_id_and_collection_id(current_user.id, @forum_topic.id) if logged_in?
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'show', :layout => false and return }
      format.xml { return }
    end
  end

  def new
    # Switch Question/ForumTopic handling
    if !params[:type].nil? && params[:type] == "ForumTopic"
      @forum_topic = ForumTopic.new
    else
      @forum_topic = Question.new
      @forum_topic.forum = get_question_forum
    end
    respond_to do |format|
      format.html { return }
      format.js { render :action => 'new', :layout => false and return }
      format.xml { return }
    end
  end
  
  def create
    return if cancelled?
    # Switch Question/ForumTopic handling
    if params[:forum_topic]
      form_fields = params[:forum_topic]
      @forum_topic = ForumTopic.new
    else
      form_fields = params[:question]
      @forum_topic = Question.new
    end
    @forum_topic.attributes = form_fields
    assign_protected_values(form_fields)
    @forum_post = ForumPost.new
    @forum_post.user = current_user
    @forum_post.body = form_fields[:description]

    ForumTopic.transaction do
      begin
        @forum_topic.save!
        @forum_post.topic = @forum_topic
        @forum_post.save!
      rescue
        #Re-Display on error
        respond_to do |format|
          format.html { return }
          format.js { render :action => 'new', :layout => false and return }
          format.xml  { return }
        end
      end
    end
    #On Success
    respond_to do |format|
      format.html { redirect_to show_question_path(@forum_topic.id) and return }
      format.js { show and return }
      format.xml  { return }
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
    if params[:cancel]
      display_inline_forum_topic
      return
    end
    begin
      # Switch Question/ForumTopic handling
      form_fields = (params[:question] ? params[:question] : params[:forum_topic])
      @forum_topic.update_attributes!(form_fields)
      assign_protected_values(form_fields)
      @forum_topic.save!
      #On success
      display_inline_forum_topic
    rescue
      #Re-Display on error
      respond_to do |format|
        format.html { render :action => 'edit' and return }
        format.js { render :action => 'edit', :layout => false and return }
        format.xml { }
      end
    end
  end

  def destroy
    return unless admin?
    ### TURNED OFF FOR NOW ### @forum_topic.destroy
    debugger
    message = "Topic '{title}' was deleted."[:forum_topic_deleted_message, CGI::escapeHTML(@forum_topic.title)]
    respond_to do |format|
      format.html { flash[:notice] = message; redirect_to home_path() }
      format.js { render :partial => "layouts/message", :status => "200 OK", :locals => { :message => message }, :layout => false }
      format.xml  { head 200 }
    end
  end

  def solve_question
    #Only the current user can mark question as solved
    if @forum_topic.type == 'Question' and @forum_topic.editable_by?(current_user)
      @post = ForumPost.find_by_id(params[:post_id])
      if @forum_topic.id == @post.topic.id and @post.first_post_flag !=1 # Cannot mark original post as solution
        # Toggle as solved / unsolved
        @forum_topic.solution_post_id = (@forum_topic.solution_post_id == params[:post_id].to_i ? 0 : params[:post_id].to_i)
        @forum_topic.solved_at = Time.now.utc  
        @forum_topic.save!
      end
    end
    respond_to do |format|
      render :json => (true).to_json and return
    end
  end

  def monitor
    @monitorship = Monitorship.find_or_initialize_by_user_id_and_collection_id(current_user.id, params[:forum_topic_id])
    if !@monitorship.new_record?
      active = (@monitorship.active ? false : true)
      Monitorship.update_all( ['active = ?', active], ['user_id = ? and collection_id = ?', current_user.id, params[:forum_topic_id]] )
    else
      active = true
      @monitorship.update_attribute(:active, active)
    end
    respond_to do |format|
      render :json => (active).to_json and return
    end
  end

  protected
    def display_inline_forum_topic
      respond_to do |format|
        format.html { redirect_to(forum_topic_path(@forum_topic.forum_id, @forum_topic.id)) and return }
        format.js  { redirect_to(forum_topic_path(@forum_topic.forum_id, @forum_topic.id, :format => :js)) and return }
        format.xml { return }
      end
    end

    def get_question_forum
      return Forum.find_by_title('Everything')
    end
    
    def assign_protected_values(form_fields)
      # Only admin or new record can changeform_fields user_id/topic.id
      if @forum_topic.editable_by?(current_user) or @forum_topic.new_record?
        @forum_topic.user = current_user
        @forum_topic.tags = form_fields[:tags]
        @forum_topic.forum_id = params[:selected_forum_id] if params[:selected_forum_id]
      end
      # Only owner/admin/moderator can change topic type or lock/sticky topics
      if admin? or @forum_topic.user_id == current_user.id or current_user.forum_moderator_of?(@forum_topic.forum)
        @forum_topic.sticky, @forum_topic.suspended = form_fields[:sticky], form_fields[:suspended]
        @forum_topic.tags = form_fields[:tags]
      end
      return unless admin?
      # Only admins can move topics
      @forum_topic.forum_id = params[:selected_forum_id] if params[:selected_forum_id]
      ## Only admins can delete topics
      ## @forum_topic.deleted = form_fields[:deleted] if form_fields[:deleted]
    end

    def find_forum_and_topic
      @forum = Forum.find(params[:forum_id]) if params[:forum_id]
      @forum_topic = ForumTopic.find(params[:id]) if params[:id]
      @post = ForumPost.find_by_id(params[:post_id]) if params[:post_id]
    end
    
    def load_forum_topic
      # Track when we last viewed this topic for activity indicators
      (session[:topics] ||= {})[@forum_topic.id] = Time.now.utc if logged_in?
      # Authors of topics don't get counted towards total hits
      @forum_topic.hit! if logged_in? and @forum_topic.user != current_user and session[:topics][@forum_topic.id].nil?
      @forum_posts = ForumPost.find_nested(@forum_topic.id, 30, params[:page])
      @forum = @forum_topic.forum if @forum.nil?
      @page_title = @forum_topic.title
      @monitoring = logged_in? && !Monitorship.count(:all, :conditions => ['user_id = ? and collection_id = ? and active = ?', current_user.id, @forum_topic.id, true]).zero?
    end

    def authorized?
      super || @forum_topic.editable_by?(current_user)
    end

    def prevent_further_changes
      # nothing yet!
    end

end