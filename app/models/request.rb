require "#{Hydraulics.models_dir}/request"

class Request
  belongs_to :customer, :inverse_of => :requests

  accepts_nested_attributes_for :units
  accepts_nested_attributes_for :customer

  validates :units, :presence => {
    :message => 'are required.  Please add at least one item to your request.'
  }

  validates_presence_of :customer
end
