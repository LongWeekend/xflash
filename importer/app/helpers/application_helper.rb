require 'md5'

module ApplicationHelper

  def submit_tag(value = "Save Changes"[], options={} )
    or_option = options.delete(:or)
    return super + "<span class='button_or'>"+"or"[]+" " + or_option + "</span>" if or_option
    super
  end

  def avatar_for(user, size=32)
    image_tag "http://www.gravatar.com/avatar.php?gravatar_id=#{MD5.md5(user.email)}&rating=PG&size=#{size}", :size => "#{size}x#{size}", :class => 'photo'
  end

  def feed_icon_tag(title, url)
    (@feed_icons ||= []) << { :url => url, :title => title }
    link_to image_tag('/images/smallicons/feed.png', :size => '14x14', :border=>'0', :style=>'padding-left:4px', :alt => "Subscribe to #{title}"), url
  end

  def search_posts_title
    returning(params[:q].blank? ? 'Recent Posts'[] : "Searching for"[] + " '#{h params[:q]}'") do |title|
      title << " "+'by {user}'[:by_user,h(User.find(params[:user_id]).display_name)] if params[:user_id]
      title << " "+'in {forum}'[:in_forum,h(Forum.find(params[:forum_id]).name)] if params[:forum_id]
    end
  end

  def search_posts_path(rss = false)
    options = params[:q].blank? ? {} : {:q => params[:q]}
    prefix = rss ? 'formatted_' : ''
    options[:format] = 'rss' if rss
    [[:user, :user_id], [:forum, :forum_id]].each do |(route_key, param_key)|
      return send("#{prefix}#{route_key}_posts_path", options.update(param_key => params[param_key])) if params[param_key]
    end
    options[:q] ? all_search_posts_path(options) : send("#{prefix}all_posts_path", options)
  end

  # strftime on windows doesn't seem to support %e and you'll need to 
  # use the less cool %d in the strftime line below
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
  
    case distance_in_minutes
      when 0..1           then (distance_in_minutes==0) ? 'a few seconds ago'[] : '1 minute ago'[]
      when 2..59          then "{minutes} minutes ago"[:minutes_ago, distance_in_minutes]
      when 60..90         then "1 hour ago"[]
      when 90..1440       then "{hours} hours ago"[:hours_ago, (distance_in_minutes.to_f / 60.0).round]
      when 1440..2160     then '1 day ago'[] # 1 day to 1.5 days
      when 2160..2880     then "{days} days ago"[:days_ago, (distance_in_minutes.to_f / 1440.0).round] # 1.5 days to 2 days
      else from_time.strftime("%b %e, %Y  %l:%M%p"[:format_datetime]).gsub(/([AP]M)/) { |x| x.downcase }
    end
  end

  # ==============================
  # WIKI HELPERS
  # ==============================

  def relative_time(from_time)
		from_time = from_time.to_time if from_time.respond_to?(:to_time)
		distance_in_minutes = (((Time.now - from_time).abs)/60).round

		case distance_in_minutes
			when 0..1					then (distance_in_minutes == 0) ? '< 1 min ago' : '1 min ago'
			when 2..45				then "#{distance_in_minutes} mins ago"
			when 46..90				then '1 hr ago'
			when 90..1049			then "#{(distance_in_minutes.to_f / 60.0).round} hrs ago"
			when 1050..2159		then "1 day ago"
			when 2160..8640		then "#{(distance_in_minutes / 1440.0).round} days ago"
			when 8641..10080	then '1 week ago'
			else
				from_time.strftime from_time.year == Time.now.year ? '%b %d' : '%b %d, %Y'
		end
	end

  #what does this do??
	def make_columns(list, options = {})
		options[:columns] ||= 5
		options[:min_rows] ||= 3
		per_column = (list.length.to_f / options[:columns]).ceil
		per_column = [ per_column, options[:min_rows] ].max
		per_column -= 1 if list.length % per_column == 1 && (list.length.to_f / per_column).ceil < options[:columns]
		columns = []
		x = 0
		while x < list.length
			columns << list[x..(x+(per_column-1))]
			x += per_column
		end
		columns.empty? ? [[]] : columns
	end

	def feed_url_options(item = nil)
		options = { :controller => 'feed' }
		options[:action] = item ? item.class.to_s.downcase : "recent"
		options[:name] = item.name if item
		options[:key] = @user.key if @user
		options
	end
	
	def recent_item_link(item, options = {})
		options[:title] = item.page.title
		if item.class == Revision
			options[:rev] = item.id
			options[:action] = "compare"
		else
			options[:anchor] = "comment_#{item.id}"
		end
		page_url(options)
	end

	def feed_icon(item = nil)
		link_to(image_tag("feed", :id => "feed_icon", :width => "16", :height => "16"), feed_url_options(item))
	end
	
	def link_for(item, options = {})
		if item.class == Page
			options[:title] = item.title
			page_url(options)
		elsif item.class == Tag
			options[:tag] = item.name
			tag_url(options)
		elsif item.class == Recent
			recent_url(options)
		else
			url_for(options)
		end
	end
	
	def indent_tags(list)
		hier = [ "" ]
		list.collect do |x|
			parents = x.name.split('.')[0..-2]
			while parents[0,hier.last.split('.').length].join('.') != hier.last && hier.pop; end
			hier << x.name
			[x, hier.length-2]
		end
	end
	
	def show_search?
		params[:show_search]
	end

	def group_by_page(list, options = {})
		options[:per_page] ||= 3
		pages = { }
		list.each { |i| (pages[i.page] ||= [ i.created_at ]) << i }
		pages = pages.collect { |page, items| [page, items] }
		pages = pages.sort { |a, b| b[1][0] <=> a[1][0] }.collect do |c|
			[ c[0], c[1][1, options[:per_page]] ]
		end
		options[:limit] ? pages[0, options[:limit]] : pages
	end

	def can_edit?
		return true if @user
		#return WikiOptions[:allow_anonymous_write]
	end

  # ==============================
	# GLOBAL HELPERS
  # ==============================

	def short_date(date)
		h date.strftime("%Y/%m/%d")
	end

	def medium_date(date)
		h date.strftime("%Y/%m/%d at %H:%M %p")
	end

	def long_date(date)
		h date.strftime("%a, %d %b %Y at %H:%M %p")
	end

