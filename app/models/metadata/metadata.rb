class Metadata < ActiveRecord::Base

   TYPES = ['Sirsi', "Xml", "ArchivesSpace"]

   GENRES = [
      'abstract or summary', 'art original', 'art reproduction', 'article', 'atlas',
      'autobiography', 'bibliography', 'biography', 'book', 'catalog', 'chart', 'comic strip',
      'conference publication', 'database', 'dictionary', 'diorama', 'directory', 'discography',
      'drama', 'encyclopedia', 'essay', 'festschrift', 'fiction', 'filmography', 'filmstrip',
      'finding aid', 'flash card', 'folktale', 'font', 'game', 'government publication',
      'graphic', 'globe', 'handbook', 'history', 'hymnal', 'humor, satire', 'index',
      'instruction', 'interview', 'issue', 'journal', 'kit', 'language instruction',
      'law report or digest', 'legal article', 'legal case and case notes', 'legislation',
      'letter', 'loose-leaf', 'map', 'memoir', 'microscope slide', 'model', 'motion picture',
      'multivolume monograph', 'newspaper', 'novel', 'numeric data', 'offprint',
      'online system or service', 'patent', 'periodical', 'picture', 'poetry', 'programmed text',
      'realia', 'rehearsal', 'remote sensing image', 'reporting', 'review', 'script', 'series',
      'short story', 'slide', 'sound', 'speech', 'statistics', 'survey of literature', 'technical drawing',
      'technical report', 'thesis', 'toy', 'transparency', 'treaty', 'videorecording', 'web site']

   RESOURCE_TYPES = [
      'text', 'cartographic', 'notated music', 'sound recording', 'sound recording-musical', 'sound recording-nonmusical',
      'still image', 'moving image', 'three dimensional object', 'software, multimedia', 'mixed material']

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :availability_policy, :counter_cache => true
   belongs_to :indexing_scenario, :counter_cache => true
   belongs_to :use_right, :counter_cache => true

   has_many :agencies, :through => :orders
   has_many :job_statuses, :as => :originator, :dependent => :destroy
   has_many :customers, ->{ uniq }, :through => :orders
   has_many :orders, ->{ uniq }, :through => :units
   has_many :units
   has_many :master_files

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :approved, ->{ where(:is_approved => true) }
   scope :in_digital_library,  ->{ where("metadata.date_dl_ingest is not null").order("metadata.date_dl_ingest DESC") }
   scope :not_in_digital_library,  ->{ where("metadata.date_dl_ingest is null") }
   scope :not_approved,  ->{ where(:is_approved => false) }
   scope :has_exemplars,  ->{ where("exemplar is NOT NULL") }
   scope :need_exemplars,  ->{ where("exemplar is NULL") }
   scope :dpla, ->{where(:dpla => true) }

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :title, :presence => {:message => "Title is required" }

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      self.is_approved = false if self.is_approved.nil?
      self.is_collection = false if self.is_collection.nil?
      self.is_manuscript = false if self.is_manuscript.nil?
      self.is_personal_item = false if self.is_personal_item.nil?
      self.discoverability = true if self.discoverability.nil?
      self.collection_facet = nil if self.collection_facet.downcase == "none"

      # default right statement to not Evaluated
      if self.use_right.blank?
         cne = UseRight.find_by(name: "Copyright Not Evaluated")
         self.use_right = cne
      end
   end

   before_destroy :destroyable?
   def destroyable?
      if self.units.size > 0
         errors[:base] << "cannot delete metadata that is associated with units"
         return false
      end
      return true
   end

   after_create do
      update_attribute(:pid, "tsb:#{self.id}") if self.pid.blank?
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def url_fragment
      return "xml_metadata" if self.type == "XmlMetadata"
      return "sirsi_metadata"
   end

   # Returns an array of MasterFile objects that are in units to be included in the DL
   def dl_master_files
      if self.new_record?
         return Array.new
      else
         return MasterFile.joins(:metadata).joins(:unit).where('units.include_in_dl = true').where("metadata.id = #{self.id}")
      end
   end

   def in_catalog?
      return self.catalog_key?
   end

   def in_dl?
      return self.date_dl_ingest?
   end

   def personal_item?
      return self.is_personal_item
   end

   def physical_virgo_url
      return "#{VIRGO_URL}/#{self.catalog_key}"
   end

   def dl_virgo_url
      return "#{VIRGO_URL}/#{self.pid}"
   end

   def agency_links
      return "" if self.agencies.empty?
      out = ""
      self.agencies.uniq.sort_by(&:name).each do |agency|
         out << "<div><a href='/admin/agencies/#{agency.id}'>#{agency.name}</a></div>"
      end
      return out
   end

   def flag_for_publication
      if self.date_dl_ingest.blank?
        if self.date_dl_update.blank?
            self.update(date_dl_ingest: Time.now)
        else
            self.update(date_dl_ingest: self.date_dl_update, date_dl_update: Time.now)
        end
      else
        self.update(date_dl_update: Time.now)
      end
   end

   def publish_to_test
      if self.indexing_scenario.blank?
         if self.type == "XmlMetadata"
            self.update(indexing_scenario_id: 2)
         else
            self.update(indexing_scenario_id: 1)
         end
      end

      xml = Hydra.solr( self )
      RestClient.post "#{Settings.test_solr_url}/virgo/update?commit=true", xml, {:content_type => 'application/xml'}
   end

   # Returns the array of child metadata records
   #
   def children
      begin
         return Metadata.where(parent_bibl_id: id)
      rescue ActiveRecord::RecordNotFound
         return Array.new
      end
   end

   def typed_children( )
      out = {}
      begin
         out[:sirsi] =  SirsiMetadata.where(parent_bibl_id: id, type: "SirsiMetadata")
         out[:xml] =  SirsiMetadata.where(parent_bibl_id: id, type: "XmlMetadata")
         return out
      rescue ActiveRecord::RecordNotFound
         return {}
      end
   end

   def parent
      begin
         return Metadata.find(parent_bibl_id)
      rescue ActiveRecord::RecordNotFound
         return nil
      end
   end
end

# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_approved            :boolean          default(FALSE), not null
#  is_personal_item       :boolean          default(FALSE), not null
#  resource_type          :string(255)
#  genre                  :string(255)
#  is_manuscript          :boolean          default(FALSE), not null
#  is_collection          :boolean          default(FALSE), not null
#  title                  :text(65535)
#  creator_name           :string(255)
#  catalog_key            :string(255)
#  barcode                :string(255)
#  call_number            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  exemplar               :string(255)
#  parent_bibl_id         :integer          default(0), not null
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(TRUE)
#  indexing_scenario_id   :integer
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  units_count            :integer          default(0)
#  availability_policy_id :integer
#  use_right_id           :integer
#  dpla                   :boolean          default(FALSE)
#  collection_facet       :string(255)
#  type                   :string(255)      default("SirsiMetadata")
#  external_attributes    :text(65535)
#
