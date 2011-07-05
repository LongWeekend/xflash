#----------------------------------------------------------------------------#
#  EDICT NameSpace
#----------------------------------------------------------------------------#
namespace :edict do

  desc "EDICT2 Importer Task, ACCEPTS src={source file path} | from={start line} | to={max lines to process} | kill=true/false {empties all related tables!}"
  task :import => :environment do
    load_library(true)
    empty_tables if get_cli_empty_tables
    results = process_edict("extract", get_cli_start_point, get_cli_break_point)
    npedia_import_data(results[:data])
    unless @options[:silent]
      puts "---------------------------------------------------"
      puts "new headwords: " + results[:data].length.to_s
      puts "new usages: " + results[:count].to_s
    end
  end

  namespace :generate do
    desc "Hydrate memcached with all ScrapPage objects via cache_fu plugin"
    task :memcached => :environment do
      @cache_fu_on = true
      load_library
      scrap_pages = nil
      at_a_time = 25000
      tickcount("SELECT #{25000} ScrapPages"){ scrap_pages=ScrapPage.find(:all, :limit => at_a_time, :order => "id ASC") }
      while scrap_pages.any?
        tickcount("Cache Update") do
          scrap_pages.each { |scrap_page| scrap_page.set_cache }
          tickcount("SELECT #{25000} ScrapPages") { scrap_pages=ScrapPage.find(:all, :conditions=> ["id > ?", scrap_pages.last.id], :limit => at_a_time, :order => "id ASC") }
        end
      end
    end

    desc "Freshen Scrap Pages : Updates scrap_pages based on last batch date, reindexes Sphinx delta. Best for low selectivity conditions (i.e. when in production and most scrap_pages are current)"
    task :freshen => :environment do
      load_library(true)
      tickcount("Freshening ScrapPages") do
        ## Memcached assumed to be running in production mode
        @options[:cache_fu_on] = true if ENV['RAILS_ENV'] == 'production'
        generate_by_date_updated
        if @options[:sphinx_enabled]
          update_sphinx_index("scrap_page_delta")
          update_sphinx_index("collections_by_scrap_topic_or_definition_title_core")
        end
      end
    end

    desc "Synchronize Scrap Pages : Replace cached views, reindexes Sphinx. More efficient for high or 100% selectivity, ACCEPTS 'force=true'"
    task :synchronize => :environment do
      load_library(true)
      tickcount("Synchronizing ScrapPages") do
        must_run = false
        skip_scrap_topics=false
        skip_parallel_texts=false

        if get_cli_forced
          # Run if forced!
          puts "You're forcing me to do this *lol*!" unless @options[:silent]
          must_run = true
        else
          # Run if scrap_pages missing (checked by source record count)
          if ScrapTopic.count != ScrapPage.count(:conditions => "cacheable_type = 'ScrapTopic'") or Scrap.count(:conditions=>"type = 'ParallelText'") != ScrapPage.count(:conditions=>"cacheable_type = 'ParallelText'")
            must_run = true
            puts "Record counts do not match, beginning thorough comparison" unless @options[:silent]
            skip_scrap_topics=true if ScrapTopic.count != ScrapPage.count(:conditions => "cacheable_type = 'ScrapTopic'")
            skip_parallel_texts=true if Scrap.count(:conditions=>"type = 'ParallelText'") != ScrapPage.count(:conditions=>"cacheable_type = 'ParallelText'")

          # Run if scrap_pages out of date (checked by date of most recent source records)
          elsif (most_recent_cached_scrap_topic.created_at > most_recent_scrap_topic.updated_at) or (most_recent_cached_parallel_text.created_at > most_recent_parallel_text.updated_at)
            puts "\nRETRIEVING dates of last updated records" unless @options[:silent]
            most_recent_cached_scrap_topic = ScrapPage.find(:first, :order=>"created_at DESC", :conditions => "cacheable_type = 'ScrapTopic'")
            most_recent_scrap_topic = ScrapTopic.find(:first, :order=>"created_at DESC")
            most_recent_cached_parallel_text = ScrapPage.find(:first, :order=>"created_at DESC", :conditions => "cacheable_type = 'ParallelText'")
            most_recent_parallel_text = ParallelText.find(:first, :order=>"created_at DESC")
            puts "Last updated record dates do not match, beginning thorough comparison" unless @options[:silent]
            must_run = true
          end

        end

        if must_run
          generate_thoroughly
          update_all_sphinx_indexes if @options[:sphinx_enabled]
        end

      end
    end
  end

  namespace :analyse do
    desc "EDICT2 Multipurpose Line Scanner: counts and displays matched lines, ACCEPTS rex=\"/{your regex}/\" | rex=\"{your string}\""
    task :scan => :environment do
      load_library(true)
      if ENV.include?("mode") && ENV['mode'] == "silent"
        mode="silent"
        @options[:silent] = mode
      else
        mode="noisy"
        @options[:silent] = mode
      end
      @counted = scan_source_file("edict2", mode)
      puts "---------------------------------------------------"
      puts "counted: " + @counted.to_s
    end

    desc "EDICT2 Source Tag Analyser, ACCEPTS src={source file path} | from={start line} | to={max lines to process}"
    task :tags => :environment do
      load_library
      results = process_edict("analyse", get_cli_start_point, get_cli_break_point)
      tickcount do
        results[:tags][:pos].flatten!
        results[:tags][:lang].flatten!
        results[:tags][:tag].flatten!
      end
      tickcount do
        results[:tags][:pos].uniq!
        results[:tags][:lang].uniq!
        results[:tags][:tag].uniq!
      end
      unless @options[:silent]
        puts "Tag Analysis Completed!"
        puts "# pos tags          : " + results[:tags][:pos].length.to_s + " (vs " + @good_tags[:pos].length.to_s + " known)"
        puts "# lang tags         : " + results[:tags][:lang].length.to_s + " (vs " + @good_tags[:lang].length.to_s + " known)"
        puts "# tag tags          : " + results[:tags][:tag].length.to_s + " (vs " + @good_tags[:tag].length.to_s + " known)"
        puts "---------------------------------------------------"
        new_pos = results[:tags][:pos] - @good_tags[:pos]
        new_lang = results[:tags][:lang] - @good_tags[:lang]
        new_tag = results[:tags][:tag] - @good_tags[:tag]
        unused_pos = @good_tags[:pos] - results[:tags][:pos]
        unused_lang = @good_tags[:lang] - results[:tags][:lang]
        unused_tag = @good_tags[:tag] - results[:tags][:tag]
        puts "+ new pos tags    : " + new_pos.join(', ').to_s if new_pos.length > 0 
        puts "+ new lang tags   : " + new_lang.join(', ').to_s if new_lang.length > 0 
        puts "+ new tag tags    : " + new_tag.join(', ').to_s if new_tag.length > 0 
        puts "---------------------------------------------------" if new_tag.length > 0 or new_lang.length > 0 or new_pos.length > 0
        pp
        puts "* unused pos tags   : " + unused_pos.join(', ').to_s if unused_pos.length > 0 
        puts "* unused lang tags  : " + unused_lang.join(', ').to_s if unused_lang.length > 0 
        puts "* unused tag tags   : " + unused_tag.join(', ').to_s if unused_tag.length > 0 
        pp
      end
    end
  end

end
#----------------------------------------------------------------------------#
