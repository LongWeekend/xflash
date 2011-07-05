# Adds numeric to String
class String
   def numeric?
      # Check if every character is a digit
      !!self.match(/\A[0-9]+\Z/)
   end
end