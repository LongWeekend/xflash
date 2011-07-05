############################################
#  TEdi (Tanaka Corpus / Edict2 Importer)
#         --- Options file ---
############################################

# Options/Defaults
$options = {}
$options[:default_break_point] = 0
$options[:verbose] = true
$options[:force_utf8] = false
$options[:cache_fu_on] = false
$options[:maximum_cards_per_tag] = 10000

# mysql DB Options
#$options[:mysql_name] = "jflash_import"
$options[:mysql_name] = "jflash_import"

$options[:mysql_port] = 3306
$options[:mysql_host] = "localhost"
$options[:mysql_username] ="root"
$options[:mysql_password] = ""

# sqlite DB Options
$options[:sqlite_bin] = "~/sqlite-3.6.21/sqlite3"
$options[:sqlite_name] = "jflash"
$options[:sqlite_username] ="root"
$options[:sqlite_password] = ""
$options[:sqlite_file_path] = {}
$options[:sqlite_file_path][:jflash_user]  = "/Users/pchapman/gitroot/jFlashBare/jFlash/sql/jFlash.db"
$options[:sqlite_file_path][:jflash_cards] = "/Users/pchapman/gitroot/jFlashBare/jFlash/sql/jFlash-CARD-1.1.db"
$options[:sqlite_file_path][:jflash_ex]    = "/Users/pchapman/gitroot/jFlashBare/jFlash/sql/jFlash-EX-1.1.db"
$options[:sqlite_file_path][:jflash_fts]   = "/Users/pchapman/gitroot/jFlashBare/jFlash/sql/jFlash-FTS-1.1.db"
#$options[:data_file_rel_path] = "./data/crunchytoast_jflash-sql/jflash_data_sources"
$options[:data_file_rel_path] = "./data/crunchytoast_jflash-sql"

$options[:card_types] = {
  'WORD' => 0,
  'KANA' => 1,
  'KANJI' => 2,
  'DICTIONARY' => 3,
  'SENTENCE' => 4
}

$options[:tanc_keyword_idx_types] = {
  'INDEX_WORD' => 0,
  'SENTENCE_WORD' => 1,
  'READING' => 2
}

# System Tag IDs
$options[:system_tags] = { 
  'LWE_FAVORITES' => 124,
  'BAD_DATA' => 160
}

# Global shared object cache (e.g. for pos tag data or similar 'get once' data)
$shared_cache = {}

# Global Registers (Instance Vars)
$options[:mysql_time_format] = "'%Y-%m-%d %H:%M:%S'"

# Regex Definitions
$regexes = {}
$regexes[:number_marker] = /\(\d?\d?\)\s{1}/
$regexes[:inside_hard_brackets] = /\[(\S+)\]/
$regexes[:inside_parens] = /\((\S+)\)/
$regexes[:inside_braces] = /\{(\S+)\}/
$regexes[:headwords] = /^(.+)\s+\[/
$regexes[:usages] = /\/(?:[^\z].*)\/\z/
$regexes[:usages_multiple] = /\(\d?\d?\)\s+(.*?)(?=[\/|\) ](?:\(\d+\)|\z))/
$regexes[:tag_like_text] = /[(|{]([^\)]*)[)|}]/
$regexes[:first_tag_like_block] = /\] \/\(([^\)]*)\)/
$regexes[:global_definition_tags] = /\] \/\(([^\)]*)\)/
$regexes[:compdic_style_global_tags] = /\{([^\})]*)\}/
$regexes[:lang_tag] = /(.+)\:(.*)/
$regexes[:lang_tag_origin_word] = /.+\:([^\)]*)/
$regexes[:bad_lang] = /^((.){0,4}): /
$regexes[:p_tag] = /\(P\)/
$regexes[:xreference] = /See ([^\)]*)/
$regexes[:antonym] = /ant: ([^\)]*)/
$regexes[:meaning_specifier] = /([^\)]*) only/
$regexes[:alternative_annotations] = /(\(([ァ-ヶ]+|[ぁ-ゞ]+|[一-熙]+|pron.|i.e.|e.g.|col.|with|usually|usu.|sometimes|orig.|from|in|often|in|from|esp.|abbr.|after|also|as) [^\)]*\))/
$regexes[:leading_spaces] = /^\s+/
$regexes[:trailing_spaces] = /\s+$/
$regexes[:duplicate_spaces] = /\s{2,}/
$regexes[:leading_trailing_slashes] = /^\/|\/$/
$regexes[:leading_trailing_slashes_greedy] = /^\s*\/|\/\s*$/ # Takes whitespace at the beginning or end with it!
$regexes[:slash_at_end_of_line] = /\/$/
$regexes[:first_english_token] = /([^\/|^\;]+)/
$regexes[:all_common_kanji] = /([一-熙]+)/
$regexes[:kana_or_basic_punctuation] = /[ぁ-んァ-ン\s\w、。;,~ー']/
$regexes[:not_kana_nor_basic_punctuation] = /[^ぁ-んァ-ン\s\w、。;,~ー']/
$regexes[:all_common_kanji_and_kana] = /([一-熙|ぁ-んァ-ン]+)/
$regexes[:comma_delimited] = /([^\,]+),*/
$regexes[:leading_space_slash] = /^\/\s{1}/
$regexes[:parenthetical] = /(\([^\)]*\))/
$regexes[:leading_parenthetical] = /^(\([^\)]*\))/
$regexes[:edict_entry_id] = /\/EntL(.+)\/$/
$regexes[:inlined_tags] = /\(([^\)]*)\)$/
$regexes[:whitespace_padded_slashes] = /\s*\/\s*/
$regexes[:any_whitespace] = /\s+/
$regexes[:origin_language_tag] = /[(](cf. [^\)]*)[)]/  # gets 'cf.' annotations in parens
$regexes[:alphanumeric] = /[A-Z|a-z|0-9]/
$regexes[:non_alphanumeric] = /[^A-Z|a-z|0-9]/

# Delimiters
$delimiters = {}
$delimiters[:jflash_readings]         = "; "
$delimiters[:jflash_meanings]         = "; "
$delimiters[:jflash_glosses]          = " / "
$delimiters[:jflash_headwords]        = "; "
$delimiters[:jflash_inlined_tags]     = ", "
$delimiters[:jflash_tag_coldata]      = ","
$delimiters[:jflash_jmdict_refs]      = ","
$delimiters[:jflash_tag_sourcenames]  = ","
$delimiters[:jflash_alt_headwords]    = ";"

$delimiters[:edict2_headwords]        = ";"
$delimiters[:edict2_readings]         = ";"
$delimiters[:edict2_readings_alt]     = ","
$delimiters[:edict2_senses]           = ";"
$delimiters[:edict2_inlined_tags]     = ","
$delimiters[:edict2_inlined_lang_tags]= ", "

# Tanaka Corpus Specific
$regexes[:tanc_tag_numeric] = /\[(\d+)\]/
$regexes[:tanc_tag_non_numeric] = /\[([^\d+])\]/
$regexes[:tanc_id_block] = /\#ID\=(.+)/
$regexes[:tanc_b_line_reference_block] = /[^ ]+\[\d+\]/

$delimiters[:tanc_refs_array]           = " "
$delimiters[:tanc_translated_pair]      = "\t"
$delimiters[:tanc_tagret_language_pair] = "#"
$delimiters[:tanc_id_pair]              = '_'
