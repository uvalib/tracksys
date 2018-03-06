class Tag < ApplicationRecord
   has_and_belongs_to_many :master_files, join_table: "master_file_tags"
   validates :tag, presence: true, uniqueness: true
end
