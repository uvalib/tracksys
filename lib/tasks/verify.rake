#encoding: utf-8

namespace :verify do
   desc "Generate list of approved units in None with no master files"
   task :none_list  => :environment do
      Unit.where(archive_id: 4).where(unit_status: 'approved').each do |u|
         if u.master_files.count == 0
            puts u.id
         end
      end
   end

   desc "Find metadata for units with archive = None"
   task :none  => :environment do
      entries = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
      ranges = []
      entries.each do |d|
         ranges << d
      end

      $stdout.sync = true
      puts "Finding metadata for units in archive None..."
      cnt = 0
      err = 0
      Unit.joins(:master_files).where(archive_id: 4).to_a.uniq.each do |u|
         print "."
         range_dir = ""
         ranges.each do |r|
            bits = r.split('-')
            if u.id.between?(bits.first.to_i, bits.last.to_i)
               range_dir = r
               break
            end
         end
         unit_dir = u.id.to_s.rjust(9, '0')
         tgt = File.join(PRODUCTION_METADATA_DIR, range_dir, unit_dir)
         if !Dir.exist? tgt
            err += 1
            puts "  * No metadata for unit #{u.id}"
         end
         cnt += 1
      end
      puts ""
      puts "COMPLETE. #{cnt} units checked, #{err} not found"
   end

   desc "Verify stornext unit content on lib_content44"
   task :stornext  => :environment do
      lc44 = "/lib_content44/RMDS_archive/CheckSummed_archive"
      snext = "/RMDS_archive/CheckSummed_archive"
      puts "Verifying #{snext} and #{lc44} match..."

      $stdout.sync = true
      cnt = 0
      errs = 0
      ignore = [".DS_Store", ".git", ".gitignore"]
      Unit.where(archive_id: 2).each do |u|
         unit_dir = u.id.to_s.rjust(9, '0')
         print "."

         # dump lib_content44 content
         lc_files = []
         pth = "#{lc44}/#{unit_dir}/*.*"
         Dir["#{lc44}/#{unit_dir}/*.*"].each do |f|
            fn = File.basename f
            lc_files << fn if !ignore.include? fn
         end
         lc_files.sort!

         # dump stornext content
         sn_files = []
         Dir["#{snext}/#{unit_dir}/*.*"].each do |f|
            fn = File.basename f
            sn_files << fn if !ignore.include? fn
         end
         sn_files.sort!

         # if the union of the two listings is different, we have a problem
         union = sn_files|lc_files
         if sn_files != union || lc_files != union
            errs += 1
            puts " * ERROR: Unit #{u.id} archive mismatch. StorNext has #{sn_files.count} files, lib_content44 has #{lc_files.count}"
         end
         cnt += 1
      end
      puts "COMPLETE. #{cnt} directories checked, #{errs} errors found"
   end
end
