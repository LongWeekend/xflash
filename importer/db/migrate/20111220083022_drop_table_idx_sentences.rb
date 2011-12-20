class DropTableIdxSentences < ActiveRecord::Migration
  def self.up
    drop_table :idx_sentences_by_keyword_staging  
  end

  def self.down
    create_table :idx_sentences_by_keyword_staging do |t|
      t.integer :sentence_id
      t.integer :segment_number
      t.integer :sense_number
      t.integer :checked
      t.integer :keyword_type
      t.string  :keyword
      t.string  :reading
    end
  end
end
