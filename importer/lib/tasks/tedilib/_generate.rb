############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#   --- ScrapPage Generator lib file ---
############################################

#### Number them manually 1-x
@total_worker_processes = 2
@worker_id = get_worker_id
@multiple_processes_enabled = (@worker_id.to_i > 0)

@options[:import_page_size] = 500
@force_scrap_update = true
@generation_batch_comment = "ScrapPages > Generating"

#
# (BOOL) generate_imported - Generates scrap pages based on the current batch job's ID
#
def generate_imported(type,current_batch)

  puts "Current BatchJob is empty!" and return false unless current_batch

  # Build source data conditions
  conditions = "collections.import_batch_id = #{current_batch.id} " if type == "ScrapTopic"
  conditions = "scraps.import_batch_id = #{current_batch.id} " if type == "ParallelText"
  add_scrap_pages(type,conditions,current_batch)

  # Clean up!
  finalise_batch(current_batch)
  return true

end


#
# (BOOL) generate_by_date - Generates based on date check, good for low selectivity (i.e. when most scrap_pages exist).
#
def generate_by_date_updated

  last_batch = BatchJob.find(:first, :conditions => "comments = '#{@generation_batch_comment}'", :order => "created_at DESC")
  last_batch_date = last_batch.created_at if !last_batch.nil?
  last_batch_date ||= '2000/01/01'

  current_batch = BatchJob.create(:comments=>@generation_batch_comment)

  scrap_topics_needing_update_array = []
  parallel_texts_needing_update_array = []
  
  ### Get IDs of ScrapTopics changed since last generation batch job
  collections=Collection.find(:all, :select => "id", :conditions => ["type='ScrapTopic' AND updated_at >= ?", last_batch_date])
  collections.each do |rec|
    scrap_topics_needing_update_array << rec.id
  end

  ### Get IDs of ParallelTexts changed since last generation batch job
  parallel_texts=ParallelText.find(:all, :select => "id", :conditions => ["updated_at >= ?", last_batch_date])
  parallel_texts.each do |rec|
    parallel_texts_needing_update_array << rec.id
  end

  # Loop arrays incrementally and call 'add_scrap_pages'
  loop_and_save_scrap_pages("ScrapTopic", scrap_topics_needing_update_array, current_batch, "update")
  loop_and_save_scrap_pages("ParallelText", parallel_texts_needing_update_array, current_batch, "update")
  
  # Clean up!
  finalise_batch(current_batch)
  return true

end


#
# (BOOL) generate_thoroughly - Generates based on thorough (slow) record-by-record check for missing or outdated ScrapPages.
#
def generate_thoroughly

  current_batch = BatchJob.create(:comments=>@generation_batch_comment)

  scrap_pages_hash = {}
  scrap_topics_needing_update_array = []
  parallel_texts_needing_update_array = []

  # Buffer all the Scrap Pages
  # NB: This code retrieves all the ScrapPages and buffers into a hash to compare!
  cols = "id,cacheable_id,cacheable_type,created_at"
  scrap_pages=nil
  tickcount("RETRIEVAL of ALL existing ScrapPages") do
    scrap_pages=ScrapPage.find(:all, :select => cols)
    scrap_pages.each{ |sp| scrap_pages_hash["#{sp.cacheable_id}__#{sp.cacheable_type}"] = sp }
  end
  puts "Existing Scrap Pages Found: #{scrap_pages.length}" unless @options[:silent]

  # Collect missing or out of date ScrapTopics scrap pages
  # NB: Use Collection model so to exclude any child classes of ScrapTopic
  puts "RETRIEVAL of ALL ScrapTopics" unless @options[:silent]
  puts "ScrapTopics Found: #{Collection.count(:conditions => "type = 'ScrapTopic'")}" unless @options[:silent]
  collections=Collection.find(:all, :select => "id, updated_at, created_at, type", :conditions => "type = 'ScrapTopic'", :order => "id ASC")
  collections.each do |rec| 
    curr_rec = scrap_pages_hash["#{rec.id}__#{rec.type}"]
    if curr_rec.nil? or @force_scrap_update
      scrap_topics_needing_update_array << rec.id
    elsif curr_rec.created_at < rec.updated_at
      puts "RecToUpdate #{rec.id}__ScrapTopic (#{curr_rec.created_at} vs #{rec.updated_at})" unless @options[:silent]
      curr_rec.expire_cache if @options[:cache_fu_on] #cache_fu integration
      scrap_topics_needing_update_array << rec.id
    end
  end
  puts "#{scrap_topics_needing_update_array.length} ScrapTopics need updating" unless @options[:silent]

  puts "RETRIEVAL of ALL ScrapTopics" unless @options[:silent]
  puts "ParallelTexts Found: #{ParallelText.count}" unless @options[:silent]
  parallel_texts=ParallelText.find(:all, :select => "id, updated_at, created_at", :order => "id ASC")
  parallel_texts.each do |rec| 
    curr_rec = scrap_pages_hash["#{rec.id}__ParallelText"]
    if curr_rec.nil? or @force_scrap_update
      parallel_texts_needing_update_array << rec.id
    elsif curr_rec.created_at < rec.updated_at
      puts "RecToUpdate #{rec.id}__ParallelText (#{curr_rec.created_at} vs #{rec.updated_at})" unless @options[:silent]
      curr_rec.expire_cache if @options[:cache_fu_on] #cache_fu integration
      parallel_texts_needing_update_array << rec.id
    end
  end
  puts "#{parallel_texts_needing_update_array.length} ParallelTexts need updating" unless @options[:silent]

  # Loop arrays incrementally and call 'add_scrap_pages'
  loop_and_save_scrap_pages("ScrapTopic", scrap_topics_needing_update_array, current_batch)
  loop_and_save_scrap_pages("ParallelText", parallel_texts_needing_update_array, current_batch)

  # Clean up!
  finalise_batch(current_batch)
  return true

