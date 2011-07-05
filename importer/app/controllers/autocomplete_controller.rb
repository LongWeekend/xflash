class AutocompleteController < ApplicationController

  include KanaHelp
  include Kana2rom
  
  def tags
    k = params[:key].nil? ? "" : params[:key]
    @tags = TagProxy.get_cached_tags(k)
    out = @tags.collect { |t| [t.name, t.name, "<span class='tags'>#{t.name}</span>", ''] } #use tag.name as unique identifier!
    render :text => out.to_json
  end

  def scrap_topics
    q = KanaHelp::to_utf8_strip(params[:q])
    q = KanaHelp::hankaku_kuuhaku(Kconv.toutf8(q.strip)).split(' ').collect {|w| "*#{w}*"}.join(" | ").gsub("**","*")
    q = Kana2rom::kana2kana(q).join(" | ")
    @titles = CollectionsByScrapTopicOrDefinitionTitle.search q, :sort_by=> "text ASC", :per_page => 25, :page => 1, :match_mode => :boolean
    return_entries(@titles, "text")
  end

  def link_collections
    q = KanaHelp::to_utf8_strip(params[:q])
    @linkables = ScrapTopic.find(:all, :conditions => ["title LIKE ?", "#{q}%"], :order => 'title ASC', :select =>"title") unless q.empty?
    @linkables ||= ScrapTopic.find(:all, :order => 'title ASC', :select =>"title")
    return_entries(@linkables, "title")
  end

  def link_scraps
    q = KanaHelp::to_utf8_strip(params[:q])
    @linkables = Scrap.find(:all, :conditions => ["title LIKE ?", "#{q}%"], :order => 'title ASC', :select =>"title") unless q.empty?
    @linkables ||= Scrap.find(:all, :order => 'title ASC', :select =>"title")
    return_entries(@linkables, "title")
  end
  
  private
    def return_entries(collection, field)
      a = []
      collection.each { |l| a << l.attributes[field] } #seems to be necessary for Japanese text strings!!
      render :text => a.join("\n")
    end
end