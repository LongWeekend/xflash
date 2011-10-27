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