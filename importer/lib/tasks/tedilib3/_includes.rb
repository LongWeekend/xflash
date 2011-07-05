load File.dirname(__FILE__) + "/../../kana2rom.rb"
load File.dirname(__FILE__) + "/_options.rb"
load File.dirname(__FILE__) + "/_modules.rb"

load File.dirname(__FILE__) + "/classes/_importer.rb"
load File.dirname(__FILE__) + "/classes/_bulk_sql.rb"
load File.dirname(__FILE__) + "/classes/_parser.rb"
load File.dirname(__FILE__) + "/classes/_jflash_importer.rb"
load File.dirname(__FILE__) + "/classes/_jflash_migration.rb"
load File.dirname(__FILE__) + "/classes/_npedia_importer.rb"
load File.dirname(__FILE__) + "/classes/_jmdict_parser.rb"
load File.dirname(__FILE__) + "/classes/_edict2_parser.rb"
load File.dirname(__FILE__) + "/classes/_tanc_parser.rb"
load File.dirname(__FILE__) + "/classes/_tanc_2_jflash_importer.rb"
load File.dirname(__FILE__) + "/classes/_kanjidic_2_jflash_importer.rb"

# Required Gems
require 'levenshtein'
require 'base64'