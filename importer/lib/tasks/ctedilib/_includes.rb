#load File.dirname(__FILE__) + "/_options.rb"
#load File.dirname(__FILE__) + "/_modules.rb"
#load File.dirname(__FILE__) + "/_additions.rb"

# Helpers
load File.dirname(__FILE__) + "/classes/_bulk_sql.rb"

# Different entry types
load File.dirname(__FILE__) + "/classes/Entry.rb"
load File.dirname(__FILE__) + "/classes/CEdictEntry.rb"
load File.dirname(__FILE__) + "/classes/BookEntry.rb"
load File.dirname(__FILE__) + "/classes/CSVEntry.rb"
load File.dirname(__FILE__) + "/classes/HSKEntry.rb"

# Different parser types
load File.dirname(__FILE__) + "/classes/_parser.rb"
load File.dirname(__FILE__) + "/classes/CEdictParser.rb"
load File.dirname(__FILE__) + "/classes/HSKParser.rb"
load File.dirname(__FILE__) + "/classes/CSVParser.rb"
load File.dirname(__FILE__) + "/classes/BookListParser.rb"

# Importers
load File.dirname(__FILE__) + "/classes/_importer.rb"
load File.dirname(__FILE__) + "/classes/CEdictImporter.rb"

load File.dirname(__FILE__) + "/classes/CEdictExporter.rb"
#load File.dirname(__FILE__) + "/classes/_jflash_importer.rb"
#load File.dirname(__FILE__) + "/classes/_jflash_migration.rb"
#load File.dirname(__FILE__) + "/classes/_npedia_importer.rb"
#load File.dirname(__FILE__) + "/classes/_jmdict_parser.rb"
#load File.dirname(__FILE__) + "/classes/_tanc_parser.rb"
#load File.dirname(__FILE__) + "/classes/_tanc_2_jflash_importer.rb"
#load File.dirname(__FILE__) + "/classes/_kanjidic_2_jflash_importer.rb"

# Required Gems
require 'levenshtein'
require 'base64'