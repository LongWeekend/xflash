class TagMatchingExceptionsController < ApplicationController
  # GET /tag_matching_exceptions
  # GET /tag_matching_exceptions.xml
  def index
    @tag_matching_exceptions = TagMatchingException.all_unmatched_and_has_options

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tag_matching_exceptions }
    end
  end

  # GET /tag_matching_exceptions/1
  # GET /tag_matching_exceptions/1.xml
  def show
    @tag_matching_exception = TagMatchingException.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag_matching_exception }
    end
  end
  
  def update_all
    
  end

  # GET /tag_matching_exceptions/new
  # GET /tag_matching_exceptions/new.xml
  def new
    @tag_matching_exception = TagMatchingException.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag_matching_exception }
    end
  end

  # GET /tag_matching_exceptions/1/edit
  def edit
    @tag_matching_exception = TagMatchingException.find(params[:id])
  end

  # POST /tag_matching_exceptions
  # POST /tag_matching_exceptions.xml
  def create
    @tag_matching_exception = TagMatchingException.new(params[:tag_matching_exception])

    respond_to do |format|
      if @tag_matching_exception.save
        format.html { redirect_to(@tag_matching_exception, :notice => 'Tag matching exception was successfully created.') }
        format.xml  { render :xml => @tag_matching_exception, :status => :created, :location => @tag_matching_exception }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag_matching_exception.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /tag_matching_exceptions/1
  # PUT /tag_matching_exceptions/1.xml
  def update
    @tag_matching_exception = TagMatchingException.find(params[:id])

    respond_to do |format|
      if @tag_matching_exception.update_attributes(params[:tag_matching_exception])
        format.html { redirect_to(:action => :index) }
#        format.html { redirect_to(@tag_matching_exception, :notice => 'Tag matching exception was successfully updated.') }
        format.xml  { head :ok }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag_matching_exception.errors, :status => :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /tag_matching_exceptions/1
  # DELETE /tag_matching_exceptions/1.xml
  def destroy
    @tag_matching_exception = TagMatchingException.find(params[:id])
    @tag_matching_exception.destroy

    respond_to do |format|
      format.html { redirect_to(tag_matching_exceptions_url) }
      format.xml  { head :ok }
    end
  end
end
