class ExternalSystem < ApplicationRecord
   validates :name, presence: true, uniqueness: true
   validates :public_url, presence: true
end
