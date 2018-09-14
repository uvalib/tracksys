# == Schema Information
#
# Table name: tags
#
#  id  :bigint(8)        not null, primary key
#  tag :string(255)
#

class Tag < ApplicationRecord
   has_and_belongs_to_many :master_files, join_table: "master_file_tags"
   validates :tag, presence: true, uniqueness: true
end
