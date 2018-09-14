# == Schema Information
#
# Table name: order_items
#
#  id              :bigint(8)        not null, primary key
#  order_id        :bigint(8)
#  intended_use_id :bigint(8)
#  title           :text(65535)
#  pages           :text(65535)
#  call_number     :string(255)
#  author          :string(255)
#  year            :string(255)
#  location        :string(255)
#  source_url      :string(255)
#  description     :text(65535)
#  converted       :boolean          default(FALSE)
#

class OrderItem < ApplicationRecord
   belongs_to :order
   belongs_to :intended_use
end
