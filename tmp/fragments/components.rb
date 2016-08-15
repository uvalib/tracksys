class Component
  def prep_for_dl(unit, title, component_type_id, parent=nil)
    raise ArgumentError, "#{parent} is not a Component!" unless parent.is_a?(Component) | parent.nil?
    if parent
      self.parent_component_id = parent.id
    end
    self.title=title
    self.discoverability = true
    self.indexing_scenario_id = 1
    self.availability_policy_id =1
    self.component_type_id=component_type_id
    self.save!
    self.bind_to_unit(unit) unless unit.nil?
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

def component_type_map()
  # make a map from components types mapping:  name_as_symbol : type_id
  map = {}
  ComponentType.find_each { |x| map[x.name.to_sym] = x.id }
  map
end


def group_units(bibl)
  # group bibl.units by volume number extracted from unit.special_instructions and generate title for series level components.
  units = bibl.units.chunk { |u| u.special_instructions.split[1].to_i }
  units.map  do |group|
    years = group[1].map { |u| u.special_instructions.split[5]}
    tag = "Vol. #{group[0]}, #{years[0]}-#{years[-1]}"
    group[0] = tag
    group
  end
end

def link_siblings(parent)
  parent.children.each do |child|
    if ! child.next.nil?
      child.followed_by_id=child.next.id
      child.save!
    end
  end
end

def make_components(bibl)
  map = component_type_map
  top = Component.new
  top.prep_for_dl( nil, bibl.title, map[:guide])
  group_units(bibl).each do |vol|
    cvol = Component.new
    cvol.prep_for_dl( nil, vol[0], map[:series], top)
    vol[1].each do |num|
      c = Component.new
      title = num.special_instructions.to_s.gsub( /\r?\n/, ', ' )
      c.prep_for_dl( num, title, map[:item], cvol )
    end
    link_siblings(cvol)
  end
  link_siblings(top)
  bibl.component_ids= [top.id]
  bibl.save!
  top
end
