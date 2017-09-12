class Unit < ApplicationRecord

   UNIT_STATUSES = %w[approved canceled condition copyright unapproved]

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
   scope :ready_for_repo, ->{joins(:metadata).where("metadata.availability_policy_id is not null").where(:include_in_dl => true).where(:date_dl_deliverables_ready => nil).where("date_archived is not null") }
   scope :awaiting_copyright_approval, ->{where(:unit_status => 'copyright') }
   scope :awaiting_condition_approval, ->{where(:unit_status => 'condition') }
   scope :approved, ->{where(:unit_status => 'approved') }
   scope :unapproved, ->{where(:unit_status => 'unapproved') }
   scope :canceled, ->{where(:unit_status => 'canceled') }
   scope :overdue_materials, ->{where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }
   scope :checkedout_materials, ->{where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }

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
            # is specific to each masterfile.
            next if mf.metadata.type == "XmlMetadata"
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
   def has_in_process_files?
      in_proc_dir = get_finalization_dir(:in_process)
      return false if !File.exist?(in_proc_dir)
      return Dir[File.join(in_proc_dir, '**', '*')].count { |file| File.file?(file) } > 0
   end

   def directory
      return "%09d" % self.id
   end

   def approved?
      if self.unit_status == "approved"
         return true
      else
         return false
      end
   end

   def canceled?
      if self.unit_status == "canceled"
         return true
      else
         return false
      end
   end

   def ingested?
      return !date_dl_deliverables_ready.nil? || !date_patron_deliverables_ready.nil? || !date_archived.nil?
   end

   def in_dl?
      return self.date_dl_deliverables_ready?
   end

   def has_xml_masterfiles?
      self.master_files.each do |mf|
         next if mf.metadata == self.metadata
         next if mf.metadata.nil?
         return true if mf.metadata.type == "XmlMetadata"
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

   def patron_deliverables_available?
      return false if self.date_patron_deliverables_ready.nil?
      assemble_dir = get_finalization_dir(:assemble_deliverables)
      return false if !Dir.exist? assemble_dir
      return Dir["#{assemble_dir}/*"].length >= self.master_files.count
   end

   # helper to get directory used in finalization. Takes into account base directory
   # configured by project (should one exist). Note a slight change: the mode portion
   # of the process_deliverables has been dropped. Doesn't seem to be a need for it
   #
   def get_finalization_dir(name)
      dir = ""
      unit_dir = "%09d" % self.id
      if name == :dropoff
         dir = File.join(DROPOFF_DIR, unit_dir)
         dir = File.join(project.workflow.base_directory, "finalization", "10_dropoff", unit_dir) if !project.nil?
      elsif name == :in_process
         dir = File.join(IN_PROCESS_DIR, unit_dir)
         dir = File.join(project.workflow.base_directory, "finalization", "20_in_process", unit_dir) if !project.nil?
      elsif name == :process_deliverables
         dir = File.join(PROCESS_DELIVERABLES_DIR, unit_dir)
         if !project.nil?
            dir = File.join(project.workflow.base_directory, "finalization", "30_process_deliverables", unit_dir)
         end
      elsif name == :assemble_deliverables
         order_dir = File.join("order_#{self.order.id}", self.id.to_s)
         dir = File.join(ASSEMBLE_DELIVERY_DIR, order_dir)
         if !project.nil?
            dir = File.join(project.workflow.base_directory, "finalization", "40_assemble_deliverables", order_dir)
         end
      elsif name == :delete_from_finalization
         dir = File.join(DELETE_DIR_FROM_FINALIZATION, unit_dir)
         if !project.nil?
            dir = File.join(project.workflow.base_directory, "ready_to_delete", "from_finalization", unit_dir)
         end
      elsif name == :delete_from_update
         dir = File.join(DELETE_DIR, "from_update", unit_dir)
         if !project.nil?
            dir = File.join(project.workflow.base_directory, "ready_to_delete", "from_update", unit_dir)
         end
      else
         raise "Unknown directory #{name}"
      end
      return dir
   end

    def get_scan_dirs( )
      unit_dir = "%09d" % self.id
      scan_dir = PRODUCTION_SCAN_DIR
      if !project.nil?
          scan_dir = File.join(project.workflow.base_directory, "scan")
      end
      dirs = []
      scan_subdirs = [
         '01_from_archive', '10_raw', '40_first_QA', '50_create_metadata',
         '60_rescans_and_corrections', '70_second_qa', '80_final_qa', '90_make_deliverables',
         '101_archive', '100_finalization'
      ]
      scan_subdirs.each do |subdir|
         File.join(scan_dir, subdir, unit_dir)
      end
      return dirs
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
#  date_materials_received        :datetime
#  date_materials_returned        :datetime
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
#  checked_out                    :boolean          default(FALSE)
#  master_files_count             :integer          default(0)
#  complete_scan                  :boolean          default(FALSE)
#  reorder                        :boolean          default(FALSE)
#
