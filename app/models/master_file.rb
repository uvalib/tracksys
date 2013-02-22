require "#{Hydraulics.models_dir}/master_file"

class MasterFile

  include Pidable

  after_update :fix_updated_counters

  # Within the scope of a current MasterFile's Unit, return the MasterFile object
  # that follows self.  Used to create links and relationships between objects.
  def next
    master_files_sorted = self.unit.master_files.sort_by {|mf| mf.filename}
    if master_files_sorted.find_index(self) < master_files_sorted.length
      return master_files_sorted[master_files_sorted.find_index(self)+1]
    else
      return nil
    end
  end


  # Within the scope of a current MasterFile's Unit, return the MasterFile object
  # that preceedes self.  Used to create links and relationships between objects.
  def previous
    master_files_sorted = self.unit.master_files.sort_by {|mf| mf.filename}
    if master_files_sorted.find_index(self) > 0
      return master_files_sorted[master_files_sorted.find_index(self)-1]
    else
      return nil
    end
  end

  def link_to_dl_thumbnail
    return "http://fedoraproxy.lib.virginia.edu/fedora/get/#{self.pid}/djatoka:jp2SDef/getRegion?scale=125"
  end

  def link_to_dl_page_turner
    return "#{VIRGO_URL}/#{self.bibl.pid}/view?&page=#{self.pid}"
  end

  def path_to_archved_version
    return "#{self.archive.directory}/" + "#{'%09d' % self.unit_id}/" + "#{self.filename}"
  end

  def link_to_static_thumbnail
    thumbnail_name = self.filename.gsub(/tif/, 'jpg')
    unit_dir = "%09d" % self.unit_id
	begin
    # Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
    # will eliminate other directories that are of non-Tracksys managed content.
    metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
    metadata_dir_contents.each {|dir|
      range = dir.split('-')
      if self.unit_id.to_i.between?(range.first.to_i, range.last.to_i)
        @range_dir = dir
      end
    }
	rescue
		@range_dir="fixme"
	end
    return "/metadata/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{thumbnail_name}"
  end

  # alias_attributes as CYA for legacy migration.  
  alias_attribute :name_num, :title
  alias_attribute :staff_notes, :description

  # Processor information
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  publishes_to :copy_archived_files_to_production

  def get_from_stornext(computing_id)
    message = ActiveSupport::JSON.encode( {:workflow_type => 'patron', :unit_id => self.unit_id, :master_file_filename => self.filename, :computing_id => computing_id })
    publish :copy_archived_files_to_production, message
  end
  
  def update_thumb_and_tech
    if self.image_tech_meta
      self.image_tech_meta.destroy
    end
    sleep(0.1)

    message = ActiveSupport::JSON.encode( { :master_file_id => self.id, :source => self.path_to_archved_version.gsub(/\/[0-9_]*.tif/, ''), :last => 0 })
    publish :create_image_technical_metadata_and_thumbnail, message
  end
end
