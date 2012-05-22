class QueueUnitDeliverablesProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :queue_unit_deliverables, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_patron_deliverables
  
  def on_message(message)
    logger.debug "QueueUnitDeliverablesProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming messages
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank? 
    raise "Parameter 'mode' is required" if hash[:mode].blank?

    @unit_id = hash[:unit_id]
    @mode = hash[:mode]
    @source = hash[:source]

    @unit_dir = "%09d" % @unit_id
    @working_unit = Unit.find(@unit_id)
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @working_order = @working_unit.order
    @master_files = @working_unit.master_files
    
    # Get unit level deliverable information (formation, resolution and customer status)
    @remove_watermark = @working_unit.remove_watermark
    @format = @working_unit.deliverable_format
    @desired_resolution = @working_unit.deliverable_resolution
    @personal_item = @working_unit.bibl.personal_item?
    @call_number = @working_unit.bibl.call_number
    @title = @working_unit.bibl.title
    @location = @working_unit.bibl.location

    @master_files.each {|master_file|
      if master_file == @master_files.last
        @last = "1"
      else
        @last = "0"
      end
       
      # Ensure that master file has a pid
      if not master_file.pid
        master_file.pid = AssignPids.get_pid
        master_file.save!
      end

      @actual_resolution = master_file.image_tech_meta.resolution
      @file_source = File.join(@source, master_file.filename)

      message = ActiveSupport::JSON.encode({ :master_file_id => master_file.id, :source => @file_source, :mode => @mode, :format => @format, :actual_resolution => @actual_resolution, :desired_resolution => @desired_resolution, :unit_id => @unit_id, :last => @last, :personal_item => @personal_item, :call_number => @call_number, :title => @title, :location => @location, :remove_watermark => @remove_watermark})  
      publish :create_patron_deliverables, message
    }   
  on_success "All images for #{@unit_id} have been sent for patron deliverable creation."
  end 
end
