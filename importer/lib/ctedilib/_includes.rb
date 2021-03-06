load File.dirname(__FILE__) + "/config/_options.rb"
load File.dirname(__FILE__) + "/includes/DebugHelpers.rb"
load File.dirname(__FILE__) + "/includes/RakeHelpers.rb"
load File.dirname(__FILE__) + "/includes/DatabaseHelpers.rb"
load File.dirname(__FILE__) + "/includes/ImporterHelpers.rb"
load File.dirname(__FILE__) + "/includes/String+LWE.rb"
load File.dirname(__FILE__) + "/includes/Array+LWE.rb"

# Helpers
load File.dirname(__FILE__) + "/classes/BulkSQLRunner.rb"

# Custom Exception class
load File.dirname(__FILE__) + "/classes/ParseException.rb"
load File.dirname(__FILE__) + "/classes/HumanParseExceptionHandler.rb"

# Different entry types
load File.dirname(__FILE__) + "/classes/Meaning.rb"
load File.dirname(__FILE__) + "/classes/Entry.rb"
load File.dirname(__FILE__) + "/classes/CEdictEntry.rb"
load File.dirname(__FILE__) + "/classes/InlineEntry.rb"
load File.dirname(__FILE__) + "/classes/HSKEntry.rb"
load File.dirname(__FILE__) + "/classes/BookEntry.rb"
load File.dirname(__FILE__) + "/classes/BigramEntry.rb"
load File.dirname(__FILE__) + "/classes/CSVEntry.rb"

# For parsing CEDICT and tag lists
load File.dirname(__FILE__) + "/classes/Parser.rb"
load File.dirname(__FILE__) + "/classes/DiffParser.rb"
load File.dirname(__FILE__) + "/classes/CEdictParser.rb"
load File.dirname(__FILE__) + "/classes/WordListParser.rb"

# Group and Tag related importer
load File.dirname(__FILE__) + "/classes/GroupImporter.rb"
load File.dirname(__FILE__) + "/classes/TagConfiguration.rb"
load File.dirname(__FILE__) + "/classes/HumanTagImporter.rb"
load File.dirname(__FILE__) + "/classes/TagImporter.rb"
load File.dirname(__FILE__) + "/classes/EntryCache.rb"

# Importers
load File.dirname(__FILE__) + "/classes/CEdictImporter.rb"
load File.dirname(__FILE__) + "/classes/CEdictExporter.rb"

# Required Gems
require 'base64'
require 'digest/md5'
