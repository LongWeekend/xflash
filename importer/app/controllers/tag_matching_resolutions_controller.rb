class TagMatchingResolutionsController < ApplicationController
  # GET /tag_matching_resolutions
  # GET /tag_matching_resolutions.xml
  def index
    @tag_matching_resolutions = TagMatchingResolution.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tag_matching_resolutions }
    end
  end

  # GET /tag_matching_resolutions/1
  # GET /tag_matching_resolutions/1.xml
  def show
    @tag_matching_resolution = TagMatchingResolution.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag_matching_resolution }
    end
  end

  # GET /tag_matching_resolutions/new
  # GET /tag_matching_resolutions/new.xml
  def new
    @tag_matching_resolution = TagMatchingResolution.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag_matching_resolution }
    end
  end

  # GET /tag_matching_resolutions/1/edit
  def edit
    @tag_matching_resolution = TagMatchingResolution.find(params[:id])
  end

  # POST /tag_matching_resolutions
  # POST /tag_matching_resolutions.xml
  def create
    @tag_matching_resolution = TagMatchingResolution.new(params[:tag_matching_resolution])

    respond_to do |format|
      if @tag_matching_resolution.save
        format.html { redirect_to(@tag_matching_resolution, :notice => 'Tag matching resolution was successfully created.') }
        format.xml  { render :xml => @tag_matching_resolution, :status => :created, :location => @tag_matching_resolution }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag_matching_resolution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tag_matching_resolutions/1
  # PUT /tag_matching_resolutions/1.xml
  def update
    @tag_matching_resolution = TagMatchingResolution.find(params[:id])

    respond_to do |format|
      if @tag_matching_resolution.update_attributes(params[:tag_matching_resolution])
        format.html { redirect_to(@tag_matching_resolution, :notice => 'Tag matching resolution was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag_matching_resolution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tag_matching_resolutions/1
  # DELETE /tag_matching_resolutions/1.xml
  def destroy
    @tag_matching_resolution = TagMatchingResolution.find(params[:id])
    @tag_matching_resolution.destroy

    respond_to do |format|
      format.html { redirect_to(tag_matching_resolutions_url) }
      format.xml  { head :ok }
    end
  end
end
