require "#{Hydraulics.models_dir}/component"

class Component
  has_ancestry
  include Pidable
  include ExportIviewXML

  before_save :add_pid_before_save

#  after_update :fix_updated_counters

  # At this time there is no definitive field that can be used for "naming" purposes.
  # There are several candidates (title, content_desc, label) and until we make 
  # a definitive choice, we must rely upon an aritifical method to provide the string.
  def name
    if title
      return title
    elsif content_desc
      return content_desc
    elsif label
      return label
    else 
      return id # Everything has an id, so it is the LCD.
    end
  end
  
  # Returns the array of Component objects for which this Component is parent.
  # def   
  #   if id.blank?
  #     # object not saved yet
  #     return Array.new
  #   else
  #     return Component.where(:parent_component_id => self.id)
  #   end
  # end

  # Jet-powered super efficient query of the above.
  # Totally dependent on ancetry gem.
  def descendant_master_file_count
    c = 0
    # children = Component.where(:parent_id => self.id).select(:id) # Get the ids of all children of self.  Any other piece of info is extraneous.
    children = Component.where(:id => self.child_ids).select(:id).select(:ancestry)
    c += MasterFile.where(:component_id => self.id).size # add self.master_files
    until children.empty? do
      c += MasterFile.where(:component_id => children.map(&:id)).size
      children = Component.where(:id => children.map(&:child_ids)).select(:id).select(:ancestry)
    end

    return c
  end

  def descendant_master_files
    master_files = Array.new
    children = Component.where(:parent_component_id => self.id).select(:id) # Get the ids of all children of self.  Any other piece of info is extraneous.
    master_files << MasterFile.where(:component_id => self.id) # add self.master_files
    until children.empty? do
      master_files << MasterFile.where(:component_id => children.map(&:id))
      children = Component.where(:parent_component_id => children.map(&:id)).select(:id)
    end

    return master_files.flatten
  end
  
  # def parent
  #   if parent_component_id != 0
  #     return Component.where(:id => self.parent_component_id).first
  #   else
  #     return nil
  #   end
  # end
    
  # Within the scope of a current component's parent, return the sibling component
  # objects.  Used to create links and relationships between objects.
  def sorted_siblings
    return self.parent.children.sort_by {|c| c.id}
  end

  def next
    if parent
      @sorted_siblings = sorted_siblings
      if @sorted_siblings.find_index(self) < @sorted_siblings.length
        return @sorted_siblings[@sorted_siblings.find_index(self)+1]
      else
        return nil
      end
    else
      return nil
    end
  end

  def previous
    if parent
      @sorted_siblings = sorted_siblings
      if @sorted_siblings.find_index(self) > 0
        return @sorted_siblings[@sorted_siblings.find_index(self)-1]
      else
        return nil
      end
    else
      return nil
    end
  end

  alias :parent_component :parent
end
