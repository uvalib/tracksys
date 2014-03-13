require "#{Hydraulics.models_dir}/component"

class Component
  has_ancestry
  include Pidable
  include ExportIviewXML

  before_save :copy_parent_reference
  before_save :cache_ancestry

  # Intended as a before_save callback, will save to a Component object:
  # 1.  A pids_depth cache so a hierarchy of pids for each component is available
  # 2.  An ead_id_atts depth cache for legacy ids on each Component derived from an EAD guide.
  def cache_ancestry
    self.pids_depth_cache = path.map(&:pid).join('/')
    self.ead_id_atts_depth_cache = path.map(&:ead_id_att).join('/')
  end

  # Using ancestry gem, the "parent" information for a Component lives in the ancestry attribute.
  # In migrating information during the Tracksys3 rollout, we need a way to translate the legacy attribute
  # parent_componnet_id to the ancestry parent method.  The following method provides that facility.
  def copy_parent_reference
    if self.parent_component_id > 0 && self.parent == nil
      self.parent = Component.find(self.parent_component_id)
    end 
  end

  # overriding method because data lives in several places
  def level
    if @level
      @level
    elsif self.component_type
      self.component_type.name
    else
      nil
    end
  end

  # At this time there is no definitive field that can be used for "naming" purposes.
  # There are several candidates (title, content_desc, label) and until we make 
  # a definitive choice, we must rely upon an aritifical method to provide the string.
  #
  # Given the inconsistencies of input data, all newlines and sequences of two or more spaces
  # will be substituted.
  def name
    value = String.new
    if not title.blank?
      value = title
    elsif not content_desc.blank?
      value = content_desc
    elsif not label.blank?
      value = label
    elsif not date.blank?
      value = date
    else 
      value = id # Everything has an id, so it is the LCD.
    end
    return value.to_s.strip.gsub(/\n/, ' ').gsub(/  +/, ' ')
  end

  # For the purposes of digitization, student workers need access to as much of the metadata available
  # in the Component class as possible.  The 'name' method does not provide enough information in some 
  # circumstances.  In the circumstances where a Component has both a title and content_desc, pull both.
  # Otherwise, use the default name method.
  def iview_description
    value = String.new
    if title && content_desc
      value = "#{title} - #{content_desc}"
    else
      value = name
    end
    return value.strip.gsub(/\n/, ' ').gsub(/  +/, ' ')
  end
  
  # Returns a count of all MasterFiles belonging to both this component (i.e. self) and its children.
  # The count is used for component views.
  # 
  # Dependent on ancestry gem.
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

  # Returns an array of all MasterFiles belonging to this component (i.e. self) and its children.
  #
  # Depdendent on ancestry gem
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
    
  # Within the scope of a current component's parent, return the sibling component
  # objects.  Used to create links and relationships between objects.
  def sorted_siblings
    return self.parent.children.sort_by {|c| c.id}
  end

  def new_next
    return Component.find(self.followed_by_id) unless self.followed_by_id.nil?
  end

  def new_previous
    return Component.where(:followed_by_id => self.id).first
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

  def in_dl?
    return self.date_dl_ingest?
  end

  # temporary method: use until db migration adds relationship
  def index_destination
    identifier = self.index_destination_id
    if identifier
      return IndexDestination.find(identifier)
    else
      return nil
    end
  end

  # hashes for serializing hierarchies
  # TO DO: order by followed_by_id
  def master_files_pids
    self.master_files.map(&:pid)
  end
  # builds a hash for JSON publication
  # values can be either arrays of MasterFiles
  # or a hash of child components
  def descendants_hash
    hash = {};  values = []
    if self.children != []
      self.children.each do |child|
        values << child.descendants_hash
      end
    elsif self.master_files.count > 0
      values << self.master_files_pids
    end
    hash[self.pid] = values
    hash
  end

  alias :parent_component :parent
end
