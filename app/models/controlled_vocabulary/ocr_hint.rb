# == Schema Information
#
# Table name: ocr_hints
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  ocr_candidate :boolean          default(TRUE)
#

class OcrHint < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
