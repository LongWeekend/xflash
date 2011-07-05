class ApplicationController < ActionController::Base

  ##init_gettext "npedia" if Object.const_defined?(:GetText)
  include BrowserFilters, AuthenticationSystem

  layout proc{ |c| c.request.xhr? ? false : "application" }
  helper_method :current_user, :logged_in?, :admin?, :last_active
  before_filter :login_by_token

  unless ActionController::Base.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError, ActionController::UnknownController, ActionController::UnknownAction, :with => :render_404
    rescue_from RuntimeError, :with => :render_500
  end

  protected
    def last_active
      session[:last_active] ||= Time.now.utc
    end
    
    # Rescue Unauthorized errors!
    def render_401
      respond_to do |format|
        format.html { render :template => "errors/401", :status => :unauthorized, :layout => "search" }
        format.js   { render :template => "errors/401", :status => :unauthorized, :layout => false }
        format.xml  { render :nothing => true, :status => :not_found }
      end
    end

    # Rescue ActiveRecord::NotFound && NotFound errors!
    def render_404
      respond_to do |format|
        format.html { render :template => "errors/404", :status => :not_found, :layout => "search" }
        format.js   { render :template => "errors/404", :status => :not_found, :layout => false }
        format.xml  { render :nothing => true, :status => :not_found }
      end
    end

    # Rescue Server errors!
    def render_500
      respond_to do |format|
        format.html { render :template => "errors/500", :status => :internal_server_error, :layout => "search" }
        format.js   { render :template => "errors/500", :status => :internal_server_error, :layout => false }
        format.xml  { render :nothing => true, :status => :internal_server_error }
      end
    end

    def rescue_action_in_public(exception)
      exception.is_a?(ActiveRecord::RecordNotFound) ? render_404 : super
    end

    def rescue_action(exception)
      exception.is_a?(ActiveRecord::RecordInvalid) ? render_invalid_record(exception.record) : super
    end

    #Handles form redirection when validaton fails
    def render_invalid_record(record)
      render :action => (record.new_record? ? 'new' : 'edit')
    end

end

## Bot sessions blocker
## http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
class Util
  def Util.is_megatron?(user_agent)
    user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
  end
end
## END Bot sessions blocker

## Custom error validation markup
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  msg = instance.error_message
  msg = msg.kind_of?(Array) ? '* ' + msg.join("\n* ") : msg
  %(#{html_tag}<div class='validation-error'><span>#{msg}</span></div>)
end