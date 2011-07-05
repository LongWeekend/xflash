module TiddlerActions

  #
  # (nil) cancel_request_msg : Renders "cancelled" status in a tiddler msg
  #
  def cancel_request_msg
    message = 'Cancelled'[:message_action_cancelled]
    respond_to do |format|
      format.html { redirect_to home_path() }
      format.js { render :partial => "layouts/message", :status => "200 OK", :locals => {:message => message}, :layout => false }
      format.xml { }
    end
  end

  #
  # (boolean) cancelled? : Renders "cancelled" status if form param exists
  #
  def cancelled?
    if params[:cancel]
      cancel_request_msg
      return true
    else
      return false
    end
  end

end