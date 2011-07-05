# Rake task to extract texts from Ruby/ERb source in your application
# Scans patterns like "Hello World"[:hello_world] and dumps them into RAILS_ROOT/lang/new_language.yml
# TODO: Process incrementally, ie. dump newly added strings into existing localization files
require 'fileutils'

namespace :gibberish do

  desc "Extract all texts prepared to be translated from Ruby source"
  task :extract do
    DEFAULT_LANG = "en"
    count, keys, out = 0, [], "# Localization dictionary for the 'Gibberish' plugin (#{RAILS_ROOT.split('/').last})\n\n"
    Dir["#{RAILS_ROOT}/app/**/*"].sort.each do |path|
        unless ( matches = File.new(path).read.scan(/['"]([^'"]*)['"]\[\:([a-z1-9\_]*)\]/) ).empty?
          print "."
          out << "# -- #{File.basename(path)}:\n"          
          matches.each do |m| 
            out << "#{m[1]}: \"#{m[0]}\"\n" unless keys.include? m[1]
            keys << m[1]
          end
          out << "\n"                                      
          count +=1
        end if FileTest.file? path
    end
    FileUtils.mkdir_p File.join(RAILS_ROOT, 'lang') # Ensure we have lang dir
    File.open( File.join(RAILS_ROOT, 'lang', "#{DEFAULT_LANG}.yml"), "w") { |file| file << out } 
    puts "\nProcessed #{count} files and dumped YAML into #{RAILS_ROOT}/lang/new_language.yml"
  end

  desc 'Translate text with Google Translate by passing in a lang var'
  task :translate do
    require 'cgi'
    require 'open-uri'
    require 'timeout'
 
    en = File.open('lang/en.yml').read
    lang = ENV['lang']
    lang_text = String.new
 
    # parse through each line in the en.yml file
    en.each do |line|
      line.scan( /(.*?): "(.*?)"/ ) do |label, text|
        # send the text to Google Translate
        trans = CGI.escape(text)
        puts "translating: #{trans}"
        res = open("http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=#{trans}&langpair=en%7c#{lang}").read
        trans_text =  res.scan( /translatedText\":\"(.*?)\"/ )[0][0] rescue ""
        lang_text << "#{label}: \"#{trans_text}\"\n"
      end
    end
 
    # write final text to fr.yml file
    File.open("lang/#{lang}.yml", 'w+') { |f| f.write(lang_text) }
  end

  desc 'Translate a phrase with Google Translate by passing in a lang and phrase var'
  task :phrase do
    require 'cgi'
    require 'open-uri'
    require 'timeout'
   
    lang = ENV['lang']
    phrase = ENV['phrase']
    trans_phrase = CGI.escape(phrase)
   
    res = open("http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=#{trans_phrase}&langpair=en%7c#{lang}").read
    trans_text =  res.scan( /translatedText\":\"(.*?)\"/ )[0][0] rescue ""
   
    puts "Translated Text:"
    puts " -- En: #{phrase}"
    puts " -- #{lang.capitalize}: #{CGI.unescape(trans_text)}"
  end

end