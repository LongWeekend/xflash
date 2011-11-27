class EntryController < ApplicationController
  def search
    query_string = params[:query]
    
    select_sql = "SELECT * FROM cards_staging WHERE (headword_trad LIKE '%s%%' OR headword_simp LIKE '%s%%')" % [query_string, query_string]
    entries = Entry.find_by_sql(select_sql)
    @results = []
    entries.each do |entry|
      @results << entry
    end
  
    @exception_id = params[:exc_id] 
    @include_blank = (@results.count > 1) ? true : false
 
    respond_to do |format|
      format.js
      format.html # search.html.erb
      format.xml  { render :xml => @tag_matching_exceptions }
    end
  end

end
