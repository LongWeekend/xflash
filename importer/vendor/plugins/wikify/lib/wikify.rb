require 'redcloth'

module Wikify
	def wikify(options = {})
		return "" if empty?

		marker = '%!%!%'
		num = 0
		replace = [ ]

		# @code@ is a shortcut for {{{code}}}
		out = self.gsub( /(!?)(@(\S.*?\S)@)/ ) do |match|
			$1 == "!" ? $2 : "{{{#{$3}}}}"
		end

		# Code Blocks
		#   replace {{{triple braced blocks}}}
		out.gsub!( /(!?)\{\{\{(\r?\n)?(.*?)(\r?\n)?\}\}\}/m ) do |match|
			unless $1 == "!"
				r = $3
				p1, p2 = "", ""
				p1, p2 = "<pre class=\"code\">", "</pre>" if $2 =~ /^[\n\r]/
				replace[num+=1] = p1 + "<code>" + "#{r}" + "</code>" + p2
				marker + num.to_s + marker
			else
				match[1,match.length]
			end
		end

		# Wiki Links
		#   replace "[bracketed words]" of the following types:
		#     [wiki page name]
		#     [wiki page name|display text]
		#     [http://externallink.com]
		#     [http://externallink.com|display text]
		#     [http://externallink.com display text]
		#     [ticket:id]
		#   do not replace if preceded by an "!"
		out.gsub!( /(!?)\[(.*?)(\|(.*?))?\]/ ) do |match|
			if $1 == "!"
				match[1,match.length]
			else
				if $2.include? ":"
					space_parts = $2.split(' ')
					parts = $2.split(':')
					class_str = "external"
					href = space_parts.shift
					link_text = $4 || ( parts.empty? ? $2.gsub(/^https?:\/\//, '') : parts.join(' ') )
				else
					class_str = (defined? Page && Page.exists?($2)) ? "" : "notfound"
					href = "/page/#{CGI.escape($2.strip)}"
					link_text = $4 || $2
				end
				class_str &&= ' class="' + class_str + '"'
				replace[num+=1] = '<a href="' + href + '"' + class_str + '>' + link_text + '</a>'
				marker + num.to_s + marker
			end
		end

		# mask <a> links from URL autolinking
		out.gsub!( /<a[^>]*>/ ) do |match|
			replace[num+=1] = match
			marker + num.to_s + marker
		end

		# protect <pre> blocks from hard breaks and URL autolinking
		out.gsub!( /<pre>.*?<\/pre>/m ) do |match|
			replace[num+=1] = match
			marker + num.to_s + marker
		end

		# autolink URLs
		# look for http://url.com
		# don't link if preceded by "!"
		out.gsub!( /(!?)(https?:\/\/(\S+))([.!?,)]?)/ ) do |match|
			if $1 == '!'
				$2 + $4
			else
				replace[num+=1] = '<a href="' + $2 + '" class="external">' + $3 + '</a>'
				marker + num.to_s + marker + $4
			end
		end

		# hard breaks (the RedCloth :hard_breaks option seems to be broken)
		out.gsub!( /([^\s|][ \t]*?)(\r?\n[^\r\n])/ ) do |match|
			"#{$1}<br />#{$2}"
		end

		# replace temporary tags
		out.gsub!( Regexp.new(marker + '([0-9]+)' + marker) ) do |match|
			replace[$1.to_i]
		end

		# shortcut for notice on legacy pages
		out.gsub!( /#legacy.*?#/ ) do
			'<div id="legacy">
		  I am hideous because I was imported from the old wiki.<br />
		  *Please fix me!*
		</div>
			'
		end

		# RedCloth Textile parsing
		RedCloth.new(out, [:no_span_caps]).to_html(
																 :textile
																)
	end
end

class String
	include Wikify
end
