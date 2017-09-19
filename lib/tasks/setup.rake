#encoding: utf-8

namespace :setup do
   desc "Set finalize/scan/delete dir structure on new system"
   task :dirs  => :environment do
      base = ENV['base']
      abort("'base' param is required") if base.nil?
      abort("base must exist!") if !Dir.exists? base

      dirs = {
         finalization:
            ["10_dropoff", "20_in_process", "30_process_deliverables", "40_assemble_deliverables", "unit_update"],
         ready_to_delete: [ "from_scan", "from_finalization", "delivered_orders", "from_update"],
         scan: ["01_from_archive", "10_raw", "40_first_QA", "70_second_qa", "80_final_QA"],
         xml_metadata: ["dropoff", "pickup"] }
      dirs.each do | key, val |
         tgt = File.join(base, key.to_s)
         if !Dir.exists? tgt
            puts "Create #{tgt}..."
            FileUtils.mkdir_p tgt
         end
         val.each do |dir|
            subdir = File.join(tgt, dir)
            if !Dir.exists? subdir
               puts "Create #{subdir}..."
               FileUtils.mkdir_p subdir
            end
         end
      end
   end
end
