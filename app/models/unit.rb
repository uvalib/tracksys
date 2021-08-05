class Unit < ApplicationRecord

   UNIT_STATUSES = ["approved", "canceled", "condition", "copyright", "unapproved", "finalizing", "error", "done"]

   # The request form requires having data stored temporarily to the unit model and
   # then concatenated into special instructions.  Those fields are:
   attr_accessor :request_call_number, :request_copy_number, :request_volume_number,
      :request_issue_number, :request_location, :request_title, :request_author, :request_year,
      :request_description, :request_pages_to_digitize

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :metadata, :counter_cache => true, optional: true
   belongs_to :intended_use, :counter_cache => true
   belongs_to :order, :counter_cache => true, :inverse_of => :units

   has_many :master_files
   has_many :components, :through => :master_files
   has_many :job_statuses, :as => :originator, :dependent => :destroy
   has_many :attachments, :dependent=>:destroy

   has_one :agency, :through => :order
   has_one :customer, :through => :order
   has_one :department, :through => :order
   has_one :project
   has_many :notes, :through => :project

   delegate :title, :to=>:metadata, :allow_nil => true, :prefix => true
   delegate :date_due, :to => :order, :allow_nil => true, :prefix => true
   delegate :deliverable_format, :deliverable_resolution,
      :to => :intended_use, :allow_nil => true, :prefix => true

   delegate :call_number, :to=>:metadata, :allow_nil => true, :prefix => true

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :in_repo, ->{where("date_dl_deliverables_ready IS NOT NULL").order("date_dl_deliverables_ready DESC") }
   scope :ready_for_repo, ->{
      joins(:metadata).where("metadata.availability_policy_id is not null")
      .where(:include_in_dl => true).where(:date_dl_deliverables_ready => nil)
      .where("date_archived is not null") }
   scope :awaiting_copyright_approval, ->{where(:unit_status => 'copyright') }
   scope :awaiting_condition_approval, ->{where(:unit_status => 'condition') }
   scope :approved, ->{where(:unit_status => 'approved') }
   scope :unapproved, ->{where(:unit_status => 'unapproved') }
   scope :canceled, ->{where(:unit_status => 'canceled') }
   scope :error, ->{where(:unit_status => 'error') }

   def self.uncompleted_units_of_partially_completed_orders
      Unit.where(unit_status: 'approved', date_patron_deliverables_ready: nil, date_archived: nil)
         .where('intended_use_id != 110').joins(:order)
         .where('orders.date_finalization_begun is not null and orders.date_patron_deliverables_complete is null')
   end

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      if self.unit_status == "approved" && self.metadata.nil?
         errors.add(:base, "Metadata is required")
         throw(:abort)
      end

      # boolean fields cannot be NULL at database level
      self.include_in_dl = 0 if self.include_in_dl.nil?
      self.order_id = 0 if self.order_id.nil?
      self.remove_watermark = 0 if self.remove_watermark.nil?
      self.unit_status = "unapproved" if self.unit_status.nil? || self.unit_status.empty?
   end
   after_save do
      if self.master_files.count > 0 && !self.metadata.nil?
         self.master_files.each do |mf|
            # if unit metadata is changed while there are master files,
            # update all of those master files to match the unit. IMPORTANT:
            # Don't do this if masterfile has XML metadata. These will always
            # be different from the unit and must remain that way - the metadata
            # is specific to each masterfile. ExternalMetadata can fall under similar
            # circumstance, so don't update those either
            next if !mf.metadata.nil? && (mf.metadata.type == "XmlMetadata" || mf.metadata.type == "ExternalMetadata")
            if mf.metadata.nil? || (!mf.metadata.nil? && mf.metadata.id != self.metadata.id)
               mf.update(metadata: self.metadata)
            end
         end
      end
   end

   #------------------------------------------------------------------
   # aliases
   #------------------------------------------------------------------
   # Necessary for Active Admin to poplulate pulldown menu
   alias_attribute :name, :id

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def update_dir
      return File.join(Settings.production_mount, "finalization", "unit_update", directory)
   end

   def can_finalize?
      return date_archived.nil? && project.nil? && date_dl_deliverables_ready.nil? && unit_status == 'approved' && !reorder
   end

   def ocr_candidate?
      return false if metadata.nil?
      return false if metadata.ocr_hint.nil?
      return metadata.ocr_hint.ocr_candidate
   end

   def directory
      return "%09d" % self.id
   end

   def approved?
      return self.unit_status == "approved"
   end

   def error?
      return self.unit_status == "error"
   end

   def done?
      return self.unit_status == "done"
   end

   def canceled?
      return self.unit_status == "canceled"
   end

   def ingested?
      return !date_dl_deliverables_ready.nil? || !date_patron_deliverables_ready.nil? || !date_archived.nil? || master_files.count > 0
   end

   def in_dl?
      return self.date_dl_deliverables_ready?
   end

   def has_xml_masterfiles?
      self.master_files.each do |mf|
         next if mf.metadata.nil?
         next if mf.metadata.type != "XmlMetadata"
         return true
      end
      return false
   end

   def ready_for_repo?
      return false if self.include_in_dl == false
      return false if self.metadata.nil?
      return false if self.metadata.availability_policy_id.nil?
      return true if self.date_dl_deliverables_ready.nil? and not self.date_archived.nil?
      return false
   end

   def last_error
      js = self.job_statuses.order(created_at: :desc).first
      if !js.nil? && js.status == 'failure'
         return {job: js[:id], error: js[:error] }
      end
      js = self.order.job_statuses.order(created_at: :desc).first
      if !js.nil? && js.status == 'failure'
         return {job: js[:id], error: js[:error] }
      end
   end

   # Within the scope of a Unit's order, return the Unit which follows
   # or precedes the current Unit sequentially.
   def next
      units_sorted = self.order.units.sort_by {|unit| unit.id}
      if units_sorted.find_index(self) < units_sorted.length
         return units_sorted[units_sorted.find_index(self)+1]
      else
         return nil
      end
   end

   def previous
      units_sorted = self.order.units.sort_by {|unit| unit.id}
      if units_sorted.find_index(self) > 0
         return units_sorted[units_sorted.find_index(self)-1]
      else
         return nil
      end
   end

   def pick_exemplar
      # First, wipe out any lingering exemplar setting
      master_files.update_all(exemplar: false)

      # Find exemplar. Preference: Title-page/title page (best), Front Cover (2nd), or 1 (last)
      tgts = ["title-page", "title page", "front cover", "front board", "1"]
      exemplar = nil
      master_files.each do |mf|
         next if mf.title.blank?
         title = mf.title.strip.downcase
         if tgts.include? title
            if exemplar.nil?
               exemplar = {mf: mf, priority: tgts.index(title) }
            else
               if tgts.index(title) < exemplar[:priority]
                  exemplar = {mf: mf, priority: tgts.index(title) }
               end
            end
         end
      end

      if !exemplar.blank?
         exemplar[:mf].update(exemplar: true)
         return exemplar[:mf].filename
      end

      # if we got here, an exemplar with matching name was not found
      # try to make sure it is not a spine or egde
      master_files.each do |mf|
         next if mf.title == "Spine" || mf.title == "Head" || mf.title == "Tail" || mf.title == "Fore-edge"
         w = mf.image_tech_meta.width
         h = mf.image_tech_meta.height
         ratio = w.to_f / h.to_f

         # look for something kinda square-ish
         if ratio > 0.4 && ratio < 1.4
            mf.update(exemplar: true)
            return mf.filename
         end
      end

      # nothing else found, just go with first
      master_files.first.update(exemplar: true)
      return master_files.first.filename
   end
end

# == Schema Information
#
# Table name: units
#
#  id                             :integer          not null, primary key
#  order_id                       :integer          default(0), not null
#  metadata_id                    :integer
#  unit_status                    :string(255)
#  unit_extent_estimated          :integer
#  unit_extent_actual             :integer
#  patron_source_url              :text(65535)
#  special_instructions           :text(65535)
#  created_at                     :datetime
#  updated_at                     :datetime
#  intended_use_id                :integer
#  staff_notes                    :text(65535)
#  date_archived                  :datetime
#  date_patron_deliverables_ready :datetime
#  include_in_dl                  :boolean          default(FALSE)
#  date_dl_deliverables_ready     :datetime
#  remove_watermark               :boolean          default(FALSE)
#  master_files_count             :integer          default(0)
#  complete_scan                  :boolean          default(FALSE)
#  reorder                        :boolean          default(FALSE)
#  throw_away                     :boolean          default(FALSE)
#  ocr_master_files               :boolean          default(FALSE)
#
