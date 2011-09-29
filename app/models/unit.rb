# == Schema Information
#
# Table name: units
#
#  id                             :integer         not null, primary key
#  archive_id                     :integer
#  availability_policy_id         :integer
#  bibl_id                        :integer
#  heard_about_resource_id        :integer
#  intended_use_id                :integer
#  order_id                       :integer         default(0), not null
#  use_right_id                   :integer
#  master_files_count             :integer         default(0)
#  automation_messages_count      :integer         default(0)
#  date_archived                  :datetime
#  date_materials_received        :datetime
#  date_materials_returned        :datetime
#  date_patron_deliverables_ready :datetime
#  deliverable_format             :string(255)
#  deliverable_resolution         :string(255)
#  deliverable_resolution_unit    :string(255)
#  patron_source_url              :string(255)
#  remove_watermark               :boolean         default(FALSE), not null
#  special_instructions           :text
#  staff_notes                    :text
#  unit_extent_estimated          :integer
#  unit_extent_actual             :integer
#  unit_status                    :string(255)
#  date_queued_for_ingest         :datetime
#  date_dl_deliverables_ready     :datetime
#  master_file_discoverability    :boolean         default(FALSE), not null
#  exclude_from_dl                :boolean         default(FALSE), not null
#  include_in_dl                  :boolean         default(FALSE), not null
#  created_at                     :datetime
#  updated_at                     :datetime
#

require "#{Hydraulics.models_dir}/unit"

class Unit
end
