############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#        --- Export to Npedia ---
############################################

#
# (int) npedia_import_data : data = Hash of edict2 data
#
def npedia_import_data(data)

  if @options[:db_active]
    delete_incomplete("scraps")
    delete_incomplete("links")
    delete_incomplete("collections")
    delete_incomplete("taggings")
  end

  import_log_id = "Edict2 Import"
  current_batch = BatchJob.find(:first, :conditions=>"completed_at IS NULL AND comments = '#{import_log_id}'", :order =>"id DESC")
  current_batch ||= BatchJob.create(:comments => import_log_id)

  add_scrap_topics(data, current_batch)
  add_scrap_topic_scraps(data, current_batch)
  add_scrap_links(data, current_batch, true)
  add_scrap_tags(current_batch)

  add_revisions(current_batch.id)
  update_collection_counts(current_batch.id)

  if not @options[:db_active]
    current_batch.delete and return
  end
  
  tickcount("QUERY: UPDATE import statuses") do
    commit_imported_recs("collections", current_batch.id)
    commit_imported_recs("scraps", current_batch.id)
    commit_imported_recs("taggings", current_batch.id)
    commit_imported_recs("links", current_batch.id)
    current_batch.update_attribute("completed_at", Time.now)
  end

end

#
# (int) add_scrap_topics : data = Hash of edict2 data, current_batch = BatchJob object for the current run
#
def add_scrap_topics(data, current_batch)

  loop_count = 0
  sql_line_count = 0
  buffered_lines = ""

  tickcount("IMPORT of ScrapTopics into Npedia") do
    disable_keys("collections") if @options[:exclusive_access]
    data.each do |headword,v|
      loop_count=loop_count+1
      buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{@options[:japanese_lang_id]}, 'ScrapTopic', '#{headword}', '#{v[:other_headwords]}', '#{headword.to_s.gsub(/[[:space:]|[:punct:]]/, '')}', 1, NOW(), NOW(), #{@options[:statuses]["inserted"]}, #{current_batch.id})"
      sql_line_count=sql_line_count+1
      # Flush buffer every "@options[:import_page_size]" records
      if sql_line_count == @options[:import_page_size] or loop_count == data.length
        @cn.insert("INSERT INTO collections(user_id, language_id, type, title, subtitle, slug_cache, child_count, created_at, updated_at, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
        puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} ScrapTopics at #{Time.now})" unless @options[:silent]
        buffered_lines = ""
        sql_line_count = 0
      end
    end
    enable_keys("collections") if @options[:exclusive_access]
  end
  return loop_count
end

