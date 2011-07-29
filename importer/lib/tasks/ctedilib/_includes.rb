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
load File.dirname(__FILE__) + "/classes/CEdictBaseImporter.rb"
load File.dirname(__FILE__) + "/classes/CEdictImporter.rb"
load File.dirname(__FILE__) + "/classes/CEdictExporter.rb"

# Required Gems
require 'levenshtein'
require 'base64'
