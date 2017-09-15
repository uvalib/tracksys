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
end
