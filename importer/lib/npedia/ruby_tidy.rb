#
# Requires:
# => HTML Tidy - Requires compiled HTML Tidy library ("tidylib.so" or "libtidy.dylib" in require path)
# => Ruby Tidy - "gem install tidy"
#
# See Also:
# => http://rubyforge.org/projects/tidy
# => http://tidy.sourceforge.net/docs/quickref.html
#

require 'tidy'

module RubyTidy
  os = Config::CONFIG["arch"]
  if os =~ /cygwin/
    Tidy.path = "/usr/bin/cygtidy-0-99-0.dll"
  elsif os =~ /darwin/
    Tidy.path = "/usr/lib/libtidy.dylib"
  else
    Tidy.path = "/opt/csw/lib/libtidy.so"
  end

  def tidy_example
    html = 'This is what I think…<br/><font size="5">You are a dunce!!</font><br/><br/><font size="2">Big text is great for <b>flaming</b> ppl!!</font><br><br>'
    xml = Tidy.open(:show_warnings=>true) do |tidy|
      tidy.options.output_xml = true        # output as well formed XHTML (pretty!)
      puts tidy.options.show_warnings
      xml = tidy.clean(html)
      puts tidy.errors
      puts tidy.diagnostics
      xml
    end
    puts xml
  end

  def tidy(html)
    xml = Tidy.open(:show_warnings=>false) do |tidy|
      tidy.options.logical_emphasis = true  # replace i/b with em/strong
      tidy.options.merge_divs = true        # replace redundant nested divs
      tidy.options.word_2000 = true         # remove Word 2000 crap
      tidy.options.bare = true              # remove Word HTML crap (again?)
      tidy.options.show_body_only = true    # only output fragment (no html/head/body tags!)
      tidy.options.punctuation_wrap = true  # wrap after unicode/cjk punctuation
      puts tidy.options.show_warnings
      xml = tidy.clean(html)
    end
    return xml
  end

end
