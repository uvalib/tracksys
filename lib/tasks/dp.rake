#encoding: utf-8
require 'fileutils'

namespace :dp do
   desc "Split merged directories. PARAM part=n, optional param: src=[path tp lib_content64 sandbox]"
   task :split  => :environment do
      src = ENV['src']
      src = "/lib_content64" if src.nil?
      src = File.join(src, "Daily_Progress")
      part = ENV['part']
      raise "Part is required" if part.nil?

      puts "Source file: part#{part}.txt"
      $stdout.sync = true
      f = File.open(Rails.root.join("data", "fix_dp/part#{part}.txt"),"r")
      f.each_line do |line|
         bits = line.split(",")
         issue_subdir = bits.delete_at(0)
         issue_date = issue_subdir.split("/").last
         issue_path = File.join(src, issue_subdir)
         if !Dir.exist? issue_path
            #puts " * WARNING: #{issue_path} missing"
            next
         end

         # Get a list of all .tif files in the source directory
         files = Dir["#{issue_path}/*.tif"]

         puts "Splitting #{issue_path}..."
         orig_date = issue_date
         bits.each do |page_num|
            page_num.strip!
            split_page_file = "#{page_num.rjust(5, '0')}.tif"
            issue_date = (issue_date.to_i+1).to_s
            new_dir = issue_path.gsub(/#{orig_date}/, issue_date)
            if File.exists?(new_dir)
               puts "   * ERROR: Target split directory #{issue_date} already exists. Aborting issue #{orig_date}"
               break
            end

            puts  "   NEW ISSUE #{new_dir}, start: #{split_page_file}"
            print "   "
            Dir.mkdir(new_dir)

            # find index of the split page in the directory listing
            tgt = File.join(issue_path,split_page_file)
            i0 = files.index tgt
            i1 = files.length-1 # assume we are moving all remining files

            # is this the last block of pages to move to a new issue directory?
            curr_idx = bits.index(page_num)
            if curr_idx < bits.length-1
               # the page number from data file is the start of new issue
               # we want to move all of the pages preceeing this one, so subtract 1
               last_page_num = bits[curr_idx+1].strip.to_i - 1
               last_page = "#{last_page_num.to_s.rjust(5, '0')}.tif"
               tgt = File.join(issue_path,last_page)
               i1 = files.index tgt
            end

            # move the block of file to new directory
            page = 1
            for i in i0..i1 do
               pg_file = "#{page.to_s.rjust(5, '0')}.tif"
               dest = File.join(new_dir, pg_file)
               #puts "      Moving #{File.basename(files[i])} to #{File.basename(dest)}"
               FileUtils.mv(files[i], dest)
               page += 1
               print "."
            end
            puts ""
         end
      end
      f.close
   end
end