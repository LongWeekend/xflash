#### KANJI DIC TO JFLASH IMPORTER ####
#### This is a combined parser/importer ####
class Kanjidic2JFlashImporter
  
  def initialize(kdic_file, krad_file)
    @kdic_file = kdic_file
    @krad_file = krad_file
  end
  
  # DESC: Parse kanjidic entries and insert into jFlash staging database"
  def run

    require 'nokogiri'
    connect_db

    # Get file and parse XML
    xml_file = File.open(@kdic_file, 'r')
    doc = Nokogiri::XML(xml_file,nil,'UTF-8')
    xml_file.close

    krad_lines = File.open(@krad_file, 'r')
    krad_data = {}
    krad_lines.each do |line|
      kd = line.split(" : ")
      krad_data[ kd[0] ] = kd[1].gsub(' ',',')
    end
    krad_lines.close
    prt "kRad data #{krad_data.length}"

    # Search for nodes by css
    tags = doc.css('kanjidic2 character')

    sql_lines_arr_kanji = []
    sql_lines_arr_readings = []
    sql_lines_arr_meanings = []
    missing_components = []
    line_count = 0

    tags.each do |tag|

      line_count +=1
      #prt_dotted_line

      kanji = tag.css('literal').first.text
      #prt "kanji: #{kanji}"

      radical = tag.css('radical rad_value[@rad_type = "classical"]').first.text
      #prt "radical: #{radical}"

      frequency = tag.css("misc freq").text
      frequency = 0 if frequency.empty? || frequency.nil?
      #prt "freq: #{frequency}"

      grade = tag.css("misc grade").text
      grade = 0 if grade.empty? || grade.nil?
      #prt "grade: #{grade}"

      jlpt = tag.css("misc jlpt").text
      jlpt = 0 if jlpt.empty? || jlpt.nil?
      #prt "jlpt: #{jlpt}"

      stroke_count = tag.css("misc stroke_count").text
      #prt "stroke_count: #{stroke_count}"
      
      if krad_data[kanji].nil?
        missing_components << kanji
        compononents = ""
      else
        components = krad_data[kanji].strip
      end
      #prt "components: #{components}"

      # Readings
      readings = []
      tag.css('reading_meaning rmgroup reading').each do |reading|
        #readings << { :reading => reading.text, :reading_type => reading['r_type'] }
        #prt "reading: #{reading.text} / #{reading['r_type']}"
        sql_lines_arr_readings << "INSERT INTO kanji_readings_staging (kanji, reading_type, reading) VALUES \n ('#{kanji}', '#{reading['r_type'].gsub("'" , '\\\\\'')}', '#{reading.text}');"
      end
      
      # Meanings
      meanings = []
      tag.css('reading_meaning rmgroup meaning').each do |meaning|
        lang = (meaning['m_lang'].nil? ? "en" : meaning['m_lang'] )
        #meanings << { :meaning => meaning.text, :language => lang }
        #prt "meaning: #{meaning.text} / #{lang}"
        sql_lines_arr_meanings << "INSERT INTO kanji_meanings_staging (kanji, meaning, language) VALUES \n ('#{kanji}', '#{meaning.text.gsub("'" , '\\\\\'')}', '#{lang}-#{line_count}');"
      end

      # Nanori
      nanoris = []
      tag.css('reading_meaning nanori').each do |nanori|
        nanoris << nanori.text
      end
      nanori = nanoris.join(', ')
      #prt "nanoris: #{nanoris}"
      
      xml_tag = tag.to_xml(:encoding => 'UTF-8')
      xml_tag.gsub!("'" , '\\\\\'')

      # Add to array
      sql_lines_arr_kanji << "INSERT INTO kanji_staging (kanji, radical, stroke_count, jlpt, grade, frequency, components, nanori, xml) VALUES \n ('#{kanji}', #{radical}, #{stroke_count}, #{jlpt}, #{grade}, #{frequency}, '#{components}', '#{nanori}', '#{xml_tag}');"
      prt "#{line_count} lines processed" if line_count%500 == 0 || line_count == tags.length

    end

    # Buffer to var and execute via CLI
    outtxt = ""
    outtxt = outtxt + sql_lines_arr_kanji.join("\n").to_s + "\n"
    outtxt = outtxt + sql_lines_arr_readings.join("\n").to_s + "\n"
    outtxt = outtxt + sql_lines_arr_meanings.join("\n").to_s + "\n"
    mysql_run_query_via_cli(outtxt)

    # How many components are missing (952!)
    prt missing_components.length

  end

end
