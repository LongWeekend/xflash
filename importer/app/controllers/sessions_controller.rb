class SessionsController < ApplicationController

  before_filter :login_required, :only => :spoof_user
  layout "search"

  def create
    # Store the page the user clicked in from
    session[:login_referrer] = request.env['HTTP_REFERER'] unless params[:login]
    if logged_in?
      respond_to do |format|
        format.html { redirect_to home_path }
        format.js { render :partial => "layouts/message", :locals => {:message => "You are already logged in. Look up and click 'logout' if you want!"[:message_already_authenticated] }, :layout => false }
        format.xml { return }
      end
    elsif params[:login].nil?
      respond_to do |format|
        format.html { return }
        format.js { render :partial => "create", :layout => false and return }
        format.xml { return }
      end
      return
    elsif open_id?(params[:login])
      open_id_authentication params[:login]
    else
      password_authentication params[:login], params[:password]
    end
  end
  
  def destroy
    viewed_topics = session[:topics]
    reset_session
    cookies.delete :login_token
    session[:topics] = viewed_topics
    message = "You have been logged out."[:msg_logged_out]
    respond_to do |format|
      format.html { flash[:notice] = message and redirect_to "/" }
      format.js { render :partial => "layouts/message", :locals => {:message => message }, :layout => false }
      format.xml { return }
    end
  end

  def spoof_user
    if admin?
      reset_session
      cookies.delete :login_token
      self.current_user = User.find_by_id(params[:id])
      successful_login(user_path(current_user.id))
    else
      redirect_to home_path
    end
  end

  protected
    def open_id_authentication(identity_url)
      authenticate_with_open_id(identity_url, :required => [:nickname, :email], :optional => :fullname) do |status, identity_url, registration|
      case status
        when :missing
          failed_login "Sorry, the OpenID server couldn\'t be found"[:msg_openid_not_found]
        when :canceled
          failed_login "OpenID verification was canceled"[:msg_openid_canceled]
        when :failed
          failed_login "Sorry, the OpenID verification failed"[:msg_openid_failed]
        when :successful
          if self.current_user = User.find_or_initialize_by_identity_url(identity_url)
            {'login=' => 'nickname', 'email=' => 'email', 'display_name=' => 'fullname'}.each do |attr, reg|
              current_user.send(attr, registration[reg]) unless registration[reg].blank?
            end
            unless current_user.save
              flash[:error] = "Error saving the fields from your OpenID profile at {identity_url}: {errors}"[:error_openid_saving, identity_url.inspect, current_user.errors.full_messages.to_sentence]
            end
          #these 5 lines need testing!
            viewed_topics = session[:topics]
            reset_session
            cookies.delete :login_token
            session[:topics] = viewed_topics
            successful_login(session[:login_referrer])
          #successful_login
          else
            failed_login "Sorry, no user by the identity URL {identity_url} exists"[:msg_openid_no_user, identity_url.inspect]
          end
        end
      end
    end

    def password_authentication(name, password)
      login_referrer = session[:login_referrer] if session[:login_referrer]
      viewed_topics = session[:topics]
      reset_session
      cookies.delete :login_token
      if self.current_user = User.authenticate(name, password)
        session[:topics] = viewed_topics
        successful_login(login_referrer)
      else
        if User.authenticate(name, password, false)
          failed_login "This account is not yet activated. Please check your email!"[:error_account_inactive]
        else
          failed_login "Invalid login or password, please try again."[:error_invalid_login]
        end
      end
    end

    def successful_login(location=nil)
      cookies[:login_token] = {:value => "#{current_user.id};#{current_user.reset_login_key!}", :expires => Time.now.utc+1.year} if params[:remember_me] == "1"
      cookies[:login_token] = {:value => "#{current_user.id};#{current_user.reset_login_key!}", :expires => 1.hour.from_now }
      respond_to do |format|
        format.html { (location.nil? ? redirect_to(home_path) : redirect_to(location) ) }
        format.js { render :partial => "layouts/message", :locals => {:message => 'You are now logged in'[:message_login_successful] }, :layout => false }
        format.xml { return }
      end
    end

    def failed_login(message)
      respond_to do |format|
        format.html { flash[:error] = message and render :action => 'create', :status => :unauthorized and return }
        format.js { render :partial => "layouts/status_message", :status => :unauthorized, :locals => {:message => message }, :layout => false }
        format.xml { return }
      end
    end
end
