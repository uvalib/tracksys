require "#{Hydraulics.models_dir}/unit"

class Unit

  include Pidable
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender


  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  belongs_to :index_destination, :counter_cache => true
  has_and_belongs_to_many :legacy_identifiers

  # The request form requires having data stored temporarily to the unit model and then concatenated into special instructions.  Those fields are:
  attr_accessor :request_call_number, :request_copy_number, :request_volume_number, :request_issue_number, :request_location, :request_title, :request_author, :request_year, :request_description, :request_pages_to_digitize

  require 'rqrcode'
  # Override Hydraulics Unit.overdue_materials and Unit.checkedout_materials scopes becuase our data should only concern itself
  # with those materials checkedout a few months before Tracksys 3 goes live (i.e. before March 1st?)
  scope :overdue_materials, where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')
  scope :checkedout_materials, where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')
  scope :uncompleted_units_of_partially_completed_orders, includes(:order).where(:unit_status => 'approved', :date_archived => nil).where('intended_use_id != 110').where('orders.date_finalization_begun is not null')

  after_update :check_order_status, :if => :unit_status_changed?

  def check_order_status
    if self.order.ready_to_approve?
      message = ActiveSupport::JSON.encode({ :order_id => order.id })
      publish :update_order_status_approved, message
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

  def check_unit_delivery_mode
    CheckUnitDeliveryMode.exec( {:unit_id => self.id})
  end

  def get_from_stornext(computing_id)
    message = ActiveSupport::JSON.encode( {:workflow_type => 'patron', :unit_id => self.id, :computing_id => computing_id })
    publish :copy_archived_files_to_production, message
  end

  def import_unit_iview_xml
    unit_dir = "%09d" % self.id
    ImportUnitIviewXML.exec( {:unit_id => self.id, :path => "#{IN_PROCESS_DIR}/#{unit_dir}/#{unit_dir}.xml"})
  end

  def qa_filesystem_and_iview_xml
    logger.tagged("MS3UF") { logger.debug "model method Unit#qa_filesystem_and_iview_xml called on #{self.id}" }
    QaFilesystemAndIviewXml.exec( {:unit_id => self.id} )
  end

  def qa_unit_data
    qa_unit_data.exec( {:unit_id => self.id})
  end

  def queue_unit_deliverables
    @unit_dir = "%09d" % self.id
    QueueUnitDeliverables.exec( {:unit_id => self.id, :mode => 'patron', :source => File.join(PROCESS_DELIVERABLES_DIR, 'patron', @unit_dir)})
  end

  def send_unit_to_archive
    SendUnitToArchive.exec( {:unit_id => self.id, :internal_dir => 'yes', :source_dir => "#{IN_PROCESS_DIR}"})
  end

  def start_ingest_from_archive
    StartIngestFromArchive.exec( {:unit_id => self.id, :order_id => self.order_id })
  end

  def copy_metadata_to_metadata_directory
    unit_dir = "%09d" % self.id
    unit_path = File.join(IN_PROCESS_DIR, unit_dir)
    CopyMetadataToMetadataDirectory.exec( {:unit_id => self.id, :unit_path => unit_path})
  end

  # End processors

  def qr
    code = RQRCode::QRCode.new("#{TRACKSYS_URL}/admin/unit/checkin/#{self.id}", :size => 7)
    return code
  end

  # utility method to present consistent Fedora object structure within a unit
  # Ordinarily, MasterFiles without transcription text do not generate a 'transcription'
  # datastream upon ingest, but this method will add blank transcription fields to
  # MasterFile objects and update their Repository counterparts as needed
  def fill_in_missing_transcriptions
    text=" \n"
    empty_items=self.master_files.where(:transcription_text => nil)
    if empty_items.count > 0
      empty_items.each do |item|
        item.transcription_text=text unless item.transcription_text
        item.save!
        item.reload
        if item.exists_in_repo?
          Fedora.add_or_update_datastream(item.transcription_text, item.pid,
            'transcription', 'Transcription', :contentType => 'text/plain',
            :mimeType => 'text/plain', :controlGroup => 'M')
        end
      end
    end
  end

end
# == Schema Information
#
# Table name: units
#
#  id                             :integer(4)      not null, primary key
#  order_id                       :integer(4)      default(0), not null
#  bibl_id                        :integer(4)
#  archive_id                     :integer(4)
#  heard_about_resource_id        :integer(4)
#  unit_status                    :string(255)
#  date_materials_received        :datetime
#  date_materials_returned        :datetime
#  unit_extent_estimated          :integer(4)
#  unit_extent_actual             :integer(4)
#  patron_source_url              :text
#  special_instructions           :text
#  created_at                     :datetime
#  updated_at                     :datetime
#  intended_use_id                :integer(4)
#  exclude_from_dl                :boolean(1)      default(FALSE), not null
#  staff_notes                    :text
#  use_right_id                   :integer(4)
#  date_queued_for_ingest         :datetime
#  date_archived                  :datetime
#  date_patron_deliverables_ready :datetime
#  include_in_dl                  :boolean(1)      default(FALSE)
#  date_dl_deliverables_ready     :datetime
#  remove_watermark               :boolean(1)      default(FALSE)
#  master_file_discoverability    :boolean(1)      default(FALSE)
#  indexing_scenario_id           :integer(4)
#  checked_out                    :boolean(1)      default(FALSE)
#  availability_policy_id         :integer(4)
#  master_files_count             :integer(4)      default(0)
#  automation_messages_count      :integer(4)      default(0)
#  index_destination_id           :integer(4)
#
