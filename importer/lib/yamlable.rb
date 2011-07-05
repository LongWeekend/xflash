# ABOUT: Provides YAML vritual fields for a parent class (and any of its child classes!)
# NOTE : Generates YAML on save once per instatiation. Skips if called manually, can be called manually multiple times.
# USAGE: "Include Yamlable" in the Parent Class file, use "add_yaml_field :field_name" in the Child class to add a field
# REQS : YA2YAML gem for proper UTF8 handling
#
module Yamlable
  require 'ya2yaml'
  
  def self.included m
    m.extend ClassMethods
  end

  module ClassMethods
    def add_yaml_field *args
      write_inheritable_array(:yaml_fields, args)
      write_inheritable_attribute(:yaml_fields_generated, false)
      attr_accessor(*args)
      attr_accessible(*args)
      before_save :serialize_yaml_fields
    end
  end

  def yaml_fields_generated?
    return self.class.read_inheritable_attribute(:yaml_fields_generated)
  end

  def serialize_yaml_fields
    return if yaml_fields_generated?
    self.class.write_inheritable_attribute(:yaml_fields_generated, true)
    ### NO UTF8 SUPPORT
     # self.content = self.class.read_inheritable_attribute(:yaml_fields).inject({}) {|h, a| h[a] = send(a); h }.to_yaml
    ### UTF8 SUPPORT
    self.content = self.class.read_inheritable_attribute(:yaml_fields).inject({}) {|h, a| h[a] = send(a); h }.ya2yaml
  end

  def after_initialize(*args)
    # Check "content" has been loaded by the finder
    YAML::load(content).each { |k, v| send("#{k}=", v.to_s) } if self.attributes['content'].inspect != "nil" and content.length > 0
    # Also note, we access pre-Rubyized data via the attributes hash, so string "nil" is valid!
  end
end
