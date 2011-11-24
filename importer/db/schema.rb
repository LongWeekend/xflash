# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111124091809) do

  create_table "card_sentence_link", :id => false, :force => true do |t|
    t.integer "card_id"
    t.integer "sentence_id"
    t.integer "should_show",  :limit => 1, :default => 1
    t.integer "sense_number"
  end

  add_index "card_sentence_link", ["card_id"], :name => "card_id"
  add_index "card_sentence_link", ["sentence_id"], :name => "sentence_id"

  create_table "card_tag_link", :id => false, :force => true do |t|
    t.integer "tag_id"
    t.integer "card_id"
  end

  create_table "cards", :id => false, :force => true do |t|
    t.integer "card_id",       :default => 0, :null => false
    t.string  "headword_trad",                :null => false
    t.string  "headword_simp",                :null => false
    t.string  "reading",                      :null => false
  end

  create_table "cards_html", :id => false, :force => true do |t|
    t.integer "card_id",                 :default => 0, :null => false
    t.string  "meaning", :limit => 5000,                :null => false
  end

  create_table "cards_search_content", :id => false, :force => true do |t|
    t.integer "card_id",                 :default => 0, :null => false
    t.string  "content", :limit => 5000
  end

  create_table "cards_staging", :primary_key => "card_id", :force => true do |t|
    t.string  "headword_trad",                                              :null => false
    t.string  "headword_simp",                                              :null => false
    t.string  "headword_en",                                                :null => false
    t.string  "reading",                                                    :null => false
    t.string  "reading_diacritic",                       :default => "",    :null => false
    t.string  "meaning",           :limit => 3000,                          :null => false
    t.string  "meaning_fts",       :limit => 3000,                          :null => false
    t.string  "meaning_html",      :limit => 5000,                          :null => false
    t.string  "classifier"
    t.string  "tags",              :limit => 200
    t.boolean "is_variant",                              :default => false, :null => false
    t.boolean "is_erhua_variant",                        :default => false, :null => false
    t.string  "variant"
    t.integer "variant_card_id"
    t.binary  "cedict_hash",       :limit => 2147483647,                    :null => false
    t.boolean "is_proper_noun",                          :default => false, :null => false
    t.boolean "is_reference_only",                       :default => false, :null => false
    t.string  "referenced_cards"
  end

  add_index "cards_staging", ["headword_simp"], :name => "headword_simp"
  add_index "cards_staging", ["headword_trad"], :name => "headword_trad"
  add_index "cards_staging", ["reading"], :name => "reading"

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

  create_table "group_tag_link", :id => false, :force => true do |t|
    t.integer "group_id", :null => false
    t.integer "tag_id",   :null => false
  end

  create_table "groups", :id => false, :force => true do |t|
    t.integer "group_id",                                 :null => false
    t.string  "group_name",  :limit => 50,                :null => false
    t.integer "owner_id",                                 :null => false
    t.integer "tag_count",                 :default => 0
    t.integer "recommended",               :default => 0
  end

  create_table "groups_staging", :primary_key => "group_id", :force => true do |t|
    t.string  "group_name",  :limit => 50,                :null => false
    t.integer "owner_id",                                 :null => false
    t.integer "tag_count",                 :default => 0
    t.integer "recommended",               :default => 0
  end

  create_table "idx_sentences_by_keyword_staging", :id => false, :force => true do |t|
    t.integer "sentence_id"
    t.integer "segment_number"
    t.integer "sense_number"
    t.integer "checked",        :limit => 1
    t.integer "keyword_type"
    t.string  "keyword",        :limit => 100
    t.string  "reading",        :limit => 100
  end

  add_index "idx_sentences_by_keyword_staging", ["sentence_id"], :name => "sentence_id"

  create_table "parse_exceptions", :force => true do |t|
    t.string   "input_string"
    t.string   "exception_type"
    t.string   "resolution_string"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "parse_exceptions", ["input_string", "exception_type"], :name => "input_string_and_type_unique", :unique => true

  create_table "sentences_staging", :id => false, :force => true do |t|
    t.integer "sentence_id",                :null => false
    t.string  "sentence_ch", :limit => 500
    t.string  "sentence_en", :limit => 500
    t.integer "en_id"
    t.integer "ch_id"
    t.integer "checked",     :limit => 1
  end

  add_index "sentences_staging", ["checked"], :name => "checked"
  add_index "sentences_staging", ["sentence_id"], :name => "sentence_id"

  create_table "tag_matching_exceptions", :force => true do |t|
    t.string   "entry_id"
    t.string   "human_readable"
    t.text     "serialized_entry"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_matching_exceptions", ["entry_id"], :name => "index_tag_matching_exceptions_on_entry_id", :unique => true

  create_table "tag_matching_resolution_choices", :force => true do |t|
    t.string   "tag_matching_exception_id"
    t.string   "human_readable"
    t.text     "serialized_entry"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_matching_resolution_choices", ["tag_matching_exception_id"], :name => "index_tag_matching_resolution_choices_on_base_entry_id"

  create_table "tag_matching_resolutions", :force => true do |t|
    t.string   "entry_id"
    t.text     "serialized_entry"
    t.string   "resolution_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :id => false, :force => true do |t|
    t.integer "tag_id",                     :default => 0, :null => false
    t.string  "tag_name",    :limit => 50
    t.string  "description", :limit => 200
    t.integer "editable",                   :default => 0, :null => false
    t.integer "count",                      :default => 0, :null => false
  end

  create_table "tags_staging", :primary_key => "tag_id", :force => true do |t|
    t.string  "tag_name",      :limit => 50
    t.string  "tag_type",      :limit => 4
    t.string  "short_name",    :limit => 20
    t.string  "description",   :limit => 200
    t.string  "source_name",   :limit => 50
    t.string  "source",        :limit => 50
    t.integer "visible",                      :default => 0, :null => false
    t.integer "editable",                     :default => 0, :null => false
    t.integer "count",                        :default => 0, :null => false
    t.integer "parent_tag_id"
    t.integer "force_off",     :limit => 1,   :default => 0
  end

  add_index "tags_staging", ["short_name"], :name => "short_name", :unique => true

end
