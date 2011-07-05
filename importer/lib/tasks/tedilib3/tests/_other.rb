require 'test/unit'
class OtherTest < Test::Unit::TestCase

  def test_iconv
    str ="袋鼯鼠"
    euc_str = Iconv.iconv("EUC-JP", "UTF-8", str).to_s
    utf8_str = Iconv.iconv("UTF-8", "EUC-JP", euc_str).to_s
    assert_equal(str, utf8_str, "Iconv conversion failed!")
  end
  
  def test_romaji_spacing
=begin
    connect_db
    existing_readings_hash = {}
    source_query = nil
    tickcount("Selecting Cards") do
      source_query = $cn.execute("SELECT card_id, headword, reading, romaji FROM cards_staging LIMIT 76825, 100")
    end
    source_query.each do |card_id, headword, reading, romaji|
      if !reading.index(",")
        existing_readings_hash[card_id] = { :headword => headword, :reading  => reading, :romaji => romaji }
      end
    end
    result_data = Importer.separate_romaji_readings(existing_readings_hash)
    ## pp existing_readings_hash
    ## pp result_data
    JFlashImporter.separate_romaji_readings
=end
  end

end