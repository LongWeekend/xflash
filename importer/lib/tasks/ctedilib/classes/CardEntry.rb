# Single entry class from a database card row
class CardEntry < Entry
  
  include ImporterHelpers
  
  #===================================
   # Parses a line from the data source
   #===================================
   def parse_line (record = "")
     init()

     # A little sanity checking on line
     if ((record.nil?) && (!record.kind_of? Hash))
       pp ("Record supplied on the Card Entry is either nil or is not a Hash type")
       return false
     end
     
     @id = record[:card_id] unless !record[:card_id]
     @headword_trad = record[:headword_trad] unless !record[:headword_trad]
     @headword_simp = record[:headword_simp] unless !record[:headword_simp]
     
     reading = ""
     reading = record[:reading] unless !record[:reading]
     @pinyin = get_pinyin_unicode_for_reading(reading)
     
     # Get the meanings (compbination with the meaning column and the meaning_fts)
     entire_meanings = Array.new()
     meanings = record[:meaning].split(";") unless !record[:meaning]
     meaning_fts = record[:meaning_fts].split(";") unless !record[:meaning_fts]
     # Remove the spaces and put them into a single array.
     entire_meanings.add_element_with_stripping_from_array!(meanings)
     entire_meanings.add_element_with_stripping_from_array!(meaning_fts)
     # Remove dupliacates
     @meanings = entire_meanings.uniq()
     
     # Get whether the card is a erhua variant
     erhua_variant = false
     erhua_variant = record[:is_erhua_variant] == 1 ? true : false unless !record[:is_erhua_variant]
     @is_erhua_variant = erhua_variant
     
     # Get whether the card is a variant.
     variant_of = false
     variant_of = record[:is_variant] == 1 ? true : false unless !record[:is_variant]
     @variant_of = variant_of
      
     #@references
   end
   
   def ==(another_card_entry)
     # If the another_card_entry is not CardEntry type
     # just return with false.
     if (!another_card_entry.kind_of?(CardEntry))
       return false
     end
     
     return self.id == another_card_entry.id
   end
   
   #def similar_to?(entry, match_criteria=$options[:likeness_level][:partial_match])
   def similar_to?(entry, match_criteria)
     # Make sure the entry is kind of Entry class
     if !entry.kind_of?(Entry)
       return false
     end
     
     same_headword, same_pinyin, same_meaning = false, false, false
     
     # Comparing the headword
     # NOTE: Please make sure that the entry is the one wanted to be matched from.
     # and self is the CARD.
     same_headword_trad = self.headword_trad == entry.headword
     same_headword_simp = self.headword_simp == entry.headword
     same_headword = same_headword_trad || same_headword_simp
     return false unless same_headword
     
     # Comparing the pinyin/reading
     same_pinyin = self.pinyin == entry.pinyin
     
     intersection = self.meanings & entry.meanings
     same_meaning = intersection.length() > 0
     
     return match_criteria.call(entry.headword, same_pinyin, same_meaning)
       
=begin 
     Comparing the meaning
     if (((match_criteria == $options[:likeness_level][:exact_match]) && (same_pinyin && same_headword)) ||
         ((match_criteria == $options[:likeness_level][:partial_match]) && (!(same_pinyin && same_headword))) ||
         ((match_criteria == $options[:likeness_level][:one_likeness_match]) && (!(same_pinyin || same_headword))))
          # Inside if body.
          intersection = self.meanings & entry.meanings
          same_meaning = intersection.length() > 0
     end

     if (match_criteria == $options[:likeness_level][:exact_match])
        # Return yes if all criterion is a match
        return same_headword && same_pinyin && same_meaning
     elsif (match_criteria == $options[:likeness_level][:partial_match])
        # Return yes if there is two likeness found
        return ((same_headword && same_pinyin) || 
                (same_headword && same_meaning) || 
                (same_pinyin && same_meaning))
      elsif (match_criteria == $options[:likeness_level][:one_likeness_match])
        # Return yes if there is one likeness found.
        return same_headword || same_pinyin || same_meaning
      end
      
      return false #If everything else fails, return with false
=end    
   end
  
end