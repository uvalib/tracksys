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

 def link_to_thumbnail
    #master_file = MasterFile.find(params[:id])
    thumbnail_name = self.filename.gsub(/tif/, 'jpg')
    unit_dir = "%09d" % self.unit_id
  
    # Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
    # will eliminate other directories that are of non-Tracksys managed content.
    metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
    metadata_dir_contents.each {|dir|
      range = dir.split('-')
      if self.unit_id.to_i.between?(range.first.to_i, range.last.to_i)
        @range_dir = dir
      end
    }
  
    return "#{TRACKSYS_URL}metadata/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{thumbnail_name}"
  end

end
