module Bipbip::Helper

  def self.name_to_classname(name)
    name.split('-').map{|w| w.capitalize}.join
  end

  def self.name_to_filename(name)
    name.tr('-', '_')
  end
end
