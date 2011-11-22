class SearchController < ApplicationController
#  require 'open-uri'
#  require 'rss/2.0'
#  include EasyMeCab
#  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :index }

  include KanaHelp
  include Kana2rom

  def search
    @per_page = (params[:per_page].to_i > 0 ? params[:per_page] : 20).to_i
    @page = (params[:page].to_i > 0 ? params[:page] : 1).to_i

    if !params[:q].nil? or !params[:t].nil?
      if params[:model] == "Question"
        @search_model = "Question"
        partial = "question_search_results"
        question_search
      elsif params[:model] == "User"
        @search_model = "User"
        partial = "user_search_results"
        user_search
      elsif params[:model] == "Tag"
        @search_model = "Tag"
        partial = "tag_search_results"
        tag_search
      else #if params[:model] == "Scrap"
        @search_model = "Scrap"
        partial = "scrap_search_results"
        scrap_search
      end
    end
    ### "0" denotes last page of search
    @next_page = ( @search && (@page*@per_page) <= @search.total_entries.to_i ? @page + 1 : 0 )
    render_search_results(partial)
  end

  def user_search
    @search_count = User.count
    @search = User.paginate(
      :page =>params[:page], 
      :per_page => @per_page, 
      :order => "display_name", 
      :conditions => User.build_search_conditions( allow_wildcards(params[:q]) )
    )
  end

  def tag_search
    @search_count = Tag.count
    @search = Tag.paginate(
      :page =>params[:page], 
      :per_page => @per_page, 
      :conditions => ['name LIKE ?',"%#{ allow_wildcards(params[:q]) }%"], 
      :order => 'name ASC'
    )
  end
  
  def question_search
    q=allow_wildcards(params[:q])
    type_cond = "AND solution_post_id = 0" if params[:type] == "answered"
    type_cond = "AND solution_post_id <> 0" if params[:type] == "unanswered"
    type_cond ||= ""
    sort_order = "collections.last_activity_at DESC" if params[:type] == "popular"
    sort_order = "collections.created_at DESC"
    @search = Question.paginate(:all,
      :page =>params[:page], 
      :per_page => @per_page, 
      :include => :posts,
      :conditions => ["(collections.title LIKE ? OR posts.body LIKE ?) AND collections.deleted_at IS NULL AND posts.deleted_at IS NULL #{type_cond}", "%#{q}%","%#{q}%"], :order => sort_order
    )
  end
  
  def scrap_search
    # Not so DRY, duplicated in autocomplete controller!
    q = (params[:q].nil? ? "" : params[:q])
    q = KanaHelp::hankaku_kuuhaku(Kconv.toutf8(q.strip)).split(' ').collect {|w| "*#{w}*"}.join(" | ").gsub("**","*")
    q = Kana2rom::kana2kana(q).join(" | ")
    t = (params[:t].nil? ? "" : tag_names_to_ids(params[:t]))

    if q.blank?
      @search = ScrapPage.search :conditions => { :tag_ids => t }, :sort_by=> "title ASC", :per_page => @per_page, :page => @page
    elsif t.blank?
      @search = ScrapPage.search q, :sort_by=> "title ASC", :per_page => @per_page, :page => @page, :match_mode => :boolean
    else
      @search = ScrapPage.search q, :conditions => { :tag_ids => t }, :sort_by=> "title ASC", :per_page => @per_page, :page => @page, :match_mode => :boolean
    end
  end

  def render_search_results(partial_name)
    if defined?(@search)
      ## Sphinx or DB search?
      the_count = ( defined?(@search.results) ? @search.results.size : @search.size)
    else
      the_count = 0
    end
    respond_to do |format|
      format.html { render :layout => "search" }
      format.js { ( params[:more] && @search && the_count ? (render :partial => partial_name, :layout => false) : (render :layout => false) ) }
      format.xml { return }
    end
  end

  def external_search
=begin
### This code is way old .... not used currently
    @per_page = (params[:per_page].to_i > 0 ? params[:per_page] : 50).to_i
    @page = (params[:page].to_i > 0 ? params[:page] : 1).to_i
    @scope = ( !params[:s].nil? ? params[:s] : 'w' )
    @scope.each do | s |
      if s == "wkpd"
        feed_url = 'http://pipes.yahoo.com/npedia/wpedia?_render=rss&query=' + URI.encode(params[:q])
        output = "" 
        open(feed_url) do |http|
          response = http.read
          @wkpd_result = RSS::Parser.parse(response, false)
        end
      end
      if s == "web"
        feed_url = 'http://pipes.yahoo.com/npedia/msnjp?_render=rss&q=' + URI.encode(params[:q])
        output = "" 
        open(feed_url) do |http|
          response = http.read
          @wkpd_result = RSS::Parser.parse(response, false)
        end
      end
    end
=end
  end

  private
    def allow_wildcards(q)
      return (q == "*" ? "%" : q)
    end

    def tag_names_to_ids(str = "")
      return ""  if str.length < 1
      ### Replace random delimiters with commas and pass along!
      tmp = str.gsub(/[ |\;]/, ",").gsub(/[,]+/, ",").split(",")
      ### Create OR statement, escape single quotes manually
      or_statement = tmp.collect { |s| ["name='#{s.strip.to_s.gsub(/'/, "''")}'", ] }.join(" OR ")
      if or_statement
        ### Return tag ids as list of ids
        Tag.find(:all, :conditions => or_statement).collect { |t| t.id.to_s }.join(",")
      else
        ""
      end
    end
end