end

#
# (BOOL) loop_and_save_scrap_pages : type, data_array, current_batch
#
def loop_and_save_scrap_pages(rec_type, data_array, current_batch, method="insert")
  last = 0
  if (len = data_array.length) > 0
    while last <= data_array.length
      first = last
      last = (first + @options[:import_page_size] > len ? len : first + @options[:import_page_size])
      add_scrap_pages(rec_type, ["id IN (?)", data_array[first..last]], current_batch) if method =="insert"
      update_scrap_pages(rec_type, ["id IN (?)", data_array[first..last]], current_batch) if method =="update"
      last = last + 1
      puts "#{last} / #{len} of #{rec_type}" unless @options[:silent]
    end
  end
  return true
end


#
# (int) update_scrap_pages : type = "ScrapTopic" or "ParallelText"
#                            conditions = SQL condition block to get records to generate
#
def update_scrap_pages(type,conditions,current_batch)
  puts "Invalid call to update_scrap_pages()" and return false if type != "ParallelText" and type != "ScrapTopic"
  
  view_base = ActionView::Base.new(Rails::Configuration.new.view_path)
  records = get_source_records(type, conditions)
  tickcount("UPDATING of ScrapPages") do
    records.each do |rec|
      content = get_rendered_page(type, rec, view_base)
      @cn.execute("UPDATE scrap_pages SET import_batch_id = #{current_batch.id}, title = '#{rec.title}', slug_cache = '#{rec.slug_cache}', content = '#{content}', language_id = #{rec.language_id}, delta = 1 WHERE cacheable_id = #{rec.id} AND cacheable_type = '#{type}'") if @options[:db_active]
      puts "Updated scrap_page #{rec.id}" unless @options[:silent]
    end
  end

end

#
# (int) add_scrap_pages : type = "ScrapTopic" or "ParallelText"
#                         conditions = SQL condition block to get records to generate
#
def add_scrap_pages(type,conditions,current_batch)
  puts "Invalid call to add_scrap_pages()" and return false if type != "ParallelText" and type != "ScrapTopic"

  sql_line_count = loop_count = 0
  buffered_lines = buffered_ids = ""

  # Kill condition is based on ID cardinality
  newest_scrap_id = ScrapPage.maximum(:id).to_i
  kill_old_date_condition = "AND id <= #{newest_scrap_id}" if newest_scrap_id != 0
  kill_old_date_condition ||= ""

  view_base = ActionView::Base.new(Rails::Configuration.new.view_path)
  records = get_source_records(type, conditions)
  tickcount("INSERTION of ScrapPages") do
    records_last_id = records.last.id
    records.each do |rec|
      loop_count=loop_count+1
      puts "Buffered No. #{loop_count}" unless @options[:silent]
      # EXPERIMENTAL: Skip records not meant for this worker
      if !@multiple_processes_enabled or ((@worker_id.to_i+1) != (rec.id % @total_worker_processes.to_i))
        sql_line_count=sql_line_count+1
        content = get_rendered_page(type, rec, view_base)
        buffered_lines = (buffered_lines == "" ? "" : buffered_lines + ",\n") + "(#{rec.id}, '#{type}', #{current_batch.id}, #{@options[:english_lang_id]}, '#{rec.title}', '#{rec.slug_cache}', '#{content}', 1, NOW())"
        buffered_ids = (buffered_ids == "" ? "" : buffered_ids + ", ") + "#{rec.id}"
      else
        puts "skipped #{rec.id}" unless @options[:silent]
      end
      if sql_line_count == @options[:import_page_size] or records.length == loop_count
        @cn.insert("INSERT INTO scrap_pages(cacheable_id, cacheable_type, import_batch_id, language_id, title, slug_cache, content, delta, created_at) VALUES #{buffered_lines}") if @options[:db_active]
        @cn.execute("DELETE FROM scrap_pages WHERE cacheable_id IN (#{buffered_ids}) #{kill_old_date_condition}") if @options[:db_active] and newest_scrap_id != 0
        puts ">>>  #{loop_count} -- Just inserted #{sql_line_count} ScrapPages at #{Time.now})" unless @options[:silent]
        buffered_lines = ""
        buffered_ids = ""
        sql_line_count = 0
      end
    end
    cond = []
    cond << ["id > ?", records_last_id]
    cond << conditions
    records = get_source_records(type, ScrapPage.merge_conditions(*cond))
  end
  return loop_count
end

#
# (AR Collection) get_source_records: type = "ScrapTopic" or "ParallelText"
#                                     conditions = SQL conditions to get the records
#
def get_source_records(type,conditions)
  if type =="ScrapTopic"
    return ScrapTopic.find(:all, :conditions => conditions, :limit => @options[:import_page_size], :include => "scraps", :order => "id ASC")
  else
    return ParallelText.find(:all, :conditions => conditions, :limit => @options[:import_page_size], :order => "id ASC")
  end
end

#
# (text) get_rendered_page: renders and returns the page
#
def get_rendered_page(type,rec, view_base)
  content = view_base.render :partial => "scraps/scrap_topic_show", :locals => { :scrap_topic => rec, :scraps => rec.scraps } if type == "ScrapTopic"
  content = view_base.render :partial => "scraps/scrap", :locals => { :scrap => rec } if type == "ParallelText"
  content.gsub!("'" , '\\\\\'')
  return content
end
