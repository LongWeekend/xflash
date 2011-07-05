# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
#ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '1.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :action_web_service ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W(
      #{RAILS_ROOT}/app/models
      #{RAILS_ROOT}/app/models/collections
      #{RAILS_ROOT}/app/models/scraps
      #{RAILS_ROOT}/app/models/posts
      #{RAILS_ROOT}/app/models/edict
      #{RAILS_ROOT}/app/models/mixin
      #{RAILS_ROOT}/app/models/sql_views
      #{RAILS_ROOT}/app/sweepers
    )
  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
#  config.action_controller.session_store = :mem_cache_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Include your application configuration below
PASSWORD_SALT = '48e45be7d489cbb0ab582d26e2168621' unless Object.const_defined?(:PASSWORD_SALT)

Module.class_eval do
  def expiring_attr_reader(method_name, value)
    class_eval(<<-EOS, __FILE__, __LINE__)
      def #{method_name}
        class << self; attr_reader :#{method_name}; end
        @#{method_name} = eval(%(#{value}))
      end
    EOS
  end
end

# Include your application configuration below

# Turns on japanese support
$KCODE = 'u'
require 'jcode'

# Set this up before going into production
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "mail.yourrailsapp.com",
  :port => 25,
  :domain => "mail.yourrailsapp.com",
  :user_name => "paulchapman@gmail.com",
  :password => "yourrailsapp",
  :authentication => :login
}
WhiteListHelper.tags.merge(%w(object param embed))

# Adds migration support for views
gem 'rails_sql_views'
require 'rails_sql_views'

# Key models presented to users as key searchable areas, array used to preserve order
$NpediaKeyModels = []
$NpediaKeyModels << { :caption => "Scraptionary", :model => :Scrap, :route => "", :all_tag_groups => "pos,context,lang,general-editorial,scraptionary-editorial", :public_tag_groups => "pos,context,lang,editorial" }
$NpediaKeyModels << { :caption => "Questions", :model => :Question, :route => "questions", :all_tag_groups => "context,general-editorial", :public_tag_groups =>  "context" }
$NpediaKeyModels << { :caption => "Tags", :model => :Tag, :route => "tags", :all_tag_groups => "general-editorial,tag-editorial", :public_tag_groups => "" }
$NpediaKeyModels << { :caption => "Users", :model => :User, :route => "users", :all_tag_groups => "award,user-editorial", :public_tag_groups => "award" }
