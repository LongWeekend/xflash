class Meaning

  @meaning
  @tags

  def initialize(meaning = "",tags = [])
    @meaning = meaning
    @tags = tags
  end
  
  def ==(obj)
    return true if (obj.meaning == @meaning && tags.eql?(@tags))
    return false
  end
  
  def meaning
    @meaning
  end
  
  def tags
    @tags
  end

end