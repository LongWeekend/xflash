class DocumentationController < ApplicationController

  layout "search"
  caches_action :index, :credits

  def index
    respond_to do |format|
      format.html { render :action => 'index' and return }
      format.js { render :action => 'index', :layout => false and return }
      format.xml { return }
    end
  end

  def about
    respond_to do |format|
      format.html { render :action => 'about' and return }
      format.js { render :action => 'about', :layout => false and return }
      format.xml { return }
    end
  end

end