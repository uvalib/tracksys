class JpegTwoThousand < MasterFile
  def say_hello
    return "Hi! I am a #{self.type}"
  end

  def mime_type
    "image/jp2"
  end
end
# == Schema Information
#
# Table name: master_files
#
#  id                        :integer(4)      not null, primary key
#  unit_id                   :integer(4)      default(0), not null
#  component_id              :integer(4)
#  tech_meta_type            :string(255)
#  filename                  :string(255)
#  filesize                  :integer(4)
#  title                     :string(255)
#  date_archived             :datetime
#  description               :string(255)
#  pid                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  transcription_text        :text
#  desc_metadata             :text
#  rels_ext                  :text
#  solr                      :text(2147483647
#  dc                        :text
#  rels_int                  :text
#  discoverability           :boolean(1)      default(FALSE)
#  md5                       :string(255)
#  indexing_scenario_id      :integer(4)
#  availability_policy_id    :integer(4)
#  automation_messages_count :integer(4)      default(0)
#  use_right_id              :integer(4)
#  date_dl_ingest            :datetime
#  date_dl_update            :datetime
#  dpla                      :boolean(1)      default(FALSE)
#  type                      :string(255)
#  creator_death_date        :string(255)
#  creation_date             :string(255)
#  primary_author            :string(255)
#

