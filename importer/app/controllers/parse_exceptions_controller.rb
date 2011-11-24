class ParseExceptionsController < ApplicationController
  # GET /parse_exceptions
  # GET /parse_exceptions.xml
  def index
    @parse_exceptions = ParseException.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @parse_exceptions }
    end
  end

  # GET /parse_exceptions/1
  # GET /parse_exceptions/1.xml
  def show
    @parse_exception = ParseException.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @parse_exception }
    end
  end

  # GET /parse_exceptions/new
  # GET /parse_exceptions/new.xml
  def new
    @parse_exception = ParseException.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @parse_exception }
    end
  end

  # GET /parse_exceptions/1/edit
  def edit
    @parse_exception = ParseException.find(params[:id])
  end

  # POST /parse_exceptions
  # POST /parse_exceptions.xml
  def create
    @parse_exception = ParseException.new(params[:parse_exception])

    respond_to do |format|
      if @parse_exception.save
        format.html { redirect_to(@parse_exception, :notice => 'Parse exception was successfully created.') }
        format.xml  { render :xml => @parse_exception, :status => :created, :location => @parse_exception }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @parse_exception.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /parse_exceptions/1
  # PUT /parse_exceptions/1.xml
  def update
    @parse_exception = ParseException.find(params[:id])

    respond_to do |format|
      if @parse_exception.update_attributes(params[:parse_exception])
        format.html { redirect_to(@parse_exception, :notice => 'Parse exception was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @parse_exception.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /parse_exceptions/1
  # DELETE /parse_exceptions/1.xml
  def destroy
    @parse_exception = ParseException.find(params[:id])
    @parse_exception.destroy

    respond_to do |format|
      format.html { redirect_to(parse_exceptions_url) }
      format.xml  { head :ok }
    end
  end
end
