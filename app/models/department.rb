class Department < ApplicationRecord
   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   has_many :customers
   has_many :orders, -> { distinct }, :through => :customers
   has_many :units, -> { distinct }, :through => :orders
   has_many :master_files, -> { distinct }, :through => :units

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   default_scope {order('name') }

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def requests
      self.orders.where('order_status = ?', 'requested')
   end

end

# == Schema Information
#
# Table name: departments
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  customers_count :integer          default(0)
#
