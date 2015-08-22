require "#{Hydraulics.models_dir}/agency"

class Agency
  has_ancestry
  before_save :cache_ancestry

  scope :no_parent, where(:ancestry => nil)

  def cache_ancestry
    cached_ancestry = String.new
    if path.empty?
      cached_ancestry = self.name
    else
      cached_ancestry = path.map(&:name).join('/')
    end
    self.names_depth_cache = cached_ancestry
  end

  def total_order_count
    # start with self.orders.size and then add all descendant agency's orders.size
    count = self.orders.size
    self.descendant_ids.each {|id| count += Agency.find(id).orders.size}
    return count
  end

  # total_class_count accepts a Sting of a class related to Agency.  Thsi method intended to 
  # determine counts for both an Agency object and its descendents (see ancestry gem for more)
  # information on the 'descendent_ids' method.
  #
  # The incoming string is pluralized to be utilized with an Agency object's has_many relationships.
  # The pluralized string is sent to the Agency instance, descendant counts are summed and the value returned.
  def total_class_count(name_of_class)
    begin
      # pluralize the incoming string
      method = name_of_class.underscore.pluralize
      count = self.send("#{method}").size
      self.descendant_ids.each {|id| count += Agency.find(id).send("#{method}").size}
      return count
    rescue NoMethodError
    end
  end
end
# == Schema Information
#
# Table name: agencies
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  description       :string(255)
#  is_billable       :boolean(1)      default(FALSE), not null
#  last_name         :string(255)
#  first_name        :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  ancestry          :string(255)
#  names_depth_cache :string(255)
#  orders_count      :integer(4)      default(0)
#

