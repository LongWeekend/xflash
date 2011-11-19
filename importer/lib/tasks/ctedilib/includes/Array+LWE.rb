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
  
  # DESC: Combines arrays and ensures they are flatten/compacted/unique
  def self.combine_and_uniq_arrays(array1, *others)
    result = []
    result << array1
    others.each do |arr|
      result << arr
    end
    return result.flatten.compact.uniq
  end

  
end