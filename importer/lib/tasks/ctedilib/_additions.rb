# Adds numeric to String
class String
  def numeric?
    # Check if every character is a digit
    !!self.match(/\A[0-9]+\Z/)
  end
   
  def hash_gsub(pattern, hash)
    gsub(pattern) do |m| 
      hash[m]
    end
  end
  
  def is_similar_pinyin?(another_reading)
    result = false
    begin
      # We dont want to compare with the string which still has the tone number.
      if (another_reading.scan($regexes[:pinyin_tone_without_normal]).length() > 0)
        puts ("Self: %s cannot be compared with: %s as it has not been converted to a pinyin unicode." % [self, another_reading])
        return false
      end
      
      # Do the actual comparison.
      if (self == another_reading)
        return true
      else
        # Implement to check the tone 5
        return false
      end
      
    end unless !another_reading.kind_of?(String)
    return false
  end
end

class Array
  
  def add_element_with_stripping_from_array!(another_array)
    # Make sure that another_array is actually an array.
    begin
      another_array.each do | element |
        index = self.length()
        # Insert the "stripped" element into the self object.
        # Insertion happens from the back. (FIFO Queue-like)
        self.insert(index, element.strip())
      end # End loop for each element
    end unless !another_array.kind_of?(Array)
  end
  
end