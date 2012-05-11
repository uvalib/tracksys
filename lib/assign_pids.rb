# This module provides methods for requesting PIDs (persistent identifiers)
# from the digital library object management system (namely Fedora) and saving
# them to the appropriate records in this Tracking System (namely Bibl,
# MasterFile, and Component records).
#
# If a record already has an assigned PID, it is left unchanged; a new PID is
# not requested.
module AssignPids
  
  # Updates Bibl records, and associated MasterFile and Component records as
  # appropriate, with PIDs obtained from an external PID-generating server.
  #
  # In: Array of Bibl records for which to assign PIDs as needed.
  # Out: Returns nil. Exceptions are raised.
  #
  # By default, all Units associated with the Bibl are processed. Optionally
  # takes an array of Unit records which serves as a filter for the Units to
  # be processed; that is, a Unit must be included in the array passed to be
  # processed.
  def self.assign_pids(bibls, units_filter = nil, pid_namespace = nil)
    # determine how many PIDs are needed
    pid_count = 0
    bibls.each do |bibl|
      pid_count += 1 if bibl.pid.blank?  # one PID for Bibl record itself
      
      bibl.units.each do |unit|
        next unless UnitsFilter.process_unit?(unit, units_filter)
        
        unit.master_files.each do |master_file|
          pid_count += 1 if master_file.pid.blank?  # one PID for each associated MasterFile
        end
        
        unit.components.each do |component|
          pid_count += 1 if component.pid.blank?  # one PID for each associated Component
        end
      end
    end
    
    return nil if pid_count.zero?
    
    pids = request_pids(pid_count, pid_namespace)
    
    if pids.length < pid_count
      raise "Unable to retrieve the number of PIDs needed for this operation"
    end
    
    # save pids to tracksys records as needed
    bibls.each do |bibl|
      bibl.pid = pids.shift if bibl.pid.blank?
      bibl.save!
      
      bibl.units.each do |unit|
        next unless UnitsFilter.process_unit?(unit, units_filter)
        
        unit.master_files.each do |master_file|
          master_file.pid = pids.shift if master_file.pid.blank?
          master_file.save!
        end
        
        unit.components.each do |component|
          component.pid = pids.shift if component.pid.blank?
          component.save!
        end
      end
    end
    
    return nil
  end

  #-----------------------------------------------------------------------------

  # Returns one PID
  def self.get_pid(pid_namespace = nil)
    return request_pids(1, pid_namespace).first
  end

  #-----------------------------------------------------------------------------

  # Requests PIDs from an external PID-generating server. Requests number of
  # PIDs passed. Returns array of string values.
  def self.request_pids(pid_count, pid_namespace = nil)
    return Array.new if pid_count.to_i == 0
    
    if pid_namespace.nil?
      if Rails.env == 'production'
        pid_namespace = 'uva-lib'
      else
        # If you set the namespace to empty string, the PID generator will use
        # its default namespace, but since that default is subject to change
        # it's probably better to specify an obviously temp/testing namespace
        pid_namespace = 'test'
      end
    end
    
    # Set up REST client
    @resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password

    url = "/objects/nextPID?numPIDs=#{pid_count}&namespace=#{pid_namespace}&format=xml"
    pids = Nokogiri.XML(@resource[url].send :post, '', :content_type => 'text/xml').xpath('//pid').map(&:content)
  
    return pids
  end

end
