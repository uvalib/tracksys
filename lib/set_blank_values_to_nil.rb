module SetBlankValuesToNil

  # Several classes of objects (Bibl, Component, MasterFile) all need PIDs, pulled from Fedora
  # at the time they are saved.  Since th
  def set_blank_values_to_nil
    self.attributes.each {|key, value|
      self.update_attribute(key, nil) if value == ""
    }
  end
end

ActiveRecord::Base.send(:include, SetBlankValuesToNil)
