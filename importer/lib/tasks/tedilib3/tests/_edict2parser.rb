require 'test/unit'

class Edict2ParserTest < Test::Unit::TestCase

  def test_parse

    expected_entries =[]
    results_data = Edict2Parser.new(File.dirname(__FILE__) + "/../testdata/edict2-2.txt").run

    # Sanity tests
    assert(!results_data.nil?)
    assert(results_data.size > 0)

#    Ｍ [エム] /(n) (1) (See Ｓ) (abbr) letter 'M'/(2) Mega/(3) (col) masochist/masochistic/EntL2211550X/
    expected_entries << {:all_tags=>["n", "abbr", "col"],
     :headwords=>[{:headword=>"Ｍ", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"emu",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"エム",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[],
        :sense=>"letter 'M'",
        :references=>[{:type=>"xref", :target=>"Ｓ"}],
        :pos=>[],
        :cat=>["abbr"]},
       {:lang=>[], :sense=>"Mega", :references=>[], :pos=>[], :cat=>[]},
       {:lang=>[],
        :sense=>"masochist/masochistic",
        :references=>[],
        :pos=>[],
        :cat=>["col"]}],
     :jmdict_refs=>["2211550"],
     :cat=>["abbr", "col"],
     :common=>false}

#   ヽ [くりかえし] /(n) repetition mark in katakana/EntL1000000/
   expected_entries <<  {:all_tags=>["n"],
     :headwords=>[{:headword=>"ヽ", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"kurikaeshi",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"くりかえし",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[],
        :sense=>"repetition mark in katakana",
        :references=>[],
        :pos=>[],
        :cat=>[]}],
     :jmdict_refs=>["1000000"],
     :cat=>[],
     :common=>false}

#  Ｖシネマ [ブイシネマ] /(n) film released direct-to-video (trademark of Toei Company) (wasei: V-cinema)/EntL2451810/
    expected_entries << {:all_tags=>["n", "wasei"],
     :headwords=>[{:headword=>"Ｖシネマ", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"buishinema",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"ブイシネマ",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[{:word=>"V-cinema", :language=>"wasei"}],
        :sense=>
         "film released direct-to-video (trademark of Toei Company) (cf. V-cinema)",
        :references=>[],
        :pos=>[],
        :cat=>[]}],
     :jmdict_refs=>["2451810"],
     :cat=>[],
     :common=>false}
     
     
#  あん摩(P);按摩 [あんま] /(n,vs) (1) massage, esp. the Anma Japanese type of massage/(n) (2) (sens) masseur/masseuse/(P)/EntL1154320X/
    expected_entries <<{:all_tags=>["n", "vs", "sens", "common"],
     :headwords=>
      [{:headword=>"あん摩", :tags=>["common"], :priority=>[]},
       {:headword=>"按摩", :tags=>[], :priority=>[]}],
     :pos=>["n", "vs"],
     :readings=>
      [{:romaji=>"anma",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"あんま",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[],
        :sense=>"massage, esp. the Anma Japanese type of massage",
        :references=>[],
        :pos=>[],
        :cat=>[]},
       {:lang=>[],
        :sense=>"masseur/masseuse",
        :references=>[],
        :pos=>["n"],
        :cat=>["sens", "common"]}],
     :jmdict_refs=>["1154320"],
     :cat=>["sens", "common"],
     :common=>true}

#  お作り;お造り;御作り;御造り [おつくり] /(n) (1) make-up/(2) (ksb:) sashimi/EntL2140770X/
    expected_entries << {:all_tags=>["n", "ksb"],
     :headwords=>
      [{:headword=>"お作り", :tags=>[], :priority=>[]},
       {:headword=>"お造り", :tags=>[], :priority=>[]},
       {:headword=>"御作り", :tags=>[], :priority=>[]},
       {:headword=>"御造り", :tags=>[], :priority=>[]}],
     :pos=>["n"],
     :readings=>
      [{:romaji=>"otsukuri",
        :tags=>[],
        :headword_ref=>nil,
        :reading=>"おつくり",
        :priority=>[]}],
     :meanings=>
      [{:lang=>[], :sense=>"make-up", :references=>[], :pos=>[], :cat=>[]},
       {:lang=>[{:word=>"", :language=>"ksb"}],
        :sense=>"sashimi",
        :references=>[],
        :pos=>[],
        :cat=>[]}],
     :jmdict_refs=>["2140770"],
     :cat=>[],
     :common=>false}
     
     
