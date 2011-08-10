class Tags800WordsImporter < TagsBaseImporter
  
  def empty_staging_tables
    
  end
  
  def import
    # Open the connection to the database first
    connect_db()
    
    #Then do the loop by its super and process every data.
    super do |rec|
  
      select_query = "SELECT card_id, headword_trad, reading FROM cards_staging WHERE headword_trad = '%s'" % [rec.headword_trad]
      $cn.execute(select_query).each do | card_id, headword_trad, reading |
        #puts ("Processing: %s, with database record: %s" % [rec.headword_trad, headword_trad])
        
        puts ("Reading from database: %s, entry: %s" % [reading, rec.pinyin])
        
        
        get_pinyin_uniode_for_reading(reading)
        
        
      end
      
      #puts("----END----")
      
      
    end
    
  end
  
end