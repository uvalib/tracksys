require "#{Hydraulics.models_dir}/unit"

class Unit

  # The request form requires having data stored temporarily to the unit model and then concatenated into special instructions.  Those fields are:
  attr_accessor :request_call_number, :request_copy_number, :request_volume_number, :request_issue_number, :request_location, :request_title, :request_author, :request_year, :request_description, :request_pages_to_digitize

  require 'rqrcode'
  # Override Hydraulics Unit.overdue_materials and Unit.checkedout_materials scopes becuase our data should only concern itself 
  # with those materials checkedout a few months before Tracksys 3 goes live (i.e. before March 1st?)
  scope :overdue_materials, where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')
  scope :checkedout_materials, where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')

  # after_update :fix_updated_counters

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

  # Processor information
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  publishes_to :copy_archived_files_to_production

  def check_unit_delivery_mode 
    message = ActiveSupport::JSON.encode( {:unit_id => self.id})
    publish :check_unit_delivery_mode, message   
  end

  def get_from_stornext(computing_id)
    message = ActiveSupport::JSON.encode( {:workflow_type => 'patron', :unit_id => self.id, :computing_id => computing_id })
    publish :copy_archived_files_to_production, message
  end

  def import_unit_iview_xml
    unit_dir = "%09d" % self.id
    message = ActiveSupport::JSON.encode( {:unit_id => self.id, :path => "#{IN_PROCESS_DIR}/#{unit_dir}/#{unit_dir}.xml"})
    publish :import_unit_iview_xml, message
  end

  def qa_filesystem_and_iview_xml
    message = ActiveSupport::JSON.encode( {:unit_id => self.id})
    publish :qa_filesystem_and_iview_xml, message
  end

  def qa_unit_data
    message = ActiveSupport::JSON.encode( {:unit_id => self.id})
    publish :qa_unit_data, message
  end

  def queue_unit_deliverables
    @unit_dir = "%09d" % self.id
    message = ActiveSupport::JSON.encode( {:unit_id => self.id, :mode => 'patron', :source => File.join(PROCESS_DELIVERABLES_DIR, 'patron', @unit_dir)})
    publish :queue_unit_deliverables, message
  end

  def send_unit_to_archive
    message = ActiveSupport::JSON.encode( {:unit_id => self.id, :internal_dir => 'yes', :source_dir => "#{IN_PROCESS_DIR}"})
    publish :send_unit_to_archive, message   
  end  # End processors

  def qr
    code = RQRCode::QRCode.new("#{TRACKSYS_URL}admin/unit/checkin/#{self.id}", :size => 7)
    return code
  end
end
