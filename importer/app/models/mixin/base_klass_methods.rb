# This is independant of any class - additional class methods
module BaseKlassMethods
  def self.included receiver
    receiver.extend ClassMethods
  end

  # Return ancestor class name one level above AR Base
  module ClassMethods
    def ar_base_klass(obj)
      obj = self if obj.nil?
      this_klass = ""
      for klass in obj.class.ancestors do
        last_klass = this_klass
        this_klass = klass.to_s
        break if %w(Collection Scrap).include?(klass.to_s)
      end
      this_klass.to_s
    end
  end
end
