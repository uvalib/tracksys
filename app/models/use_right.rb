class UseRight < ActiveRecord::Base
  has_many :bibls
  has_many :xml_metadata, class_name: "XmlMetadata"
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
#  bibls_count        :integer          default(0)
#  master_files_count :integer          default(0)
#
