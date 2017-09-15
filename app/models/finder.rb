#
# Finder is a utlility class used to find the correct directory
# for various unit functions. It bundles up all of the common
# directory names and conventions used by tracksys, combines them with project settings
# and generates path names. If there are no settings, the default base directory
# is the configured production mount (Settings.production_mount)
#
class Finder
   # fixed subdirectory names
   FINALIZATION_DIR = "finalization"
   XML_DIR = "xml_metadata"
   UPDATE_DIR = "unit_update"
   SCAN_DIR = "scan"

   # Find the bulk xml directory for a unit. Possible actions are :dropoff and :pickup
   #
   def self.xml_directory(unit, action)
      unit_dir = "%09d" % unit.id
      dir = File.join(Settings.production_mount, XML_DIR)
      dir = File.join(unit.project.workflow.base_directory, XML_DIR) if !unit.project.nil?
      if action == :dropoff
         return File.join(dir, "dropoff", unit_dir)
      elsif action == :pickup
         return File.join(dir, "pickup", unit_dir)
      else
         raise "Unknown bulk XML action: #{action}"
      end
   end

   # Get a list of unit update directories. Difference is 0-paddded vs non-padded number
   #
   def self.update_dirs( unit )
      unit_dir = "%09d" % unit.id
      finalize_dir = File.join(Settings.production_mount, FINALIZATION_DIR)
      if !unit.project.nil?
         finalize_dir = File.join(unit.project.workflow.base_directory, FINALIZATION_DIR)
      end
      return [
         File.join(finalize_dir, UPDATE_DIR, "#{unit.id}"),
         File.join(finalize_dir, UPDATE_DIR, "#{unit_dir}")
      ]
   end

   def self.scan_from_archive_dir
      dir = File.join(Settings.production_mount, SCAN, "01_from_archive")
   end

   # Helper to get the scanning workflow directories based upon project/workflow. Defaults
   # to didgserv-production if not project is configured
   #
   def self.scan_dirs( unit )
      unit_dir = "%09d" % unit.id
      scan_dir = File.join(Settings.production_mount, SCAN_DIR)
      if !unit.project.nil?
          scan_dir = File.join(unit.project.workflow.base_directory, SCAN_DIR)
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

    # Get a finalization directory by name. Supported names: base, dropoff, in_process,
    #    process_deliverables, assemble_deliverables, delete_from_finalization, delete_from_update
    #    and delete_from_delivered
    #
    def self.finalization_dir(unit, name)
      dir = ""
      unit_dir = "%09d" % unit.id
      if name == :base
          dir = "#{Settings.production_mount}/finalization"
          dir = File.join(unit.project.workflow.base_directory, "finalization") if !unit.project.nil?
      elsif name == :dropoff
          dir = File.join(DROPOFF_DIR, unit_dir)
          dir = File.join(unit.project.workflow.base_directory, "finalization", "10_dropoff", unit_dir) if !unit.project.nil?
      elsif name == :in_process
          dir = File.join(IN_PROCESS_DIR, unit_dir)
          dir = File.join(unit.project.workflow.base_directory, "finalization", "20_in_process", unit_dir) if !unit.project.nil?
      elsif name == :process_deliverables
          dir = File.join(PROCESS_DELIVERABLES_DIR, unit_dir)
          if !unit.project.nil?
             dir = File.join(unit.project.workflow.base_directory, "finalization", "30_process_deliverables", unit_dir)
          end
      elsif name == :assemble_deliverables
          order_dir = File.join("order_#{self.order.id}", self.id.to_s)
          dir = File.join(ASSEMBLE_DELIVERY_DIR, order_dir)
          if !unit.project.nil?
             dir = File.join(unit.project.workflow.base_directory, "finalization", "40_assemble_deliverables", order_dir)
          end
      elsif name == :delete_from_finalization
          dir = File.join(DELETE_DIR_FROM_FINALIZATION, unit_dir)
          if !unit.project.nil?
             dir = File.join(unit.project.workflow.base_directory, "ready_to_delete", "from_finalization", unit_dir)
          end
      elsif name == :delete_from_update
          dir = File.join(DELETE_DIR, "from_update", unit_dir)
          if !unit.project.nil?
             dir = File.join(unit.project.workflow.base_directory, "ready_to_delete", "from_update", unit_dir)
          end
      elsif name == :delete_from_delivered
          order_dir = File.join("order_#{unit.order.id}", unit.id.to_s)
          dir = File.join(DELETE_DIR_DELIVERED_ORDERS, order_dir)
          if !unit.project.nil?
             dir = File.join(unit.project.workflow.base_directory, "ready_to_delete", "delivered_orders", order_dir)
          end
      else
          raise "Unknown finalization directory: #{name}"
      end
      return dir
    end
end
