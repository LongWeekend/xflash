ActionController::Routing::Routes.draw do |map|

  # ===== Session & User Routes =====
  map.login 'login', :controller => 'sessions', :action => 'create'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy'
  map.register 'register', :controller => 'users', :action => 'new'
  map.open_id_complete 'sessions', :controller => 'sessions', :action => 'create', :conditions => { :method => :get }

  # ===== Search Centric Routes =====
  map.scraptionary 'search/scraps', :controller => 'search', :action => 'search', :model => 'Scrap'
  map.user_search 'search/users', :controller => 'search', :action => 'search', :model => 'User'
  map.question_search 'search/questions', :controller => 'search', :action => 'search', :model => 'Question'
  map.tag_search 'search/tags', :controller => 'search', :action => 'search', :model => 'Tag'
  
  # ===== Documentation Routes (static content) =====
  map.help 'documentation/help', :controller => 'documentation', :action => 'index'
  map.about 'documentation/about', :controller => 'documentation', :action => 'about'

  # ===== Tags =====
  map.tags_show 'tags/:t', :controller => 'search', :action => 'search', :model => "scrap"
  map.tags 'tags/index', :controller => 'tags', :action => 'index'

  # ===== autocompete =====
  map.tags_auto_complete 'autocomplete/tags', :controller => 'autocomplete', :action => 'tags', :format => 'json'
  map.links_auto_complete 'autocomplete/links', :controller => 'autocomplete', :action => 'links'

  # ===== lists =====
  map.lists 'list/toggle', :controller => 'lists', :action => 'toggle'
  map.lists 'list/load', :controller => 'lists', :action => 'load'
  map.lists 'list/contains', :controller => 'lists', :action => 'list_contains'
  map.lists 'list/remove_item', :controller => 'lists', :action => 'remove_item'
  map.lists 'list/empty', :controller => 'lists', :action => 'empty_list'

  #======= users ======
  map.settings 'settings', :controller => 'users', :action => 'edit'
  map.newuser 'signup', :controller => 'users', :action => 'create', :conditions => { :method => :post }
  map.signup 'signup', :controller => 'users', :action => 'new', :conditions => { :method => :get }
  map.activate 'activate/:key', :controller => 'users', :action => 'activate'
  map.create_user 'signup', :controller => 'users', :action => 'create', :conditions => { :method => :post }
  map.ajax_logged_in 'users/ajax_logged_in', :controller => 'users', :action => 'ajax_logged_in'

  # ===== scrap_topics ======
  map.new_scrap_topic 'scraps/new', :controller => "scraps", :action => 'new_scrap_topic', :conditions => { :method => :get }
  map.create_scrap_topic_wout_id 'scraps/new', :controller => "scraps", :action => 'create_scrap_topic', :conditions => { :method => :post }
  map.create_scrap_topic 'scraps/:id', :controller => "scraps", :action => 'create_scrap_topic', :conditions => { :method => :post }
  map.scrap_topic 'scraps/*scrap_topic_id', :controller => 'scraps', :action => 'show_scrap_topic'

  # ===== scraps ======
  map.edit_scrap 'scrap/:id/edit', :controller => "scraps", :action => 'edit'
  map.update_scrap 'scrap/:id', :controller => "scraps", :action => 'update', :conditions => { :method => :put }
  map.new_scrap_wout_id 'scrap/new', :controller => "scraps", :action => 'new', :conditions => { :method => :get }
  map.create_scrap_w_id 'scrap/:scrap_topic_id', :controller => "scraps", :action => 'create', :conditions => { :method => :post }
  map.revision 'scrap/:id/revision/:revid', :controller => 'scraps', :action => 'show', :revid => /\d+/
  map.compare 'compare/:id/:revid/:revid2', :controller => 'scraps', :action => 'compare', :revid => nil, :revid2 => nil
  map.create_scrap 'scrap', :controller => "scraps", :action => 'create', :conditions => { :method => :post }
  map.show_scrap 'scrap/:id', :controller => 'scraps', :action => 'show'

