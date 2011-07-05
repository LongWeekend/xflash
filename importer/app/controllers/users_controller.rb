class UsersController < ApplicationController

  before_filter :login_required, :only => [:edit, :update, :destroy, :make_admin, :login_as, :forum_moderator]
  before_filter :find_user,     :only => [:edit, :update, :destroy, :make_admin, :login_as]

  layout "search"

  def ajax_logged_in
    respond_to do |format|
      format.html { render :text => logged_in?, :layout => false and return }
      format.js { render :json => (logged_in?).to_json and return }
    end
  end

  def show
    if params[:id] == session[:user_id]
      @user = User.find(session[:user_id])
      @viewmode = 'private'
    else
      @user = User.find(params[:id])
      @viewmode = 'public'
    end
    respond_to do |format|
      format.html { }
      format.js { render :template => 'users/show', :layout => false and return }
      format.xml { render :xml => @user.to_xml }
    end
  end

  def new
    if logged_in?
      respond_to do |format|
        format.html { render :template => 'search/search' and return  }
        format.js { render :partial => "layouts/message", :locals => {:message => "You are already logged in"[:message_already_logged_in] }, :layout => false }
        format.xml { return }
      end
    end
    @user = User.new
    respond_to do |format|
      format.html { render :layout => "new" }
      format.js { render :template => 'users/new', :layout => false and return }
      format.xml { }
    end
  end
  
  def create
    @user = params[:user].blank? ? User.find_by_email(params[:email]) : User.new(params[:user])
    flash[:error] = "We could not find an account with email address '{email}'. Please check it was typed correctly?"[:error_account_not_found_message, CGI.escapeHTML(params[:email])] if params[:email] and not @user
    unless @user
      respond_to do |format|
        format.html {　flash[:error] = message and render :action => 'create', :status => :unauthorized and return　}
        format.js { render :partial => "layouts/status_message", :status => :unauthorized, :locals => {:message => message }, :layout => false　}
        format.xml { return }
      end
    end

    begin
      @user.login = params[:user][:login] unless params[:user].blank?
      @user.reset_login_key!
      # Send email when in production mode!
      UserMailer.deliver_signup(@user, request.host_with_port) if ENV['RAILS_ENV'] == 'production'
=begin
## THIS IS BROKEN ---
    rescue Net::SMTPFatalError => e
      flash[:notice] = "A permanent error occured while sending the signup message to '{email}'. Please check the e-mail address."[:signup_permanent_error_message, CGI.escapeHTML(@user.email)]
    rescue Net::SMTPServerBusy, Net::SMTPUnknownError, Net::SMTPSyntaxError, TimeoutError => e
      flash[:notice] = "The signup message cannot be sent to '{email}' at this moment. Please, try again later."[:signup_cannot_send_message, CGI.escapeHTML(@user.email)]
## ------------------
=end
    rescue
      respond_to do |format|
        format.html { redirect_to :action => "new" }
        format.js { render :template => "users/new", :layout => false and return }
        format.xml { return }
      end
    end

    # Signup success!
    success_msg = params[:email] ? "A registration activation email has been sent to '{email}'."[:registration_activation, CGI.escapeHTML(@user.email)] : "An account activation email has been sent to '{email}'."[:account_activation_message, CGI.escapeHTML(@user.email)]
    respond_to do |format|
      format.html { flash[:notice] = success_msg; (location.nil? ? redirect_to(home_path) : redirect_to(location) ); }
      format.js { render :partial => "layouts/message", :locals => {:message => success_msg }, :layout => false }
      format.xml { return }
    end
  end
  
  def activate
    self.current_user = User.find_by_login_key(params[:key])
    if logged_in? && !current_user.activated?
      current_user.toggle! :activated
      message = "Signup complete!"[:message_signup_complete]
    else
      message = "Invalid activation key!"[:message_activation_failed]
    end
    respond_to do |format|
      format.html { flash[:notice] = message and redirect_to home_path and return }
      format.js { render :partial => "layouts/message", :locals => {:message => message }, :layout => false }
      format.xml { return }
    end
  end

  def edit
    respond_to do |format|
      format.html { redirect_to settings_path(params[:user_id]) }
      format.js { render :template => "users/edit", :layout => false and return }
      format.xml  { head 200 }
    end
  end

  def update
    @user.attributes = params[:user]
    # temp fix to let people with dumb usernames change them
    @user.login = params[:user][:login] if not @user.valid? and @user.errors.on(:login)
    begin
      @user.save! and flash[:notice]="Your settings have been saved."[:msg_settings_saved]
      respond_to do |format|
        format.html { redirect_to edit_user_path(@user) }
        format.js { render :template => "users/edit", :layout => false and return }
        format.xml  { head 200 }
      end
    rescue
      respond_to do |format|
        format.html { redirect_to settings_path(params[:user_id]) }
        format.js { render :template => "users/edit", :layout => false and return }
        format.xml  { head 200 }
      end
    end
  end

  def make_admin
    respond_to do |format|
      format.html do
        if admin?
          @user.admin = params[:admin] == '1'
          @user.save
        end
        respond_to do |format|
          format.html { redirect_to user_path(@user) }
          format.js { render :template => "users/show", :layout => false and return }
          format.xml  { head 200 }
        end
      end
    end
  end

  def forum_moderator
    if m = Moderatorship.find_by_collection_id_and_type_and_user_id(params[:forum_id], Forum.to_s, params[:user_id])
      Moderatorship.delete_all ['collection_id = ? AND type = ? AND user_id = ?', params[:forum_id], Forum.to_s, params[:user_id]]
    elsif params[:forum_id] !=""
      if fid = Forum.find(params[:forum_id]).id
        m = Moderatorship.new
        m.collection_id = fid
        m.type = Forum.to_s
        m.user_id = params[:user_id]
        m.save
      end
    end
    respond_to do |format|
      format.html { redirect_to user_path(params[:user_id]) }
      format.js { render :template => "users/show", :layout => false and return }
      format.xml  { head 200 }
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_path }
      format.js { render :template => "users/index", :layout => false and return }
      format.xml  { head 200 }
    end
  end

  protected
    def authorized?
      admin? || (!%w(destroy make_admin forum_moderator).include?(action_name) && (params[:id].nil? || params[:id] == current_user.id.to_s))
    end
    
    def find_user
      @user = params[:id] ? User.find_by_id(params[:id]) : current_user
    end

end