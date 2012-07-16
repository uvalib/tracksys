require "#{Hydraulics.models_dir}/bibl"

class Bibl

  include Pidable

  VIRGO_FIELDS = ['title', 'creator_name', 'creator_name_type', 'call_number', 'catalog_key', 'barcode', 'copy', 'date_external_update', 'location', 'citation', 'year', 'year_type', 'location', 'copy', 'title_control', 'date_external_update']

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title

  def physical_virgo_url
    return "#{VIRGO_URL}/#{self.catalog_key}"
  end

  def dl_virgo_url
    return "#{VIRGO_URL}/#{self.pid}"
  end

  def fedora_url
    return "#{FEDORA_REST_URL}/objects/#{self.pid}"
  end

  # Returns an array of MasterFile objects (:id and :filename only) for the purposes 
  def exemplar_master_file_filenames
    return MasterFile.joins(:bibl).joins(:unit).select(:filename).select('`master_files`.id').where('`units`.include_in_dl = true').where("`bibls`.id = #{self.id}").map(&:filename)
  end
end
