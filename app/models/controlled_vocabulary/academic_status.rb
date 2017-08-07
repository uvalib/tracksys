class AcademicStatus < ApplicationRecord
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :customers
  has_many :orders, :through => :customers
  has_many :units, :through => :orders
  has_many :master_files, :through => :units
  
  validates :name, :presence => true

  def requests
     self.orders.where('order_status = ?', 'requested')
  end

end

# == Schema Information
#
# Table name: academic_statuses
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  customers_count :integer          default(0)
#