#
# (BOOL) add_scrap_topic_scraps : data = Hash of edict2 data, current_batch = BatchJob object for the current run
#
def add_scrap_topic_scraps(data, current_batch)

  loop_count = 0
  sql_line_count = 0
  buffered_lines = ""
  scrap_topics_hash = get_existing_scrap_topics_hash("import_status=#{@options[:statuses]["inserted"]} AND import_batch_id = #{current_batch.id}")

  existing_tags = {}
  @cn.execute("SELECT id, name, source_name FROM tags WHERE source = 'edict' ORDER BY name ").each do | id, name, source_name |
    existing_tags[source_name] = { :id => id, :npedia_name => name }
  end

  tickcount("IMPORT of Scraps into Npedia") do
    disable_keys("scraps") if @options[:exclusive_access]
    scrap_topics_hash.each do |headword, id|
      usage_count = 0
      loop_count=loop_count+1
      v = data[headword]
      v[:usages].each do |usage|
        usage_count=usage_count+1
        if usage[:description] != ""
          tags = []
          
    ## For some reason this code is not matching the new names correctly!!!
          tags << usage[:pos_tags].split(' ').collect{|a| (existing_tags.has_key?(a) ? existing_tags[a][:npedia_name] : a)}.join(',') if usage[:pos_tags].length > 0
          tags << usage[:tag_tags].split(' ').collect{|a| (existing_tags.has_key?(a) ? existing_tags[a][:npedia_name] : a)}.join(',') if usage[:tag_tags].length > 0
          tags << usage[:lang_tags].split(' ').collect{|a| (existing_tags.has_key?(a)? existing_tags[a][:npedia_name] : a)}.join(',') if usage[:lang_tags].length > 0
          tags = tags.join(', ')

          scrap_topic_id = (@options[:db_active] ? scrap_topics_hash[headword] : "XXX")
          readings = headword if readings == ""
          content = format_definition(usage[:readings], usage[:description])
          content = content.gsub("'" , '\\\\\'').gsub('\"' , '\\\\\\\\\\"') # Manually escape: i) single quotes and ii) YAML-escaped double quotes
          buffered_lines = (buffered_lines =="" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{scrap_topic_id}, #{@options[:english_lang_id]}, 'Definition', '#{usage[:readings]}', '#{content}', '#{tags}', '#{headword.to_s.gsub(/[[:space:]|[:punct:]]/, '')}', #{usage_count}, NOW(), NULL, #{@options[:statuses]["inserted"]}, #{current_batch.id})"
          sql_line_count=sql_line_count+1

          # Flush buffer every "@options[:import_page_size]" records
          ## PROOF DBEUG ## pp "Does #{loop_count}==#{scrap_topics_hash.length} AND #{v[:usages].length}==#{usage_count} ? "+ (loop_count == scrap_topics_hash.length and v[:usages].length == usage_count).to_s
          if sql_line_count == @options[:import_page_size] or (loop_count == scrap_topics_hash.length and v[:usages].length == usage_count)
            @cn.insert("INSERT INTO scraps (user_id, collection_id, language_id, type, title, content, tag_cache, slug_cache, sibling_order, created_at, updated_at, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
            puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} Scraps at #{Time.now})" unless @options[:silent]
            buffered_lines = ""
            sql_line_count = 0
          end
        end
      end
    end
    puts "Scraps inserted, total (#{loop_count})" unless @options[:silent]
    enable_keys("scraps") if @options[:exclusive_access]
  end
  return true
end

#
# (int) add_scrap_tags : current_batch = BatchJob object for the current run
#
def add_scrap_tags(current_batch)

  loop_count = 0
  sql_line_count = 0
  buffered_lines = ""

  tickcount("INSERTION of Tags") do
    existing_tags = {}
    @cn.execute("SELECT id, name, source_name FROM tags WHERE source = 'edict' ORDER BY name ").each do | id, name, source_name |
      existing_tags[source_name] = { :id => id, :npedia_name => name }
    end
    disable_keys("taggings") if @options[:exclusive_access]
    foo = @cn.execute("SELECT id, tag_cache FROM scraps WHERE import_status=#{@options[:statuses]["inserted"]} and import_batch_id = #{current_batch.id}")

    foo.each do | scrap_id, tag_cache |
      loop_count=loop_count+1
      tag_blocks_count=0
      tag_blocks = tag_cache.split('/')

      tag_blocks.each do |block|
        tag_blocks_count=tag_blocks_count+1
        # No embedding of tag types for now, ALL unique!
          #if block.scan(/pos\:/).size > 0
          #  tag_type = "pos"
          #elsif block.scan(/lang\:/).size > 0
          #  tag_type = "lang"
          #elsif block.scan(/tag\:/).size > 0
          #  tag_type = "tag"
          #else
          #  tag_type = nil
          #end

        ###if !tag_type.nil?
          ### tags_in_block = block.gsub("#{tag_type}\:","").split(',')
          tags_in_block_count=0
          tags_in_block = block.split(',')
          tags_in_block.each do |tag|
            tags_in_block_count=tags_in_block_count+1
            tag = tag.strip
            if existing_tags[tag].nil?
              # Insert tag if not in array already
              tag_id = @cn.insert("INSERT INTO tags (name, type, description, source_name, source, created_at) VALUES ('#{tag}', '', 'Unedited EDICT tag', '#{tag}', 'edict', NOW())") if @options[:db_active]
              existing_tags[tag] = tag_id
            else
              tag_id = existing_tags[tag][:id]
              tag_name = existing_tags[tag][:npedia_name]
            end
            buffered_lines = (buffered_lines =="" ? "" : buffered_lines + ",\n") + "(#{tag_id}, #{scrap_id}, #{@options[:import_user_id]}, 'User', 'Scrap', 'tag', NOW(), #{@options[:statuses]["inserted"]}, #{current_batch.id})"
            sql_line_count=sql_line_count+1

            # Flush buffer every "@options[:import_page_size]" records
            # PROOF DEBUG ### pp "#{loop_count}== #{foo.num_rows} and #{tag_blocks.length}==#{tag_blocks_count} and #{tags_in_block.length}=#{tags_in_block_count} >> " + (loop_count == foo.num_rows and tag_blocks.length==tag_blocks_count and tags_in_block.length == tags_in_block_count).to_s
            if (sql_line_count == @options[:import_page_size]) or (loop_count == foo.num_rows and tag_blocks.length==tag_blocks_count and tags_in_block.length == tags_in_block_count)
              @cn.insert("INSERT INTO taggings(tag_id, taggable_id, tagger_id, tagger_type, taggable_type, context, created_at, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
              puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} Tags at #{Time.now})" unless @options[:silent]
              buffered_lines = ""
              sql_line_count = 0
            end
          ###end
        end
      end
    end
    enable_keys("taggings") if @options[:exclusive_access]
  end
  return loop_count
end

#
# (BOOL) add_scrap_links : current_batch = BatchJob object for the current run
#
def add_scrap_links(data, current_batch, in_lock_step=true)
  loop_count = 0
  sql_line_count = 0
  sql_line_total_count = 0
  buffered_lines = ""
  scrap_topics_hash = get_existing_scrap_topics_hash()

  lock_step = (in_lock_step ? "import_status = #{@options[:statuses]["inserted"]} AND import_batch_id = #{current_batch.id} AND " : "")

  # Get all definitions
  scraps_hash = {}
  scraps = nil
  tickcount("SELECT all Scraps") do
    scraps = @cn.execute("SELECT id, title, collection_id, sibling_order FROM scraps WHERE #{lock_step} type ='Definition'")
  end
  scraps.each do |id, title, collection_id, sibling_order|
    puts "Scrap Hash Collision when linking Scraps" if scraps_hash.has_key?("#{collection_id}__#{title}") and !@options[:silent]
    scraps_hash["#{collection_id}__#{title}__#{sibling_order}"] = id
  end

  ### { :readings => readings, :description => description, :references => references, :antonyms => antonyms, :pos_tags => pos, :lang_tags => lang, :tag_tags => tag, :headword => headword }
  tickcount("INSERTION of links") do
    disable_keys("links") if @options[:exclusive_access]
    scrap_topics_hash.each do |headword, id|
      usage_count = 0
      loop_count=loop_count+1
      v = data[headword]
      if !v.nil?
        v[:usages].each do |usage|
          usage_count = usage_count+1
          next if usage[:references] =="" and usage[:antonyms] ==""
          puts "Link Inserted" unless
          puts "Missing ScrapTopic when linking Scrap" unless scrap_topics_hash.has_key?(headword) and !@options[:silent]
          scrap_topic_id = scrap_topics_hash[headword]
          scrap_ref = scraps_hash["#{scrap_topic_id}__#{usage[:readings]}__#{usage_count}"]
          if scraps_hash[:references] !=""
            usage[:references].split(',').each do |ref|
              scrap_topic_ref = scrap_topics_hash[ref]
              if !scrap_topic_ref.nil?
                buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{scrap_ref}, #{scrap_topic_ref}, 'Scrap', 'ScrapTopic', 'related', #{@options[:statuses]["inserted"]}, #{current_batch.id})"
                sql_line_count+=1
              end
            end
          end
          if scraps_hash[:antonyms] !=""
            usage[:antonyms].split(',').each do |ref|
              scrap_topic_ref = scrap_topics_hash[ref]
              if !scrap_topic_ref.nil?
                buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{scrap_ref}, #{scrap_topic_ref}, 'Scrap', 'ScrapTopic', 'antonym', #{@options[:statuses]["inserted"]}, #{current_batch.id})"
                sql_line_count+=1
              end
            end
          end
        end
      end

      # Flush buffer every "@options[:import_page_size]" records
      if sql_line_count >= @options[:import_page_size] or (scrap_topics_hash.length == loop_count) and buffered_lines != ""
        @cn.insert("INSERT INTO links (user_id, source_id, related_id, source_type, related_type, relationship, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
        puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} Links at #{Time.now})" unless @options[:silent]
        buffered_lines = ""
        sql_line_count = 0
      end

    end
    enable_keys("links") if @options[:exclusive_access]
  end

  return true
end


#
# (BOOL) add_revisions(current_batch_id)
#
def add_revisions(current_batch_id)
  return if not @options[:db_active]
  tickcount("QUERY: SELECT Scraps and INSERT as Revisions") do
    @cn.execute("ALTER TABLE revisions ENABLE KEYS") if @options[:exclusive_access]
    @cn.execute("INSERT INTO revisions(title, scrap_id, user_id, content, tag_cache, change_size, created_at) " +
                "SELECT title, id, user_id, content, tag_cache, 100, created_at " +
                "FROM scraps WHERE import_status=#{@options[:statuses]["inserted"]} and import_batch_id = #{current_batch_id}")
    @cn.execute("ALTER TABLE revisions DISABLE KEYS") if @options[:exclusive_access]
  end
  return true
end

#
# (BOOL) update_collection_counts(current_batch_id)
#
def update_collection_counts(current_batch_id)
  return if not @options[:db_active]
  tickcount("QUERY: UPDATE collections.child_count") do
    cnt = 0
    foo = @cn.execute(
      "SELECT * FROM "+ 
        "( SELECT count(collection_id) AS child_count, collection_id FROM scraps "+
           "WHERE collection_id IN (SELECT id FROM collections WHERE import_status=#{@options[:statuses]["inserted"]} and import_batch_id = #{current_batch_id}) GROUP BY collection_id " +
        ") AS mytable WHERE child_count > 1"
     )
    foo.each do | child_count, collection_id |
      cnt=cnt+1
      @cn.execute("UPDATE collections SET child_count = #{child_count} WHERE id = #{collection_id}")
      if cnt == 500
        puts "Updated 500 ScrapTopic counts @ " + (Time.now).to_s
        cnt = 0
      end
    end
  end
  return true
end