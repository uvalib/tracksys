require "#{Hydraulics.models_dir}/master_file"

class MasterFile
  after_update :fix_updated_counters

  # scope :index_scope, select(["`master_files`.id", :filename, :title, :description, "`master_files`.discoverability","`master_files`.date_dl_ingest", "`master_files`.date_archived", "`master_files`.pid"])
  
  def link_to_thumbnail
    #master_file = MasterFile.find(params[:id])
    
  # Within the scope of a current MasterFile's Unit, return the MasterFile object
  # that follows self.  Used to create links and relationships between objects.
  def next
    master_files_sorted = self.unit.master_files.sort_by {|mf| mf.filename}
      return master_files_sorted[master_files_sorted.find_index(self)+1]
    else
      return nil
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

    return "/metadata/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{thumbnail_name}"
  end

  # alias_attributes as CYA for legacy migration.  
  alias_attribute :name_num, :title
  alias_attribute :staff_notes, :description
end