require "#{Hydraulics.models_dir}/bibl"

class Bibl

  include Pidable

  after_update :fix_updated_counters

  VIRGO_FIELDS = ['title', 'creator_name', 'creator_name_type', 'call_number', 'catalog_key', 'barcode', 'date_external_update', 'location', 'citation', 'year', 'year_type', 'location', 'copy', 'title_control', 'date_external_update', 'cataloging_source']
  # Create and manage a Hash that contains the SIRSI location codes and their human readable values for citation purposes
  LOCATION_HASH = {
    "ALD-STKS" => "Alderman Library, University of Virginia, Charlottesville, VA.",
    "ASTRO-STKS" => "Astronomy Library, University of Virginia, Charlottesville, VA.",
    "BARR-STKS" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "CABELJR" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "DEC-IND-RM" => "Albert H. Small Declaration of Independence Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "FA-FOLIO" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
    "FA-OVERSIZE" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
    "FA-STKS" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
    "GEOSTAT" => "Alderman Library, University of Virginia, Charlottesville, VA.",
    "HS-CABELJR" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "HS-RAREOVS" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "HS-RARESHL" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "HS-RAREVLT" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "IVY-BOOK" => "Ivy Annex, University of Virginia, Charlottesville, VA.",
    "IVY-STKS" => "Ivy Annex, University of Virginia, Charlottesville, VA.",
    "IVYANNEX" => "Ivy Annex, University of Virginia, Charlottesville, VA." ,
    "LAW-IVY" => "Law Library, University of Virginia, Charlottesville, VA.",
    "MCGR-VLTFF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "RAREOVS" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "RARESHL" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "RAREVLT" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
    "SC-ARCHV" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-ARCHV-X" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-F" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-FF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-M" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-RM" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-ST" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-X" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-XF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARR-XZ" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-BARRXFF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-GARN-F" => "Garnett Family Library, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-GARN-RM" => "Garnett Family Library, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-IVY" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-F" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-FF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-RM" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-ST" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-X" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-XF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGR-XZ" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-MCGRXFF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-REF" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-REF-F" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTT" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTT-F" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTT-M" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTT-X" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTTFF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTTXF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-SCOTTXZ" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-D" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-EF" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-F" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-FF" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-M" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-X" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-XF" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKS-XZ" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-STKSXFF" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUM" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUM-F" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUM-M" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUM-X" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUMFF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUMXF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SC-TATUMXZ" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
    "SPEC-COLL" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "STACKS" => "Special Collections, University of Virginia, Charlottesville, VA.",
    "Reading Room" => "Special Collection, University of Virginia, Charlottesville, VA."
  }
  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title

  #------------------------------------------------------------------
  # scopes - maybe this belongs in hydraulics engine along with others (sdm7g)
  #------------------------------------------------------------------
  scope :dpla, where(:dpla => true)


  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  belongs_to :index_destination, :counter_cache => true


  # Although many Bibl records have citations provided through the MARC record, many do not
  # (especially those which lack a MARC record or are otherwise not cataloged in VIRGO).  As
  # a result, this method will impose some general order on the act of creating citations where
  # needed and rely upon the canonical citation when present.
  def get_citation
    if self.citation
      return self.citation
    else
      citation = String.new
      citation << "#{self.cleanedup_title}.  " if self.title
      citation << "#{self.call_number}.  " if self.call_number
      if self.location
        begin
          citation << "#{LOCATION_HASH.fetch(self.location)}"
        rescue
          citation << "Special Collections, University of Virginia, Charlottesville, VA"
        end
      else
        citation << "Special Collections, University of Virginia, Charlottesville, VA"
      end
      return citation
    end
  end

  # For the purposes of citations, run the title through some manipulation.
  def cleanedup_title
    # Remove trailing periods.
    if self.title.match(/\.$/)
      return self.title.chop
    else
      return self.title
    end
  end

  def physical_virgo_url
    return "#{VIRGO_URL}/#{self.catalog_key}"
  end

  def dl_virgo_url
    return "#{VIRGO_URL}/#{self.pid}"
  end

  def fedora_url
    return "#{FEDORA_REST_URL}/objects/#{self.pid}"
  end

  def solr_url(url=STAGING_SOLR_URL)
    return "#{url}/select?q=id:\"#{self.pid}\""
  end
end
# == Schema Information
#
# Table name: bibls
#
#  id                        :integer(4)      not null, primary key
#  is_approved               :boolean(1)      default(FALSE), not null
#  is_personal_item          :boolean(1)      default(FALSE), not null
#  resource_type             :string(255)
#  genre                     :string(255)
#  is_manuscript             :boolean(1)      default(FALSE), not null
#  is_collection             :boolean(1)      default(FALSE), not null
#  title                     :text
#  description               :string(255)
#  series_title              :string(255)
#  creator_name              :string(255)
#  creator_name_type         :string(255)
#  catalog_key               :string(255)
#  title_control             :string(255)
#  barcode                   :string(255)
#  call_number               :string(255)
#  copy                      :integer(4)
#  volume                    :string(255)
#  location                  :string(255)
#  year                      :string(255)
#  year_type                 :string(255)
#  date_external_update      :datetime
#  pid                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  is_in_catalog             :boolean(1)      default(FALSE), not null
#  issue                     :string(255)
#  citation                  :text
#  exemplar                  :string(255)
#  parent_bibl_id            :integer(4)      default(0), not null
#  desc_metadata             :text
#  rels_ext                  :text
#  solr                      :text(2147483647
#  dc                        :text
#  rels_int                  :text
#  discoverability           :boolean(1)      default(TRUE)
#  indexing_scenario_id      :integer(4)
#  date_dl_ingest            :datetime
#  date_dl_update            :datetime
#  automation_messages_count :integer(4)      default(0)
#  units_count               :integer(4)      default(0)
#  availability_policy_id    :integer(4)
#  use_right_id              :integer(4)
#  dpla                      :boolean(1)      default(FALSE)
#  cataloging_source         :string(255)
#  collection_facet          :string(255)
#  index_destination_id      :integer(4)
#
