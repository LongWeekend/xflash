module Sluggable

  def slug
    self.slug_cache
  end
  
  def slug=(str)
    self.slug_cache = slugify(str)
  end
  
  def slugify(str)
    str = str.to_s.gsub(/[[:space:]|[:punct:]]/, '')
    str = " " + str.split.join(" ")
    return str.gsub(/ (.)/) { $1.upcase }
  end

  module_function :slugify

end