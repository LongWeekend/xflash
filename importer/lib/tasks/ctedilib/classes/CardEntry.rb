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
     reading = record[:reading].downcase() unless !record[:reading]
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
   
   def similar_to?(entry, criteria)
     # Make sure the entry is kind of Entry class
     if !entry.kind_of?(Entry)
       return false
     end
     
     # Comparing the headword
     same_headword_trad = self.headword_trad == entry.headword_trad
     same_headword_simp = self.headword_simp == entry.headword_simp
     same_headword = same_headword_trad || same_headword_simp
     
     # Comparing the pinyin/reading
     same_pinyin = self.pinyin == entry.pinyin
     
     # Comparing the meaning
     
     return same_headword && same_pinyin
   end
  
end