# 意欲満々;意欲満満 [いよくまんまん(uK)] /(adj-no,adj-t,adv-to) full of zeal/highly motivated/very eager/EntL2041800X/
    expected_entries << {:jmdict_refs=>["2041800"],
       :headwords=>
        [{:headword=>"意欲満々", :tags=>[], :priority=>[]},
         {:headword=>"意欲満満", :tags=>[], :priority=>[]}],
       :pos=>["adj-no", "adj-t", "adv-to"],
       :readings=>
        [{:romaji=>"iyokumanman",
          :headword_ref=>nil,
          :tags=>["ukanji"],
          :reading=>"いよくまんまん",
          :priority=>[]}],
       :cat=>[],
       :common=>false,
       :meanings=>
        [{:lang=>[],
          :pos=>[],
          :cat=>[],
          :sense=>"full of zeal/highly motivated/very eager",
          :references=>[]}],
       :all_tags=>["adj-no", "adj-t", "adv-to"]}

    assert_equal(expected_entries[0], results_data[0])
    assert_equal(expected_entries[1], results_data[1])
    assert_equal(expected_entries[2], results_data[2])
    assert_equal(expected_entries[3], results_data[3])
    assert_equal(expected_entries[4], results_data[4])
    assert_equal(expected_entries[5], results_data[5])

    # REC 1:, TYPE: Reading hash expected length
    assert_equal(1, results_data[0][:readings].size)
    assert_equal(1, results_data[1][:readings].size)
    assert_equal(1, results_data[2][:readings].size)
