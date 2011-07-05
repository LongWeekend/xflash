############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#   --- Export TanakaCorpus to Npedia ---
############################################

#
# (true) import_tanc_data : data = Hash of tanc data
#
def import_tanc_data(data)

  if @options[:db_active]
    delete_incomplete("scraps")
    delete_incomplete("links")
    delete_incomplete("taggings")
  end

  loop_count = 0
  sql_line_count = 0
  buffered_lines = ""
  import_log_id = "Tanaka Corpus Import"
  corpus_type_id = "Japanese-English Parallel Texts"
  ptxt_references = {}

  # Find or create the English-Japanese Corpus
  corpus_id = Corpus.find_or_create_by_title_and_language_id_and_user_id(corpus_type_id, @options[:english_lang_id], @options[:import_user_id]).id
  current_batch = BatchJob.find(:first, :conditions=>"completed_at IS NULL AND comments = '#{import_log_id}'", :order =>"id DESC")
  current_batch ||= BatchJob.create(:comments => import_log_id)

  # Get all Scrap Topics, dump into hash!
  scrap_topics_hash = {}
  tickcount("BUFFERING all ScrapTopics") do
    scrap_topics = @cn.execute("SELECT id, title, subtitle FROM collections WHERE import_status=#{@options[:statuses]["completed"]} AND type='ScrapTopic'")
    scrap_topics.each do |id,title,subtitle|
      scrap_topics_hash[title] = id
      subtitle.split(';').each do |other_t|
        scrap_topics_hash[other_t] = id
      end    
    end
  end

  # Buffer existing ta data
  existing_tags = {}
  @cn.execute("SELECT id, name, source_name FROM tags WHERE source = 'edict' ORDER BY name ").each do | id, name, source_name |
    existing_tags[source_name] = { :id => id, :npedia_name => name }
  end

  tickcount("IMPORT of ParallelTexts into Npedia") do
    disable_keys("scraps") if @options[:exclusive_access]
    data.each do |pt|
      loop_count+=1
      hash = ""
      ## This requires a FULL import of Edict2 before it can match up to the existing references nicely!
      if pt[:references].size > 0
        pt[:references].each do |ref|
          ref.each do |headword, position|
            headword.gsub(@regexes[:tag_like], "")
            target_scrap = scrap_topics_hash[headword]
            if !target_scrap.nil?
              hash = ap_hash("#{pt[:japanese]}___#{pt[:translated]}___#{pt[:tags]}")
              ptxt_references["#{hash}"] = [] unless !ptxt_references[hash].nil?
              ptxt_references["#{hash}"] << target_scrap
              ## NOISY DEBUG puts "Found linkage to #{headword}[#{position}]" unless @options[:silent]
            elsif !@options[:silent]
              puts "Missing linkage to #{headword} [#{position}]"
            end
          end
        end
      end
      
      # New tag handling code that actually save tags!
      if pt[:tag].length > 0
        tags = pt[:tag].split(' ').collect{|a| (existing_tags.has_key?(a) ? existing_tags[a][:npedia_name] : a)}.join(',')
      else
        tags = ""
      end

      content = format_parallel_text(pt[:japanese], pt[:translated], pt[:line_b]).gsub("'" , '\\\\\'').gsub('\"' , '\\\\\\\\\\"')
      buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{corpus_id}, #{@options[:english_lang_id]}, 'ParallelText', '#{hash}', '#{content}', '#{tags}', NOW(), NOW(), #{@options[:statuses]["inserted"]}, #{current_batch.id})"
      sql_line_count+=1
      # Flush buffer every "@options[:import_page_size]" records
      if sql_line_count == @options[:import_page_size] or loop_count == data.length
        @cn.insert("INSERT INTO scraps (user_id, collection_id, language_id, type, title, content, tag_cache, created_at, updated_at, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
        puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} ParallelTexts at #{Time.now})" unless @options[:silent]
        buffered_lines = ""
        sql_line_count = 0
      end
    end
    enable_keys("scraps") if @options[:exclusive_access]
  end
  
  tickcount("INSERTION of tags") do
    # TO DO!!!
  end
  
  loop_count = 0
  sql_line_count = 0
  sql_line_total_count = 0
  buffered_lines = ""

  parallel_texts = @cn.execute("SELECT id, title FROM scraps WHERE type ='ParallelText' AND import_status=#{@options[:statuses]["inserted"]} AND import_batch_id = #{current_batch.id} AND title is not null")
  parallel_texts_hash = {}
  parallel_texts.each {|id, key| parallel_texts_hash[key] = id }

  tickcount("INSERTION of links") do
    disable_keys("links") if @options[:exclusive_access]
    parallel_texts_hash.each do |key, id|
      if key != ""
        loop_count+=1
        if ptxt_references.has_key?(key)
          ptxt_references["#{key}"].each do |ref|
            buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{@options[:import_user_id]}, #{id}, #{ref}, 'ParallelText', 'Scrap', 'related', #{@options[:statuses]["inserted"]}, #{current_batch.id})"
            sql_line_count+=1
            sql_line_total_count+=1
          end
        end
      end
      # Flush buffer every "@options[:import_page_size]" records
      if sql_line_count >= @options[:import_page_size] or sql_line_total_count == ptxt_references.length
        @cn.insert("INSERT INTO links (user_id, source_id, related_id, source_type, related_type, relationship, import_status, import_batch_id) VALUES #{buffered_lines}") if @options[:db_active]
        puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} Links at #{Time.now})" unless @options[:silent]
        buffered_lines = ""
        sql_line_count = 0
      end
      # Break if all links have been inserted
      break if sql_line_total_count == ptxt_references.length
    end
    enable_keys("links") if @options[:exclusive_access]
  end

  return if not @options[:db_active]

  tickcount("QUERY: SELECT Scraps and INSERT as Revisions") do
    @cn.execute("ALTER TABLE revisions ENABLE KEYS") if @options[:exclusive_access]
    @cn.execute("INSERT INTO revisions(title, scrap_id, user_id, content, tag_cache, change_size, created_at) " +
                "SELECT title, id, user_id, content, tag_cache, 100, created_at " +
                "FROM scraps WHERE import_status=#{@options[:statuses]["inserted"]} and import_batch_id = #{current_batch.id}")
    @cn.execute("ALTER TABLE revisions DISABLE KEYS") if @options[:exclusive_access]
  end

  tickcount("QUERY: UPDATE import statuses") do
    commit_imported_recs("collections", current_batch.id)
    commit_imported_recs("scraps", current_batch.id)
    commit_imported_recs("taggings", current_batch.id)
    commit_imported_recs("links", current_batch.id)
    current_batch.update_attribute("completed_at", Time.now)
  end
  return true
end