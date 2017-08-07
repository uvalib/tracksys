class OcrHint < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