##    pp results_data
  end
  
  def test_get_inline_tags
    expected = "(cf. V-cinema)"
    result = Edict2Parser.get_inline_tags("(wasei: V-cinema)")
    assert_equal(expected, result[:string], "Inline language tags not extracted correctly!")
  end

  def test_get_meanings
    meanings = Edict2Parser.get_meanings("お座り [おすわり] /(n,vs) (1) (chn) sit down/sit up/(2) Sit! (to a dog)/EntL2164820X/")
    expected = ["(chn) sit down/sit up", "Sit! (to a dog)"]
    assert_equal(expected, meanings, "Meanings were not split correctly!")

    meanings = Edict2Parser.get_meanings("ある限り;有る限り [あるかぎり] /(n) (1) (See 限り,有る) all (there is)/(exp,n-adv) (2) as long as there is/EntL1745510X/")
    expected = ["(See 限り,有る) all (there is)", "(exp,n-adv) as long as there is"]
    assert_equal(expected, meanings, "Meanings were not split correctly!")
    
    meanings = Edict2Parser.get_meanings("お姉さん(P);御姉さん [おねえさん] /(n) (1) (usu. お姉さん) (See 姉さん) (hon) elder sister/(2) (vocative) young lady/(3) (usu. お姐さん) miss (referring to a waitress, etc.)/(4) (usu. お姐さん) ma'am (used by geisha to refer to their superiors)/(P)/EntL1001990X/")
    expected = ["(usu. お姉さん) (See 姉さん) (hon) elder sister", "(vocative) young lady", "(usu. お姐さん) miss (referring to a waitress, etc.)","(usu. お姐さん) ma'am (used by geisha to refer to their superiors)/(P)"]
    assert_equal(expected, meanings, "Meanings were not split correctly!")
    
    meanings = Edict2Parser.get_meanings("掛ける(P);懸ける [かける] /(v1,vt) (1) (See 壁にかける) to hang (e.g. picture)/to hoist (e.g. sail)/to raise (e.g. flag)/(2) (See 腰を掛ける) to sit/(aux-v,v1) (3) to be partway (verb)/to begin (but not complete)/(4) (See 時間を掛ける) to take (time, money)/to expend (money, time, etc.)/(5) (See 電話を掛ける) to make (a call)/(6) to multiply/(7) (See 鍵を掛ける) to secure (e.g. lock)/(8) (See 眼鏡を掛ける) to put on (glasses, etc.)/(9) to cover/(10) (See 迷惑を掛ける) to burden someone/(11) (See 保険を掛ける) to apply (insurance)/(12) to turn on (an engine, etc.)/to set (a dial, an alarm clock, etc.)/(13) to put an effect (spell, anaesthetic, etc.) on/(14) to hold an emotion for (pity, hope, etc.)/(15) (also 繋ける) to bind/(16) (See 塩をかける) to pour (or sprinkle, spray, etc.) onto/(17) (See 裁判に掛ける) to argue (in court)/to deliberate (in a meeting)/to present (e.g. idea to a conference, etc.)/(18) to increase further/(19) to catch (in a trap, etc.)/(20) to set atop/(21) to erect (a makeshift building)/(22) to hold (a play, festival, etc.)/(aux-v) (23) (See 話し掛ける) (after -masu stem of verb) indicates (verb) is being directed to (someone)/(P)/EntL1207610X/")
    expected = ["(See 壁にかける) to hang (e.g. picture)/to hoist (e.g. sail)/to raise (e.g. flag)",
    "(See 腰を掛ける) to sit",
    "(aux-v,v1) to be partway (verb)/to begin (but not complete)",
    "(See 時間を掛ける) to take (time, money)/to expend (money, time, etc.)",
    "(See 電話を掛ける) to make (a call)",
    "to multiply",
    "(See 鍵を掛ける) to secure (e.g. lock)",
    "(See 眼鏡を掛ける) to put on (glasses, etc.)",
    "to cover",
    "(See 迷惑を掛ける) to burden someone",
    "(See 保険を掛ける) to apply (insurance)",
    "to turn on (an engine, etc.)/to set (a dial, an alarm clock, etc.)",
    "to put an effect (spell, anaesthetic, etc.) on",
    "to hold an emotion for (pity, hope, etc.)",
    "(also 繋ける) to bind",
    "(See 塩をかける) to pour (or sprinkle, spray, etc.) onto",
    "(See 裁判に掛ける) to argue (in court)/to deliberate (in a meeting)/to present (e.g. idea to a conference, etc.)",
    "to increase further",
    "to catch (in a trap, etc.)",
    "to set atop",
    "to erect (a makeshift building)",
    "to hold (a play, festival, etc.)",
    "(aux-v) (See 話し掛ける) (after -masu stem of verb) indicates (verb) is being directed to (someone)/(P)"]
    assert_equal(expected, meanings, "Meanings were not split correctly!")

    meanings = Edict2Parser.get_meanings("我人ども;和人ども [わひとども] /(n) (arch) you (familiar or derog.; usu. plural)/EntL2412010X/")
    expected = ["(n) (arch) you (familiar or derog., usu. plural)"]
    assert_equal(expected, meanings, "Semicolon in parens was not replaced correctly!!")

  end

  def test_get_inline_tags
    result = Edict2Parser.get_inline_tags("ice (eng: ice, ger: Eis)")
    expected = { :lang=> [{:word=>"ice", :language=>"en"}, {:word=>"Eis", :language=>"de"}],
      :string=>"ice (cf. ice)",
      :pos=>[],
      :references=>[],
      :custom=>[],
      :cat=>[]}
    assert_equal(expected, result, "Multiple language extraction failed!")

    result = Edict2Parser.get_inline_tags("(n) opus (lat:, eng:)")
    expected = {:lang=>[{:word=>"", :language=>"la"}, {:word=>"", :language=>"en"}],
      :string=>"opus",
      :pos=>["n"],
      :references=>[],
      :custom=>[],
      :cat=>[]}

    assert_equal(expected, result, "Multiple language extraction with empty origin words failed!")

    result = Edict2Parser.get_inline_tags("(also written 巴布 (ateji)) (See パップ剤) poultice (dut: pap)/cataplasm")
    expected = {:lang=>[{:word=>"pap", :language=>"du"}],
      :string=>"(also written 巴布 (ateji)) poultice (cf. pap)/cataplasm",
      :pos=>[],
      :references=>[{:type=>"xref", :target=>"パップ剤"}],
      :custom=>[],
      :cat=>[]}
    assert_equal(expected, result, "Single language extraction failed!")
  end

end