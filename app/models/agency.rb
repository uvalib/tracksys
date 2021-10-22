class Agency < ApplicationRecord
  has_many :orders
  has_many :units, -> { distinct }, :through => :orders
  has_many :master_files, -> { distinct }, :through => :units
  has_one :primary_address, ->{where(address_type: "primary")}, :class_name => 'Address', :as => :addressable, :dependent => :destroy
  has_one :billable_address, ->{where(address_type: "billable_address")}, :class_name => 'Address', :as => :addressable, :dependent => :destroy
  has_many :customers, -> { distinct }, :through => :orders
  has_many :metadata, -> { distinct }, :through => :units

  validates :name, :presence => true, :uniqueness => true

  def requests
     self.orders.where('order_status = ?', 'requested')
  end
end

# == Schema Information
#
# Table name: agencies
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  ancestry          :string(255)
#  names_depth_cache :string(255)
#  orders_count      :integer          default(0)
#