##　Not Used ##  map.create_scrap_wout_id 'scrap/new', :controller => "scraps", :action => 'create', :conditions => { :method => :post }
##　Not Used ##  map.new_scrap_w_id 'scrap/:scrap_topic_id/new', :controller => "scraps", :action => 'new', :conditions => { :method => :post }
##　Not Used ##  map.delete_scrap 'scrap/:id', :controller => "scraps", :action => 'destroy', :conditions => { :method => :delete }

  # ==== Stack Overflow Style Forum Routes ====
  map.resources :question, :controller => 'forum_topics'
  map.solve_question 'question/:id/solve', :controller => 'forum_topics', :action => 'solve_question'
  map.monitor_forum_topic 'question/:id/monitor', :controller => 'forum_topics', :action => 'monitor'
=begin
  map.show_question　'question/show', :controller => 'forum_topics', :action => 'show'
  map.new_question　'question/ask', :controller => 'forum_topics', :action => 'new'
  map.create_question　'question/create', :controller => 'forum_topics', :action => 'create'
  map.edit_question　'question/edit/:id', :controller => 'forum_topics', :action => 'edit', :conditions => { :method => :get }
  map.update_question　'question/:id', :controller => 'forum_topics', :action => 'update', :conditions => { :method => :put }
=end
  map.post_vote_up 'posts/:id/voteup', :controller => 'posts', :action => 'vote_up'
  map.post_vote_down 'posts/:id/votedown', :controller => 'posts', :action => 'vote_down'
  map.post_abuse 'posts/:id/abuse', :controller => 'posts', :action => 'abuse'

  # ===== Traditional Style Forum Routes =====
  map.resources :forums, :controller => 'forums'
  map.resources :forum_topics, :controller => 'forum_topics', :as => 'topics', :path_prefix => '/forum/:forum_id', :has_many => :topics, :has_many => :posts

### Not Used
#  map.forum_topic_talkabout 'forum/:forum_id/topics/:topic_id/talkabout', :controller => 'posts', :action => 'talkabout_topic', :forum_id => /\d+/, :topic_id => /\d+/
#  map.forum_moderator 'users/:user_id/forum/:forum_id', :controller => 'users', :action => 'forum_moderator'
#  map.solve_question 'forums/:forum_id/topics/:forum_topic_id/solve', :controller => 'forum_topics', :action => 'solve_question'
#  map.monitor_forum_topic 'forums/:forum_id/topics/:forum_topic_id/monitor', :controller => 'forum_topics', :action => 'monitor'
#
#  map.with_options :controller => 'posts', :action => 'monitored' do |m|
#    m.formatted_monitored_posts 'users/:user_id/monitored.:format'
#    m.monitored_posts           'users/:user_id/monitored'
#  end
#
#  # forum/topic/monitorship routes
#  map.resources :forums do |forum|
#    forum.resources :forum_topics, :as => 'topic', :name_prefix => nil do |topic|
#      topic.resources :posts, :name_prefix => nil
#      topic.resource :monitorship, :controller => :monitorships, :name_prefix => nil
#    end
#  end
### Not Used
  
  # ====== Generated Routes =======
  map.resources :sessions, :controller => 'sessions', :member => { :spoof_user => :post }
  map.resources :users, :member => { :make_admin => :post }

  # ===== controller/action route =====
  map.connect ':controller/:action/:id'

  # ===== scrap search aliases =====
  map.e_pseudo_search 'e/:q', :controller => 'search', :action => 'search', :model => 'Scrap'
  map.j_pseudo_search 'j/:q', :controller => 'search', :action => 'search', :model => 'Scrap'
  map.pseudo_search ':q', :controller => 'search', :action => 'search', :model => 'Scrap'
  map.home '', :controller => 'search', :action => 'search', :model => 'Scrap'

  # ===== error route =====
  map.exceptions 'logged_exceptions/:action/:id', :controller => 'logged_exceptions', :action => 'index', :id => nil

end