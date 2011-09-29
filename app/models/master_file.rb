# == Schema Information
#
# Table name: master_files
#
#  id                        :integer         not null, primary key
#  availability_policy_id    :integer
#  component_id              :integer
#  ead_ref_id                :integer
#  tech_meta_type            :string(255)
#  unit_id                   :integer         default(0), not null
#  use_right_id              :integer
#  automation_messages_count :integer
#  description               :string(255)
#  filename                  :string(255)
#  filesize                  :integer
#  md5                       :string(255)
#  title                     :string(255)
#  dc                        :text
#  desc_metadata             :text
#  discoverability           :boolean         default(FALSE), not null
#  locked_desc_metadata      :boolean         default(FALSE), not null
#  pid                       :string(255)
#  rels_ext                  :text
#  rels_int                  :text
#  solr                      :text(16777215)
#  transcription_text        :text
#  date_ingested_into_dl     :datetime
#  created_at                :datetime
#  updated_at                :datetime
#

require "#{Hydraulics.models_dir}/master_file"

class MasterFile
end
