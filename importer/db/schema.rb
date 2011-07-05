# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "batch_jobs", :force => true do |t|
    t.string    "comments",     :limit => 200
    t.timestamp "created_at"
    t.datetime  "completed_at"
  end

  create_table "collections", :force => true do |t|
    t.integer  "parent_id",                       :default => 0, :null => false
    t.integer  "user_id"
    t.integer  "language_id",                     :default => 0
    t.string   "type",             :limit => 25,                 :null => false
    t.string   "subtype",          :limit => 25
    t.string   "title"
    t.string   "subtitle"
    t.string   "description",      :limit => 500
    t.string   "slug_cache",       :limit => 100
    t.string   "tag_cache"
    t.integer  "hits",                            :default => 0
    t.integer  "solution_post_id",                :default => 0, :null => false
    t.integer  "last_child_id",                   :default => 0, :null => false
    t.integer  "sticky_flag",      :limit => 1,   :default => 0
    t.integer  "answerable_flag",  :limit => 1,   :default => 0, :null => false
    t.integer  "child_count",                     :default => 0, :null => false
    t.datetime "solved_at"
    t.datetime "last_activity_at"
    t.integer  "last_activity_by",                :default => 0, :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "deleted_at"
    t.datetime "suspended_at"
    t.datetime "updated_at",                                     :null => false
    t.integer  "import_status",    :limit => 1,   :default => 0, :null => false
    t.integer  "import_batch_id",                 :default => 0, :null => false
  end

  add_index "collections", ["created_at"], :name => "created_at"
  add_index "collections", ["slug_cache"], :name => "slug_cache"
  add_index "collections", ["sticky_flag"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "collections", ["title"], :name => "title"
  add_index "collections", ["type"], :name => "type"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.string "name", :limit => 50, :null => false
    t.string "code", :limit => 3,  :null => false
  end

  create_table "links", :force => true do |t|
    t.integer "user_id",                                      :null => false
    t.integer "source_id",                                    :null => false
    t.integer "related_id",                                   :null => false
    t.string  "source_type",     :limit => 25,                :null => false
    t.string  "related_type",    :limit => 25,                :null => false
    t.string  "relationship",    :limit => 50
    t.integer "position",                      :default => 0, :null => false
    t.integer "private",         :limit => 1,  :default => 0, :null => false
    t.integer "import_status",                 :default => 0, :null => false
    t.integer "import_batch_id",               :default => 0, :null => false
  end

  add_index "links", ["related_id"], :name => "related_id"
  add_index "links", ["related_type"], :name => "related_type"
  add_index "links", ["source_id"], :name => "source_id"
  add_index "links", ["source_type"], :name => "source_type"

  create_table "list_Items", :force => true do |t|
    t.integer  "list_id",                                    :null => false
    t.integer  "listable_id"
    t.string   "listable_type", :limit => 25
    t.integer  "position",                    :default => 0
    t.datetime "created_at",                                 :null => false
  end

  add_index "list_Items", ["created_at"], :name => "created_at"

  create_table "lists", :force => true do |t|
    t.integer  "user_id",                                     :null => false
    t.string   "name",       :limit => 80,                    :null => false
    t.boolean  "private",                  :default => false, :null => false
    t.datetime "created_at",                                  :null => false
  end

  add_index "lists", ["created_at"], :name => "created_at"

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.string   "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at",      :null => false
  end

  create_table "moderatorships", :force => true do |t|
    t.integer "collection_id"
    t.string  "type",          :limit => 25, :null => false
    t.integer "user_id"
  end

  add_index "moderatorships", ["collection_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer "collection_id"
    t.integer "user_id"
    t.boolean "active",        :default => true
  end

  create_table "posts", :force => true do |t|
    t.integer   "collection_id"
    t.integer   "scrap_id",                      :default => 0,     :null => false
    t.integer   "parent_id",                     :default => 0,     :null => false
    t.integer   "user_id"
    t.string    "type",            :limit => 25,                    :null => false
    t.string    "title"
    t.text      "body"
    t.text      "body_html"
    t.string    "path"
    t.integer   "depth",                         :default => 0,     :null => false
    t.integer   "child_count",                   :default => 0,     :null => false
    t.integer   "vote_up_count",                 :default => 0,     :null => false
    t.integer   "vote_down_count",               :default => 0,     :null => false
    t.boolean   "first_post_flag",               :default => false, :null => false
    t.boolean   "spam_flag",                     :default => false, :null => false
    t.integer   "spam_score",                    :default => 0,     :null => false
    t.datetime  "created_at",                                       :null => false
    t.datetime  "deleted_at"
    t.timestamp "updated_at",                                       :null => false
  end

  add_index "posts", ["created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

  create_table "revisions", :force => true do |t|
    t.string   "title",                          :null => false
    t.integer  "scrap_id",                       :null => false
    t.integer  "user_id",                        :null => false
    t.text     "content"
    t.string   "summary"
    t.string   "tag_cache"
    t.integer  "change_size",     :default => 4, :null => false
    t.datetime "created_at",                     :null => false
    t.integer  "import_status",   :default => 0, :null => false
    t.integer  "import_batch_id", :default => 0, :null => false
  end

  create_table "scrap_pages", :force => true do |t|
    t.integer   "cacheable_id",                                       :null => false
    t.string    "cacheable_type",  :limit => 50,                      :null => false
    t.integer   "import_batch_id",                     :default => 0, :null => false
    t.integer   "language_id",                                        :null => false
    t.string    "title"
    t.string    "slug_cache"
    t.text      "content",         :limit => 16777215
    t.timestamp "created_at"
  end

  create_table "scraps", :force => true do |t|
    t.integer   "collection_id",                 :default => 0,     :null => false
    t.integer   "parent_id",                     :default => 0
    t.integer   "user_id",                                          :null => false
    t.integer   "language_id"
    t.string    "type",            :limit => 25,                    :null => false
    t.string    "title",                                            :null => false
    t.string    "tag_cache"
    t.string    "slug_cache",                                       :null => false
    t.text      "content",                                          :null => false
    t.string    "path"
    t.integer   "depth",                         :default => 0
    t.integer   "sibling_order",                 :default => 0
    t.integer   "version",                       :default => 1,     :null => false
    t.boolean   "spam",                          :default => false
    t.integer   "spam_score",                    :default => 0
    t.integer   "draft_flag",      :limit => 1,  :default => 0,     :null => false
    t.datetime  "created_at",                                       :null => false
    t.datetime  "deleted_at"
    t.timestamp "updated_at",                                       :null => false
    t.integer   "import_status",                 :default => 0,     :null => false
    t.integer   "import_batch_id",               :default => 0,     :null => false
  end

  add_index "scraps", ["collection_id"], :name => "collection_id"
  add_index "scraps", ["slug_cache"], :name => "slug_cache"
  add_index "scraps", ["title"], :name => "title"
  add_index "scraps", ["type", "title"], :name => "type_title"

  create_table "sessions", :force => true do |t|
    t.string    "session_id"
    t.text      "data",       :limit => 16777215
    t.integer   "user_id"
    t.timestamp "updated_at",                     :null => false
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "sphinx_counter", :primary_key => "counter_id", :force => true do |t|
    t.integer  "max_doc_id", :null => false
    t.datetime "updated_at"
  end

  create_table "tag_cache", :force => true do |t|
    t.integer  "tag_id",                       :null => false
    t.string   "context"
    t.string   "taggable_type"
    t.integer  "count",         :default => 0
    t.datetime "updated_at"
  end

  add_index "tag_cache", ["tag_id", "context", "taggable_type"], :name => "tag_cache_index"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
    t.integer  "import_status",   :default => 0, :null => false
    t.integer  "import_batch_id", :default => 0, :null => false
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "source_name", :limit => 50
    t.string   "source",      :limit => 50
    t.datetime "created_at"
  end

  add_index "tags", ["name"], :name => "name"

  create_table "users", :force => true do |t|
    t.string    "login"
    t.string    "email"
    t.string    "display_name"
    t.string    "identity_url"
    t.string    "password_hash"
    t.string    "key",                                     :null => false
    t.string    "login_key"
    t.datetime  "login_key_expires_at"
    t.boolean   "activated",            :default => false
    t.text      "bio"
    t.text      "bio_html"
    t.string    "website"
    t.boolean   "admin"
    t.integer   "forum_posts_count",    :default => 0,     :null => false
    t.datetime  "last_seen_at"
    t.datetime  "last_login_at"
    t.datetime  "created_at",                              :null => false
    t.timestamp "updated_at",                              :null => false
  end

  add_index "users", ["last_seen_at"], :name => "index_users_on_last_seen_at"

  create_table "votes", :force => true do |t|
    t.integer  "user_id",                                  :null => false
    t.integer  "source_id",                 :default => 0, :null => false
    t.string   "source_type", :limit => 25
    t.string   "vote_type",   :limit => 25
    t.integer  "weight",                    :default => 0, :null => false
    t.datetime "created_at",                               :null => false
  end

# Could not dump view "new_view" because of following NoMethodError
#   You have a nil object when you didn't expect it!
The error occurred while evaluating nil.dump

# Could not dump view "v_collections_by_scrap_topic_or_definition_title" because of following NoMethodError
#   You have a nil object when you didn't expect it!
The error occurred while evaluating nil.dump

# Could not dump view "v_tags_by_collection" because of following NoMethodError
#   You have a nil object when you didn't expect it!
The error occurred while evaluating nil.dump

# Could not dump view "v_tags_by_scrap_page" because of following NoMethodError
#   You have a nil object when you didn't expect it!
The error occurred while evaluating nil.dump

end
