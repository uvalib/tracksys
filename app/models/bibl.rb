class Bibl < ActiveRecord::Base
  include Pidable

  CREATOR_NAME_TYPES = %w[corporate personal]
  YEAR_TYPES = %w[copyright creation publication]
  GENRES = ['abstract or summary', 'art original', 'art reproduction', 'article', 'atlas', 'autobiography', 'bibliography', 'biography', 'book', 'catalog', 'chart', 'comic strip', 'conference publication', 'database', 'dictionary', 'diorama', 'directory', 'discography', 'drama', 'encyclopedia', 'essay', 'festschrift', 'fiction', 'filmography', 'filmstrip', 'finding aid', 'flash card', 'folktale', 'font', 'game', 'government publication', 'graphic', 'globe', 'handbook', 'history', 'hymnal', 'humor, satire', 'index', 'instruction', 'interview', 'issue', 'journal', 'kit', 'language instruction', 'law report or digest', 'legal article', 'legal case and case notes', 'legislation', 'letter', 'loose-leaf', 'map', 'memoir', 'microscope slide', 'model', 'motion picture', 'multivolume monograph', 'newspaper', 'novel', 'numeric data', 'offprint', 'online system or service', 'patent', 'periodical', 'picture', 'poetry', 'programmed text', 'realia', 'rehearsal', 'remote sensing image', 'reporting', 'review', 'script', 'series', 'short story', 'slide', 'sound', 'speech', 'statistics', 'survey of literature', 'technical drawing', 'technical report', 'thesis', 'toy', 'transparency', 'treaty', 'videorecording', 'web site']
  RESOURCE_TYPES = ['text', 'cartographic', 'notated music', 'sound recording', 'sound recording-musical', 'sound recording-nonmusical', 'still image', 'moving image', 'three dimensional object', 'software, multimedia', 'mixed material']
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
  # relationships
  #------------------------------------------------------------------
  belongs_to :availability_policy, :counter_cache => true
  belongs_to :indexing_scenario, :counter_cache => true
  belongs_to :use_right, :counter_cache => true

  has_and_belongs_to_many :legacy_identifiers
  has_and_belongs_to_many :components

  has_many :agencies, :through => :orders
  has_many :job_statuses, :as => :originator, :dependent => :destroy
  has_many :customers, :through => :orders, :uniq => true
  has_many :master_files, :through => :units
  has_many :orders, :through => :units, :uniq => true
  has_many :units
  belongs_to :index_destination, :counter_cache => true

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------
  scope :approved, where(:is_approved => true)
  scope :in_digital_library, where("bibls.date_dl_ingest is not null").order("bibls.date_dl_ingest DESC")
  scope :not_in_digital_library, where("bibls.date_dl_ingest is null")
  scope :not_approved, where(:is_approved => false)
  scope :has_exemplars, where("exemplar is NOT NULL")
  scope :need_exemplars, where("exemplar is NULL")
  scope :uniq, select( 'DISTINCT id' )
  scope :dpla, where(:dpla => true)

  #------------------------------------------------------------------
  # delegation
  #------------------------------------------------------------------
  # delegate :id,
  #   :to => :unit, :allow_nil => true, :prefix => true

  # delegate :id,
  #   :to => :order, :allow_nil => true, :prefix => true

  delegate :id, :email,
    :to => :customers, :allow_nil => true, :prefix => true

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :availability_policy, :presence => {
    :if => 'self.availability_policy_id',
    :message => "association with this AvailabilityPolicy is no longer valid because it no longer exists."
  }
  validates :indexing_scenario, :presence => {
    :if => 'self.indexing_scenario_id',
    :message => "association with this IndexingScenario is no longer valid because it no longer exists."
  }

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  before_save do
    # boolean fields cannot be NULL at database level
    self.is_approved = 0 if self.is_approved.nil?
    self.is_collection = 0 if self.is_collection.nil?
    self.is_in_catalog = 0 if self.is_in_catalog.nil?
    self.is_manuscript = 0 if self.is_manuscript.nil?
    self.is_personal_item = 0 if self.is_personal_item.nil?
    self.discoverability = 1 if self.discoverability.nil? # For Bibl objects, the default value is 1 (i.e. is discoverable)

    # get pid
    if self.pid.blank?
      begin
        self.pid = AssignPids.get_pid
      rescue Exception => e
        #ErrorMailer.deliver_notify_pid_failure(e) unless @skip_pid_notification
      end
    end

    # Moved from after_initialize in order to make compliant with 2.3.8
    if self.is_in_catalog.nil?
      # set default value
      if self.is_personal_item?
        self.is_in_catalog = false
      else
        # held by Library; default to assuming it's in Library catalog
        self.is_in_catalog = true
      end
    end
  end
  after_update :fix_updated_counters
  before_destroy :destroyable?

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  # Returns an array of Bibl objects that are the parent, grandparent, etc... of the
  # Bibl object upon which this method is invoked.
  def ancestors
    parent_bibls = Array.new
    if parent_bibl_id != 0
      begin
        bibl = parent_bibl
        parent_bibls << bibl
        parent_bibls << bibl.ancestors unless bibl.ancestors.nil?
        return parent_bibls.flatten
      rescue ActiveRecord::RecordNotFound
        return parent_bibls.flatten
      end
    end
  end

  # Returns the array of Bibl objects for which this Bibl is parent.
  def child_bibls
    begin
      return Bibl.find(:all, :conditions => "parent_bibl_id = #{id}")
    rescue ActiveRecord::RecordNotFound
      return Array.new
    end
  end

  def components?
    if components.any?
      return true
    else
      return false
    end
  end

  # Returns an array of MasterFile objects (:id and :filename only) for the purposes
  def dl_master_files
    if self.new_record?
      return Array.new
    else
      return MasterFile.joins(:bibl).joins(:unit).where('`units`.include_in_dl = true').where("`bibls`.id = #{self.id}")
    end
  end

  # Returns a boolean value indicating whether it is safe to delete this record
  # from the database. Returns +false+ if this record has dependent records in
  # other tables, namely associated Unit, Component, or EadRef records.
  #
  # This method is public but is also called as a +before_destroy+ callback.
  def destroyable?
    if components? || units?
      return false
    else
      return true
    end
  end

  def in_catalog?
    return self.catalog_key?
  end

  def in_dl?
    return self.date_dl_ingest?
  end

  def master_file_filenames
    return master_files.map(&:filename)
  end

  def parent_bibl
    begin
      return Bibl.find(parent_bibl_id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def personal_item?
    return self.is_personal_item
  end

  def units?
    if units.any?
      return true
    else
      return false
    end
  end

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  alias :parent :parent_bibl
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title


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
#  units_count               :integer(4)      default(0)
#  availability_policy_id    :integer(4)
#  use_right_id              :integer(4)
#  dpla                      :boolean(1)      default(FALSE)
#  cataloging_source         :string(255)
#  collection_facet          :string(255)
#  index_destination_id      :integer(4)
#
