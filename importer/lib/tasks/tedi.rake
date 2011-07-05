####################################################################################################
# TEdi (Tanaka Corpus / Edict2 Importer)
# Author: crunchyt@crunchytoast.com
# Version 1.2
####################################################################################################
# 
# Command Line Usage:
# > rake edict2:import                             #imports default Edict file contents
# > rake tanc:import                               #imports default Tanaka Corpus file contents
# > rake edict2:import  src=/usr/local/edict2.txt  #imports custom Edict file contents
#
####################################################################################################

### Load options
load File.dirname(__FILE__) + "/tedilib/_options.rb"

### Default source files
@options[:default_edict_source] = "db/edictimp/edict2_utf8_20091207.txt"
@options[:default_tanc_source] = "db/edictimp/tanakac_20090522.txt"

### Database Options
@options[:import_page_size] = 350    # Size of each bulk insert "page"
@options[:db_active] = true          # DB modified if true
@options[:exclusive_access] = true   # Provides speed-ups if it's the only process accessing the DB

### Dependancy Options
@options[:sphinx_enabled] = true

# Load RAKE namespaces
load File.dirname(__FILE__) + "/tedilib/_namespace_tanc.rb"
load File.dirname(__FILE__) + "/tedilib/_namespace_edict.rb"
load File.dirname(__FILE__) + "/tedilib/_namespace_jflash.rb"


### Library file loader
def load_library(withdb=false)

  # Connect to default Npedi datasource

  @cn = ActiveRecord::Base.connection() if withdb
  load File.dirname(__FILE__) + "/tedilib/_process_import.rb"
  load File.dirname(__FILE__) + "/tedilib/_shared.rb"

  # Load import processing libraries
  load File.dirname(__FILE__) + "/tedilib/_edict2_to_npedia.rb"
  load File.dirname(__FILE__) + "/tedilib/_tanc_to_npedia.rb"
  load File.dirname(__FILE__) + "/tedilib/_edict2_to_jflash.rb"
  load File.dirname(__FILE__) + "/tedilib/_generate.rb"

  # Load RAKE namespaces
  #load File.dirname(__FILE__) + "/tedilib/_namespace_tanc.rb"
  #load File.dirname(__FILE__) + "/tedilib/_namespace_edict.rb"
  #load File.dirname(__FILE__) + "/tedilib/_namespace_jflash.rb"

  @options[:silent] = get_silent()
  return true

end