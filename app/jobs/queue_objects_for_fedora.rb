class QueueObjectsForFedora < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      @source = message[:source] # this is the unit's archive directory file path
      @working_unit = Unit.find(message[:unit_id])

      # Will put all objects to be ingested into repo into an array called things
      things = Array.new

      # When the last master file is ingested as a JP2K, a message will need to be sent to the bus so that the indexing content model can be attached to all newly
      # created objects for this unit.  In order to determine when that last JP2K image is created, we need to attach at this stage a flag to all messages
      # informing future processors that the message it is working on is the one for the last master file.  Thus, we will iterate through a loop, incrementing
      # +1 each time the system handles a master file and, when the last master file is being worked on, the default value for last (= 0) will be changed
      # to 1.
      @num_master_files = @working_unit.master_files.count
      @master_file_messages = 0
      @last = 0

      # Always add a unit's Bibl record
      things << @working_unit.bibl

      # Add a Unit's Bibl's parents (if in existence)
      # @working_unit.bibl.ancestors.each {|bibl| things << bibl} unless @working_unit.bibl.ancestors.empty?
      @working_unit.master_files.each {|mf| things << mf }
      @working_unit.components.each do |component|
         things << component
         # the following may produce duplicates, especially when ingesting many items from the same
         # EAD guide, so we must uniq them before emitting messages (as done four lines below).
         things << component.ancestors
      end

      things.flatten!

      things.uniq.each do |thing|
         # If object does not have a pid, request one and save the object with newly requested pid
         if not thing.pid
            @pid =  AssignPids.request_pids(1)
            thing.pid = @pid[0]
            thing.save!
         else
            @pid = thing.pid
         end

         # LFF Don't send the top-level Daily Progress component or bibl
         if @pid == "uva-lib:2137307" || @pid == "uva-lib:2065830"
           logger.info "Skipping Daily Progress top-level component/bibl (pid: #{@pid})"
           next
         end

         if thing.is_a? MasterFile
            @master_file_messages += 1
            if @master_file_messages == @num_master_files
               @last = 1
            end
         end

         PropogateAccessPolicies.exec_now({
            :unit_id => message[:unit_id], :source => @source, :object_class => thing.class.to_s,
            :object_id => thing.id, :last => @last }, self)
      end
      on_success "All ingestable objects related to Unit #{@messagable_id} are have been ingested."
   end
end
