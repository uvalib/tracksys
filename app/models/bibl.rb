require "#{Hydraulics.models_dir}/bibl"

class Bibl

  VIRGO_FIELDS = ['title', 'creator_name', 'creator_name_type', 'call_number', 'catalog_key', 'barcode', 'copy', 'date_external_update', 'location', 'citation', 'year', 'year_type', 'location', 'copy', 'title_control']

  after_update :fix_updated_counters

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title

end
