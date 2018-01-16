#
# Finder is a utlility class used to find the correct directory
# for various unit functions. It bundles up all of the common
# directory names and conventions used by tracksys, combines them with project settings
# and generates path names. If there are no settings, the default base directory
# is the configured production mount (Settings.production_mount)
#
class Finder

   # Find the bulk xml directory for a unit. Possible actions are :dropoff and :pickup
   #
   def self.xml_directory(unit, action)
      unit_dir = "%09d" % unit.id
      base_dir = base_dir(unit)
      xml_dir = File.join(base_dir, "xml_metadata")
      if action == :dropoff
         return File.join(xml_dir, "dropoff", unit_dir)
      elsif action == :pickup
         return File.join(xml_dir, "pickup", unit_dir)
      else
         raise "Unknown bulk XML action: #{action}"
      end
   end

   # Get a list of unit update directories. Difference is 0-paddded vs non-padded number
   #
   def self.update_dir( unit )
      unit_dir = "%09d" % unit.id
      base_dir = base_dir(unit)
      finalize_dir = File.join(base_dir, "finalization")
      return File.join(finalize_dir, "unit_update", "#{unit_dir}")
   end

   def self.scan_from_archive_dir
      dir = File.join(Settings.production_mount, "scan", "01_from_archive")
   end

   # Helper to get the scanning workflow directories based upon project/workflow. Defaults
   # to didgserv-production if not project is configured. This directory does not include UNIT
   #
   def self.scan_dirs( unit )
      base_dir = base_dir(unit)
      scan_dir = File.join(base_dir, "scan")
      scan_subdirs = [
         '01_from_archive', '10_raw', '40_first_QA', '50_create_metadata',
         '60_rescans_and_corrections', '70_second_qa', '80_final_qa', '90_make_deliverables',
         '101_archive', '100_finalization'
      ]
      dirs = []
      scan_subdirs.each do |subdir|
         dirs << File.join(scan_dir, subdir)
      end
      return dirs
    end

    # Get a finalization directory by name. Supported names: base, dropoff, in_process,
    #    process_deliverables, assemble_deliverables, delete_from_finalization, delete_from_update
    #    and delete_from_delivered
    #
    def self.finalization_dir(unit, name)
      unit_dir = "%09d" % unit.id
      base_dir = base_dir(unit)
      finalize_dir = File.join(base_dir, "finalization")
      ready_to_del_dir = File.join(base_dir, "ready_to_delete")

      dir = ""
      if name == :dropoff
         dir = File.join(finalize_dir, "10_dropoff", unit_dir)
      elsif name == :in_process
         dir = File.join(finalize_dir, "20_in_process", unit_dir)
      elsif name == :process_deliverables
         dir = File.join(finalize_dir, "30_process_deliverables", unit_dir)
      elsif name == :assemble_deliverables
         order_dir = File.join("order_#{unit.order.id}", unit.id.to_s)
         dir = File.join(finalize_dir, "40_assemble_deliverables", order_dir)
      elsif name == :delete_from_finalization
         dir = File.join(ready_to_del_dir, "from_finalization", unit_dir)
      elsif name == :delete_from_update
         dir = File.join(ready_to_del_dir, "from_update", unit_dir)
      elsif name == :delete_from_delivered
         order_dir = File.join("order_#{unit.order.id}", unit.id.to_s)
         dir = File.join(ready_to_del_dir, "delivered_orders", order_dir)
      else
         raise "Unknown finalization directory: #{name}"
      end
      return dir
    end

    def self.ready_to_delete_from_scan(unit, scan_dir)
      unit_dir = "%09d" % unit.id
      del_dir = "#{unit_dir}_from_#{scan_dir}"
      base_dir = base_dir(unit)
      ready_to_del_dir = File.join(base_dir, "ready_to_delete", "from_scan", del_dir)
      if Dir.exists? ready_to_del_dir
         ts = Time.now.to_i
         del_dir << ".#{ts}"
         ready_to_del_dir = File.join(base_dir, "ready_to_delete", "from_scan", del_dir)
      end
      return ready_to_del_dir
    end

    def self.base_dir(unit)
      base_dir = Settings.production_mount
      base_dir = unit.project.workflow.base_directory if !unit.project.nil?
      return base_dir
    end
    private_class_method :base_dir
end
