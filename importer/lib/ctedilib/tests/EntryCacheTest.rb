require 'test/unit'

class EntryCacheTest < Test::Unit::TestCase
  
  include DatabaseHelpers
  
  def test_caching
    cache = EntryCache.new
    cache.prepare_cache_if_necessary
  
    #TODO: get this number on the spot from cards_staging
    # The total number of entries (currently) -- make sure we have them all
    total_cards = -1
    $cn.execute("SELECT COUNT(*) FROM cards_staging").each do |res|
      total_cards = res[0]
    end
    assert_equal(total_cards,cache.card_entries.count)
    
    # Total number of cards that are duplicates
    number_simp_dupes = -1
    $cn.execute("SELECT SUM(count) FROM (SELECT headword_simp, count(*) as count FROM cards_staging GROUP BY headword_simp ORDER BY count DESC) as dupes WHERE count > 1").each do |res|
      number_simp_dupes = res[0]
    end
    assert_equal((total_cards - number_simp_dupes),cache.size_of_headword_cache(:simp))

    number_trad_dupes = -1
    $cn.execute("SELECT SUM(count) FROM (SELECT headword_trad, count(*) as count FROM cards_staging GROUP BY headword_trad ORDER BY count DESC) as dupes WHERE count > 1").each do |res|
      number_trad_dupes = res[0]
    end
    assert_equal((total_cards - number_trad_dupes),cache.size_of_headword_cache(:trad))

    # FOR REFERENCE:
    # Number of headwords that have duplicates
    #SELECT COUNT(headword_simp) FROM (SELECT headword_simp, count(*) as count FROM cards_staging GROUP BY headword_simp ORDER BY count DESC) as dupes WHERE count > 1
    #1714
    #SELECT COUNT(headword_trad) FROM (SELECT headword_trad, count(*) as count FROM cards_staging GROUP BY headword_trad ORDER BY count DESC) as dupes WHERE count > 1
    #1470

    
  end
  
end