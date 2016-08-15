class UseRight < ActiveRecord::Base
   has_many :metadata, :source=>:metadata, :class_name => 'Metadata'
   has_many :master_files
   validates :name, :uniqueness => true
end

# == Schema Information
#
# Table name: use_rights
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  metadata_count     :integer          default(0)
#  master_files_count :integer          default(0)
#
