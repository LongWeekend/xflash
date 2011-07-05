class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    # Tag storage
    create_table :tags do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :created_at, :datetime
    end

    # Associations storage for tagged objects
    create_table :taggings do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      t.column :tagger_id, :integer
      t.column :tagger_type, :string
      t.column :taggable_type, :string
      t.column :context, :string
      t.column :created_at, :datetime
    end

    # Cache for tag counts, scoped by [tag_id] / [context] / [taggable_type]
    create_table :tag_cache do |t|
      t.column :tag_id, :integer
      t.column :context, :string
      t.column :tagger_type, :string
      t.column :count, :integer
      t.column :updated_at, :datetime
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :context, :taggable_type]
    add_index :tag_cache, [:tag_id, :context, :taggable_type]
  end
  
  def self.down
    drop_table :taggings
    drop_table :tags
    drop_table :tag_cache
  end
end
