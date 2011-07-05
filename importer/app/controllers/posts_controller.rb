class PostsController < ApplicationController

  before_filter :load_post, :only => [:show, :edit, :update, :destroy, :vote_up, :vote_down, :star_rating, :abuse]
  before_filter :login_required, :except => [:index, :monitored, :search, :show]
  @@query_options = { :per_page => 25, :select => 'posts.*, forum_topics.title as topic_title, forums.title as forum_name', :joins => 'inner join collections forum_topics on (posts.collection_id = forum_topics.id and forum_topics.type="ForumTopic") inner join collections forums on (forum_topics.parent_id = forums.id and forums.type="Forum")', :order => 'posts.created_at desc' }
## This is killing mongrel on the production server!
## include RubyTidy

  def monitored
    @user = User.find params[:user_id]
    options = @@query_options.merge(:conditions => ['monitorships.user_id = ? and posts.user_id != ? and monitorships.active = ?', params[:user_id], @user.id, true])
    options[:joins] += ' inner join monitorships on monitorships.collection_id = forum_topics.id'
    @forum_posts = paginate(:forum_posts, options)
    render_posts_or_xml
  end

  def show
    @post = ForumPost.new
    respond_to do |format|
      format.html { redirect_to forum_topics_path(@forumpost.forum_id, @post.collection_id) }
      format.xml  { render :xml => @post.to_xml }
    end
  end

  def edit
    respond_to do |format| 
      format.html
      format.js
    end
  end
  
  def update
    @post.attributes = params[:forumpost]
    @post.save!
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'An error occurred'[:error_generic]
  ensure
    respond_to do |format|
      format.html {redirect_to forum_topics_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page] || '1') }
      format.js { }
      format.xml { head 200 }
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "Post of '{title}' was deleted."[:post_deleted_message, CGI::escapeHTML(@forumpost.topic.title)]

    # check for posts_count == 1 because its cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_path(params[:forum_id]) if @post.topic.posts_count == 1
    respond_to do |format|
      format.html do
        redirect_to forum_topics_path(:forum_id => params[:forum_id], :id => params[:topic_id], :page => params[:page]) unless performed?
      end
      format.xml { head 200 }
    end
  end

  def vote_up
    Vote.up(@post, current_user) if @post
    if params[:ajax]
      rjs_render_post_vote_response(current_user)
      return
    else
      redirect_to(request.env["HTTP_REFERER"] + "#talk#{@post.id}")
    end
  end
  
  def vote_down
    Vote.down(@post, current_user) if @post
    if params[:ajax]
      rjs_render_post_vote_response(current_user)
      return
    else
      redirect_to(request.env["HTTP_REFERER"] + "#talk#{@post.id}")
    end
  end
  
  def abuse
    if @post.user_id == current_user.id
      msg = 'Sorry, no self voting!'[:error_no_self_voting]
    elsif @post
      v = Vote.abuse(@post, current_user)
      msg = (v==true ? 'Abuse reported!'[:msg_abuse_reported] : 'Abuse report retracted!'[:msg_abuse_report_retracted] )
    else
      msg = 'Post not found!'[:error_post_not_found]
    end
    if params[:ajax]
      render(:update) { |pg| pg.alert(msg) } and return
    else
      flash[:notice] = msg
      redirect_to(request.env["HTTP_REFERER"] + "#talk#{@post.id}")
    end
  end

  def star_rating
    Vote.rating(@post, current_user, params[:star_rating]) if @post
    redirect_to(request.env["HTTP_REFERER"] + "#talk#{@post.id}")
  end

  def rjs_render_post_vote_response(current_user)
    render(:update) do |pg|
      if @post.user_id == current_user.id
        pg.alert('Sorry, no self voting!'[:error_no_self_voting])
      else
        pg.replace_html("post#{@post.id}_ups", @post.votes_up.count)
        pg.replace_html("post#{@post.id}_downs", @post.votes_down.count)
        pg.replace_html("total_up_votes", @post.topic.post_votes_up.count)
        pg.replace_html("total_down_votes", @post.topic.post_votes_down.count)
      end
    end
  end

  def talkabout_topic
    @post = ForumPost.new
## This is killing mongrel on the production server!
## @post.body = tidy(params[:forumpost][:body])
    @post.body = white_list(params[:forumpost][:body])
    @post.parent_id = params[:forumpost][:parent_id].to_i || 0
    @post.collection_id = ForumTopic.find_by_id(params[:topic_id]).id
    @post.user_id = current_user.id
    @post.save!
    respond_to do |format|
      format.html { redirect_to(request.env["HTTP_REFERER"] + "#talk#{@post.id}") }
    end
  end

  def talkabout_scrap
    @post = TalkPost.new
    @post.body = params[:talkpost][:body]
    @post.parent_id = params[:talkpost][:parent_id].to_i || 0
    @post.scrap_id = Page.find_by_id(params[:id]).id
    @post.user_id = current_user.id
    @post.save!
    respond_to do |format|
      format.html { redirect_to(request.env["HTTP_REFERER"]) }
    end
  end

  protected
    def authorized?
      action_name == 'create' || 'talkabout_post' || 'talkabout_page' || @post.editable_by?(current_user)
    end
    
    def load_post
      post_id = params[:id] if(params[:id])
      post_id ||= params[:post_id] if(params[:post_id])
      @post = TalkPost.find_by_id(post_id) || raise(ActiveRecord::RecordNotFound) if params[:class_type] == 'talk'
      @post ||= ForumPost.find_by_id(post_id) || raise(ActiveRecord::RecordNotFound)
      ###if(post_id && params[:topic_id] && params[:forum_id])
      ###@post = Post.find_by_id_and_topic_id_and_forum_id(params[:id], params[:topic_id], params[:forum_id]) || raise(ActiveRecord::RecordNotFound)
    end
    
    def render_posts_or_xml(template_name = action_name)
      respond_to do |format|
        format.html { render :action => "#{template_name}.rhtml" }
        format.rss  { render :action => "#{template_name}.rxml", :layout => false }
        format.xml  { render :xml => @posts.to_xml }
      end
    end
end