class Component
  def prep_for_dl(unit, title, component_type_id, parent=nil)
    raise ArgumentError, "#{parent} is not a Component!" unless parent.is_a?(Component)
    if parent
      self.parent_component_id = parent.id
    end
    self.title=title
    self.discoverability = true
    self.indexing_scenario_id = 1
    self.availability_policy_id =1
    self.component_type_id=component_type_id
    self.save!
    self.bind_to_unit(unit)
    if self.master_files != []
      self.exemplar = self.master_files.first.filename  
    end 
    self.save! 
  end
  

  def bind_to_unit(u)
    raise ArgumentError, "#{u}.to_s is not a Unit" unless u.is_a?(Unit)
    warn "Unit #{u.id} has no master files!" unless u.master_files.count > 0
    raise RuntimeError, "Component #{self}.id already has master files!" unless self.master_files.count == 0
    self.master_files = u.master_files
    Component.reset_counters(self.id, :master_files)
    self.save!
  end

end
