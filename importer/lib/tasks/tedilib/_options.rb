############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#         --- Options file ---
############################################

# Options/Defaults
@options = {}
@options[:default_break_point] = 0
@options[:debug] = true
@options[:silent] = false
@options[:force_utf8] = false
@options[:cache_fu_on] = false
@options[:merge_similar] = false

# Global Registers (Instance Vars)
@edict2_data = {}
@edict2_count = 0
@tanc_data = []
@tanc_count = 0
@all_tanc_tags = []
@ticks = {}
@mysql_time_format = "'%Y-%m-%d %H:%M:%S'"

# Regex Definitions
@regexes = {}
@regexes[:inside_hard_brackets] = /\[(\S+)\]/
@regexes[:headwords] = /^(.+)\s+\[/
@regexes[:tag_like] = /\(([^\)]*)\)/
@regexes[:lang_tag] = /(.+)\:/
@regexes[:lang_tag_origin_word] = /.+\:([^\)]*)/
@regexes[:p_tag] = /\(P\)/
@regexes[:usages] = /(\/)([^$].+)(\/)/
@regexes[:reference] = /\(See ([^\)]*)\)/
@regexes[:antonym] = /ant: ([^\)]*)/

@regexes[:reading_specifier_annotation] = /(\([^\)]* only\))/
@regexes[:alternative_annotations] = /(\(([ァ-ヶ]+|[ぁ-ゞ]+|[一-熙]+|pron.|i.e.|e.g.|col.|with|usually|usu.|sometimes|orig.|from|in|often|in|from|esp.|abbr.|ant:|after|also|as) [^\)]*\))/

@regexes[:block_marker] = /\(\d?\d?\)/
@regexes[:bad_lang] = /^((.){0,4}): /
@regexes[:leading_spaces] = /^\s+/
@regexes[:trailing_spaces] = /\s+$/
@regexes[:leading_trailing_slashes] = /^\/|\/$/
@regexes[:tanc_tag_non_numeric] = / \[([^\d+])\]/
@regexes[:tanc_id_block] = /\#ID\=[\d]+/
@regexes[:tanc_b_line_reference_block] = /[^ ]+\[\d+\]/
@regexes[:slash_at_end_of_line] = /\/$/
@regexes[:first_english_token] = /([^\/|^\;]+)/
@regexes[:all_common_kanji] = /([一-熙]+)/
@regexes[:not_kana_nor_basic_punctuation] = /[^ぁ-んァ-ン\s\w、。;,']/

# Known Tag Data
@good_tags = {}
@tanc_good_tags = []
@tanc_good_tags = ["M", "F"]
@good_tags[:pos] = ["adj", "adj-f", "adj-i", "adj-na", "adj-no", "adj-pn", "adj-t", "adv", "adv-n", "adv-to", "aux", "aux-adj", "aux-v", "conj", "ctr", "exp", "f", "h", "id", "int", "iv", "m", "n", "n-adv", "n-pref", "n-suf", "n-t", "num", "pref", "prt", "suf", "symbol", "u", "v1", "v4h", "v4r", "v5", "v5aru", "v5b", "v5g", "v5k", "v5k-s", "v5m", "v5n", "v5r", "v5r-i", "v5s", "v5t", "v5u", "v5u-s", "v5uru", "v5z", "vi", "vk", "vn", "vs", "vs-i", "vs-s", "vt", "vz"]
@good_tags[:lang] = ["ai", "ar", "bu", "ch", "de", "du", "el", "en", "es", "fr", "gr", "he", "id", "it", "kh", "ko", "ksb", "ktb", "kyb", "la", "ma", "ms", "nl", "no", "osb", "po", "pt", "rkb", "ro", "ru", "sa", "sv", "ta", "th", "thb", "ti", "tsb", "tsug", "wasei", "zh"]
@good_tags[:tag] = ["common", "2-ch term", "Buddh", "Catholic", "Edo-period", "Judeo-Christian", "MA", "X", "abbr", "aeronautical", "arch", "astronomical", "ateji", "baseball", "botanical", "botanical term", "chem", "chn", "col", "colour", "comp", "constellation", "derog", "ekana", "ekanji", "electrical", "fam", "fem", "food", "gagaku", "game of", "geom", "gikun", "gram", "hanafuda", "hon", "hum", "ikana", "ikanji", "io", "ling", "linguistic", "m-sl", "male", "male-sl", "masc", "math", "mil", "ng", "obs", "obsc", "okana", "okanji", "on-mim", "philosohical", "physics", "plant", "plant family", "poet", "pol", "political", "rare", "sens", "shogi", "sl", "sumo", "taxonomical", "telephone", "theatrical", "ukana", "ukanji", "vulg", "zoological"]
@good_tags_not_inlined = ["common"]
@tag_transformations = { "P" => "common", "san"=>"sa", "ita"=>"it", "tib"=>"ti", "tha"=>"th", "kor"=>"ko", "dut"=>"du", "chi"=>"ch", "gre"=>"gr", "spa"=>"es", "khm"=>"kh", "tah"=>"ta", "ara"=>"ar", "may"=>"ma", "rus"=>"ru", "ain"=>"ai", "nor"=>"no", "por"=>"po", "eng"=>"en", "bur"=>"bu", "was"=>"wasei", "lat"=>"la", "ger"=>"de", "fre"=>"fr", "uK"=>"ukanji", "uk"=>"ukana", "oK"=>"okanji", "ok"=>"okana", "eK"=>"ekanji", "ek"=>"ekana", "iK"=>"ikanji", "ik"=>"ikana", "Buddhist"=>"Buddh", "euph. for"=>"euphemism", "computer"=>"comp", "in geometry"=>"geom", "in gagaku"=>"gagaku", "in hanafuda"=>"hanafuda", "military"=>"mil" }
@tag_ignore_list = ["ant", "also", "lit", "USA", "from", "form", "Note"]
@bad_tags = {}
@possible_lang_tags ={}
