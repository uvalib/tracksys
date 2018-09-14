class UseRight < ApplicationRecord
   has_many :metadata, :source=>:metadata, :class_name => 'Metadata'
   validates :name, :uniqueness => true
   has_many :master_files, :through=>:metadata

   def uses
      uses = []
      uses << "Educational Use Permitted" if educational_use
      uses << "Commercial Use Permitted" if commercial_use
      uses << "Modifications Permitted" if modifications
      uses << "None" if uses.blank?
      return uses.join(", ")
   end
end

# == Schema Information
#
# Table name: use_rights
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  metadata_count  :integer          default(0)
#  uri             :string(255)
#  statement       :text(65535)
#  commercial_use  :boolean          default(FALSE)
#  educational_use :boolean          default(FALSE)
#  modifications   :boolean          default(FALSE)
#
