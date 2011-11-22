class Corpus < ScrapTopic

  has_many :parallel_texts
  has_one  :language

  # (Corpus) by_language : ACCEPTS Lanaguage Obj / Language Id/ Lanaguage Name / Language Code
  def self.by_language(obj)
    if obj.class.to_s =="Language"
      lang_id = obj.id
      puts "Language"
    elsif obj.to_i > 0
      lang_id = obj.to_i
      puts "Int"
    elsif obj.class.to_s == "String" and obj.length <= 3
      # 2-3 letter language code
      lang_id = Language.find_by_code(obj).id.to_i
      puts "String-code"
    else
      # Assume name of the language in English
      lang_id = Language.find_by_name(obj).id.to_i
      puts "String-name"
    end
    return self.find_by_language_id(lang_id)
  end

end