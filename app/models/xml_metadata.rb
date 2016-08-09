class XmlMetadata < ActiveRecord::Base
   SCHEMAS = %w[mods vra]
   has_many :units, as: :metadata

   has_many :agencies, :through => :orders
   has_many :customers, ->{ uniq }, :through => :orders
   has_many :master_files, :through => :units
   has_many :orders, ->{ uniq }, :through => :units

   belongs_to :availability_policy, :counter_cache => true
   belongs_to :indexing_scenario, :counter_cache => true
   belongs_to :use_right, :counter_cache => true

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :approved, ->{ where(:is_approved => true) }
   scope :in_digital_library,  ->{ where("xml_metadata.date_dl_ingest is not null").order("xml_metadata.date_dl_ingest DESC") }
   scope :not_in_digital_library,  ->{ where("xml_metadata.date_dl_ingest is null") }
   scope :not_approved,  ->{ where(:is_approved => false) }
   scope :has_exemplars,  ->{ where("exemplar is NOT NULL") }
   scope :need_exemplars,  ->{ where("exemplar is NULL") }

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
      self.discoverability = 1 if self.discoverability.nil?

      # default right statement to not Evaluated
      if self.use_right.blank?
         cne = UseRight.find_by(name: "Copyright Not Evaluated")
         self.use_right = cne
      end

      if self.is_in_catalog.nil?
         if self.is_personal_item?
            self.is_in_catalog = false
         else
            # held by Library; default to assuming it's in Library catalog
            self.is_in_catalog = true
         end
      end
   end
   after_create do
      update_attribute(:pid, "tsx:#{self.id}") if self.pid.blank?
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def in_dl?
      return self.date_dl_ingest?
   end

   def exemplar_files
     if self.new_record?
       return Array.new
     else
       #return MasterFile.joins(:xml_metadata).joins(:unit).where('`units`.include_in_dl = true').where("`metadata_id`.id = #{self.id}")
       #return MasterFile.joins(:bibl).joins(:unit).where('`units`.include_in_dl = true').where("`bibls`.id = #{self.id}")
       return Array.new
     end
   end

   def dl_virgo_url
      return "#{VIRGO_URL}/#{self.pid}"
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

   def agency_links
      return "" if self.agencies.empty?
      out = ""
      self.agencies.uniq.sort_by(&:name).each do |agency|
        out << "<div><a href='/admin/agencies/#{agency.id}'>#{agency.name}</a></div>"
      end
      return out
   end
end
