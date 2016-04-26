class Department < ActiveRecord::Base
   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   has_many :customers
   has_many :requests, ->{ where('orders.order_status = ?', 'requested') }, :through => :customers
   has_many :orders, :through => :customers
   has_many :units, :through => :orders
   has_many :master_files, :through => :units

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

end
# == Schema Information
#
# Table name: departments
#
#  id              :integer(4)      not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  customers_count :integer(4)      default(0)
#