=begin
  # DEPRECATED - nav bar concept has changed!
  def display_nav_options(opt='all')
    u = request.request_uri
    all = (opt == 'all' ? true : false)
    only = (opt != 'all' ? true : false)
    controller = ActionController::Routing::Routes.recognize(request).to_s
    ## Books controller removed 2009-02-15
    nav_links =  {
      :scraptionary => { :text => 'Scraptionary'[:title_scraptionary], :link => "<li class='command tab active' id='scraptionary'>" + link_to('Scraptionary'[:title_scraptionary], scraptionary_url()) + "</li>" },
      :forums => { :text => 'Talk'[:title_forums], :link => "<li class='command tab' id='forums'>" + link_to('Talk'[:title_forums], forums_url()) + "</li>" },
      :questions => { :text => 'Questions'[:title_questions], :link => "<li class='command tab' id='questions'>" + link_to('Questions'[:title_questions], questions_url()) + "</li>" },
      :tags => { :text => 'Tags'[:title_tags], :link => "<li class='command tab' id='tags'>" + link_to('Tags'[:title_tags], tags_url()) + "</li>" },
      :users => { :text => 'Users'[:title_users], :link => "<li class='command tab' id='users'>" + link_to('Users'[:title_users], all_users_url()) + "</li>" },
      :login => { :text => 'Login'[:title_login], :link => "<li class='command' class='logout_required_element' id='login'>" + link_to('Login'[:title_login], login_url()) + "</li>" },
      :logout => { :text => 'Logout'[:title_logout], :link => "<li class='command' class='login_required_element' id='logout'>" + link_to('Logout'[:title_logout], logout_url()) + "</li>" }
    }
    a = ""
    a << nav_links[:scraptionary][:link]
    a << nav_links[:forums][:link]
    a << nav_links[:questions][:link] 
    a << nav_links[:tags][:link]
    a << nav_links[:users][:link]
    a << nav_links[:login][:link]
    a << nav_links[:logout][:link]
    o = ""
    o << nav_links[:scraptionary][:text] if controller == "SearchController" or controller == "ScrapsController"
    o << nav_links[:forums][:text] if controller == "ForumsController" or controller == "TopicsController"
    o << nav_links[:questions][:text] if u.match(/\questions*/)
    o << nav_links[:tags][:text] if controller == "TagsController"
    o << nav_links[:login][:text] if controller == "SessionsController"
    o << nav_links[:users][:text] if controller == "UsersController"
    return a if all
    return o if only
  end
=end

  def display_solved_icon
    "<img src='/images/smallicons/star-med.png' alt='[#{'Solved'[:text_solved]}]' style='margin:-3px 0 -3px 0' title='#{'Solved'[:text_solved]}' border=0/>"
  end
  
  def display_topic_icon(topic, css="", title="")
    if topic.suspended?
      icon = "lock"
      post = ", this topic is suspended."[:text_comma_topic_locked]
      color = "darkgrey"
    elsif topic.sticky?
      icon = "binary"
      post = ", this is sticky."[:text_comma_sticky_topic]
      color = "darkgrey"
    else
      icon = "comment"
      color = "orange"
    end
    image_tag("clearbits/#{icon}.gif", :class => "#{css.to_s}  #{color.to_s}", :title => title.to_s + post.to_s)
  end
  
  def ajax_request?
    request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' || !(params[:format] and params[:format] =="js").nil?
  end

  def pluralize(noun, count, text = "", wordy = false)
    count_str = number_with_delimiter(count)
    noun = noun.to_s
    text = text.to_s
    if wordy
      case count
        when 0 : "There are no {noun} {text}"[:msg_none_found_count_0, noun.pluralize, text]
        when 1 : "There is one {noun} {text}"[:msg_none_found_count_1, noun.singularize, text]
        else "There are {count} {noun} {text}"[:msg_none_found_count_plus1, count_str, noun.pluralize, text]
      end
    else
      case count
        when 0 : count_str + " " + noun.pluralize
        when 1 : count_str + " " + noun.singularize
        else count_str + " " + noun.pluralize
      end
    end
  end

  # -------------------------------------------------------
  # These should be elsewhere, temoprarily placed here!!
  # cf: forum_helper.rb
  # -------------------------------------------------------
  # return whether topic has changed since we read it last
  def recent_topic_activity(topic)
    return false if not logged_in?
    return topic.last_activity_at > (session[:topics][topic.id] || last_active)
  end 
  # return whether a forum has changed since we read it last
  def recent_forum_activity(forum)
    return false unless logged_in? && forum.topics.first
    return forum.recent_topics.first.last_activity_at > (session[:forums][forum.id] || last_active)
  end
  # -------------------------------------------------------


end