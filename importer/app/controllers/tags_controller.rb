class TagsController < ApplicationController

  def index
    @tags = Tag.find(:all, :order => "name ASC")
  end

  ## DEPRECATED
  #def show
  #  redirect_to(:controller => 'search', :action => 'search', :q => "", :t => params[:t], :format => :js)
  #end

end