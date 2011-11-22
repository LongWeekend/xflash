class TagMatchingResolutionChoicesController < ApplicationController
  # GET /tag_matching_resolution_choices
  # GET /tag_matching_resolution_choices.xml
  def index
    @tag_matching_resolution_choices = TagMatchingResolutionChoice.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tag_matching_resolution_choices }
    end
  end

  # GET /tag_matching_resolution_choices/1
  # GET /tag_matching_resolution_choices/1.xml
  def show
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag_matching_resolution_choice }
    end
  end

  # GET /tag_matching_resolution_choices/new
  # GET /tag_matching_resolution_choices/new.xml
  def new
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag_matching_resolution_choice }
    end
  end

  # GET /tag_matching_resolution_choices/1/edit
  def edit
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.find(params[:id])
  end

  # POST /tag_matching_resolution_choices
  # POST /tag_matching_resolution_choices.xml
  def create
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.new(params[:tag_matching_resolution_choice])

    respond_to do |format|
      if @tag_matching_resolution_choice.save
        format.html { redirect_to(@tag_matching_resolution_choice, :notice => 'Tag matching resolution choice was successfully created.') }
        format.xml  { render :xml => @tag_matching_resolution_choice, :status => :created, :location => @tag_matching_resolution_choice }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag_matching_resolution_choice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tag_matching_resolution_choices/1
  # PUT /tag_matching_resolution_choices/1.xml
  def update
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.find(params[:id])

    respond_to do |format|
      if @tag_matching_resolution_choice.update_attributes(params[:tag_matching_resolution_choice])
        format.html { redirect_to(@tag_matching_resolution_choice, :notice => 'Tag matching resolution choice was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag_matching_resolution_choice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tag_matching_resolution_choices/1
  # DELETE /tag_matching_resolution_choices/1.xml
  def destroy
    @tag_matching_resolution_choice = TagMatchingResolutionChoice.find(params[:id])
    @tag_matching_resolution_choice.destroy

    respond_to do |format|
      format.html { redirect_to(tag_matching_resolution_choices_url) }
      format.xml  { head :ok }
    end
  end
end
