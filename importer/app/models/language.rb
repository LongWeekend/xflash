class Language < ActiveRecord::Base

  has_many :scraps
  has_many :collections

  def self.Japanese
    self.find_by_name("Japanese")
  end

  def self.English
    self.find_by_name("English")
  end

  def self.Deutsch
    self.find_by_name("Deutsch")
  end

  def self.Francais
    self.find_by_name("Francais")
  end

end