class OcrHint < ActiveRecord::Base
   validates :name, presence: true, uniqueness: true
end
