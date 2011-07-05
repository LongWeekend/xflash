#
#  ABOUT: This controller provides the interface for Page class objects. Inherits from Pages, every core asset is a page
# 
class PagesController < ApplicationController   # < ScrapController ??
  before_filter :login_required, :except => [:index, :show, :popup, :credits]
  before_filter :load_book, :except => [:index, :credits]
  before_filter :load_page, :except => [:index, :new, :create]
  before_filter :load_tree, :only => [:show, :wikidiff, :compare]
  before_filter :load_parent, :only => [:new, :create]

  def credits
    #nuthin!
  end

  def show
    redirect_to( :action => "edit", :title => @title ) and return if @page.new_record?
    @talkposts = TalkPost.find_nested(@page.id, 30, params[:page])
  end

  def edit

  end

  def index
    @results = Page.find(:all, :include=> :revisions, :page => {:size => 10, :current => params[:page]}, :order => 'revisions.created_at ASC')
  end

  def new
    @page = Page.new
    @page.parent_id = @parent.id if @parent
    @page.book = @book if @book
  end

  def create
    @page = Page.new(params[:page])
    @page.parent_id = @parent.id if @parent
    @page.book = @book if @book
    @page.user_id = current_user.id
    begin
      @page.save!(current_user)
      redirect_to_current_page
    end
   rescue
    #form error
    render :action => "new", :book_id => params[:book_id]
    return
  end

  def update
    unless @page
      flash[:error] = 'The page you are editing cannot be found. Try adding it instead!'
      redirect_to_current_page
    end

    #Display form
    if params[:page].nil?
      @content = @page.content unless @page.new_record?
      render :action => "edit" and return
    end

    # Proceed to save if changed
    if changed?
      @page.title = params[:page][:title]
      @page.content = params[:page][:content]
      @page.tags = params[:page][:tags]
      if @page.save!
        flash[:notice] = 'Page updated successfully!'[:msg_page_update_success]
      end
    else
     flash[:bad_reply] = 'Nothing changed, page not updated!'[:msg_page_not_changed]
    end
    redirect_to_current_page
  end

  def remove
    #Display confirmation form
    if params[:page].nil?
      render :action => "confirm" and return
    end
    # Use transaction
    #List all sub-pages and confirm deletion OR ask for new parent location (prune or pluck sub-nodes)
      # case: PRUNE
          # delete current and all sub
      # case: PLUCK
          # delete current and promote all sub-nodes one level 
      # __ NB: Deletion should be non-destructive (for now, keep in same table!)
  end

  def changed?
    !( @page.content.eql?(params[:page][:content]) && @page.title.eql?(params[:page][:title]) )
  end

  def compare
    if params[:compare] and params[:compare].length == 2
      a = params[:compare][0].to_i
      b = params[:compare][1].to_i
    elsif params[:revid] and params[:revid2]
      a = params[:revid].to_i
      b = params[:revid2].to_i
    else
      flash[:bad_reply] = 'Incomplete request'[:error_incomplete_request]
      redirect_to_current_page and return
    end
    @comparison = @page.compare(a,b)
    render :action => "show" and return
  end

  private
    def load_parent
      # load and set parent page
      if params[:parent_id] and params[:parent_id] != 0
        @parent = Page.find_by_id(params[:parent_id])
      end
    end
    
    def redirect_to_current_page
      respond_to do |format|
        format.html { redirect_to book_page_path(@page.book.slug, @page.slug) }
      end
    end

    def load_book
      @book = Book.find_by_id(params[:book_id]) if (params[:book_id] and params[:book_id].to_i > 0)
      @book ||= Book.find_by_slug_cache(params[:book_id]) if params[:book_id]
      render_404 and return if @book.nil?
    end

=begin
# This probably belongs here?? Moved form scraps_controller.rb
    def load_page
      #@scrap = Scrap.find_by_id(params[:id]) if (params[:id] and params[:id].to_i > 0)
      #@scrap ||= Page.find_by_slug_cache(params[:id]) if params[:id]
      #render_404 and return if @page.nil?

      #Load parent page if id provided
      @parent_page = Page.find_by_id(params[:parent_id]) if params[:parent_id]

      #Load Revision most recent or by revid
      @revision_displayed = @page.revisions.find_by_id(params[:revid]) if params[:revid]
      @revision_displayed ||= @page.revisions.find(:first, :order =>'revisions.created_at DESC')
      @revision_displayed ||= @page.revisions.last

      #Get next or previous revision ID (relative to current)
      @revision_displayed_alt = @page.revisions.find(:first, :conditions => "revisions.id < '#{@revision_displayed.id}'", :order => "revisions.created_at DESC")
      @revision_displayed_alt ||= @page.revisions.find(:first, :conditions => "revisions.id > '#{@revision_displayed.id}'", :order => "revisions.created_at ASC")
    end
=end

    def load_page
      @page = Page.find_by_id_and_collection_id(params[:id], @book.id) if (params[:id] and params[:id].to_i > 0)
      @page ||= Page.find_by_slug_cache_and_collection_id(params[:id], @book.id) if params[:id]
      #render_404 and return if @page.nil?

      #Load parent page if id provided
      @parent_page = Page.find_by_id(params[:parent_id]) if params[:parent_id]

      #Load Revision most recent or by revid
      @revision = @page.revisions.find_by_id(params[:revid]) if params[:revid]
      @revision ||= @page.revisions.find(:first, :order =>'revisions.created_at DESC')
      @revision ||= @page.revisions.last
    end
 
    def load_tree
      @tree = @page.book.tree
      @load_trees = true
    end
    
    def assign_protected_values
      # Only admin or new record can delete
      return unless admin?
      @page.deleted = params[:page][:deleted]
    end
end