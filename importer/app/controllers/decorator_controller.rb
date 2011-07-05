class DecoratorController < ApplicationController

  def navigation
    render :partial => "layouts/navigation", :layout => false
  end

end