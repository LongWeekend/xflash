require 'redcloth'

module WikiSemanticMarkup

  class WSM < String
  
    # Remember, Wsmc < String!
    def initialize( string )
      super( string )
    end

    # Methods for extending an existing object
    def self.extended(obj)
      class << obj

        def self.tag_contents(tagname)
          t = self.dup.split(/\{key\}(.*)\{key\}/)
          t
        end
            
        def self.tag_exists?(tagname)
          t = self.dup.split(/\{key\}(.*)\{key\}/)
          if t.size > 0
            true
          else
            false
          end
        end
    
        def self.validate!(tags)
          true
        end

        def self.isvalid?(tags)
          true
        end

        def self.to_formatted_text
          true
        end

        # Converts WSM to HTML. Method name and usage inspired by RedCloth.
        def self.to_html
=begin
          text = self.dup
          return "" if text == "" # If it's empty, don't bother processing it!

          # Process {key}{/key} elements.
          text.gsub!( /\{word(( +(@|\$|%)[a-zA-Z0-9]+)*) *\}(.*)\{word\}/ ) do
          text.gsub!( /\{key\}(.*)\{key\}/ ) do
            tags = $1
            content = $4
            "<div class=\"word\">#{ content } #{ tags_to_html( tags ) }</div>"
          end
          
          # Process {usage}{/usage} elements.
          # This does not number things. Adding a '#' for use with Textile
          # seems to break RedCloth. Perhaps using JavaScript and DOM?
          text.gsub!( /\{usage(( +(@|\$|%)[a-zA-Z0-9]+)*) *\}(.*)\{usage\}/ ) do
            tags = $1
            content = $4
            "<div class=\"usage\">#{ content } #{ tags_to_html( tags ) }</div>"
          end
          
          # Process {pair}{/pair} elements.
          # How do we display tags and notes for {pair}{/pair} elements?
          text.gsub!( /\{pair(( +(@|\$|%)[a-zA-Z0-9]+)*) *\}/, "<div class=\"pair\">" )
          text.gsub!( /\{pair}/, "</div>" )
          
          # Process {triplet}{/triplet} elements.
          # How do we display tags and notes for {triplet}{/triplet} elements?
          text.gsub!( /\{triplet(( +(@|\$|%)[a-zA-Z0-9]+)*) *\}/, "<div class=\"triplet\">" )
          text.gsub!( /\{triplet}/, "</div>" )
          
          # Process {sentence}{/sentence} element.
          # As easy as {word}.
          text.gsub!( /\{sentence(( +(@|\$|%)[a-zA-Z0-9]+)*) *\}(.*)\{sentence\}/ ) do
             tags = $1
             content = $4
             "<div class=\"sentence\">#{ content } #{ tags_to_html( tags ) }</div>"
          end
          return text.strip
=end
        end
      end
    end

    #Class method for extending the object passed in
    def self.WSMize(obj, option)
      obj.extend WSMarkup
      obj.something = something if something
      obj
    end

    def self.validate(obj, klass)
      # Validate
          # word
          # example
          # page (do macros exist and are they applied properly??)
    end

    private
      # Converts a list of tags to HTML.
      # This may be possible with one "gsub!", but it'd require
      # a more complex RegEx pattern and a do block.
      def tags_to_html( tags )
        tags.strip!
        return "" if tags == "" # If it's empty, don't bother processing it!
        tags.gsub!(/@([a-zA-Z0-9]+)/, '<span class="context_tag">\1</span>') # Context tags
        tags.gsub!(/\$([a-zA-Z0-9]+)/, '<span class="system_tag">\1</span>') # System tags
        tags.gsub!(/%([a-zA-Z0-9]+)/, '<span class="grammar_tag">\1</span>') # Grammar tags   
        return tags
      end
  end
end