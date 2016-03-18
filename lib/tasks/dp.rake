#encoding: utf-8
require 'fileutils'

namespace :dp do
   desc "Split merged directories. PARAM part=n, optional param: src=[path tp lib_content64 sandbox], test=1 for a dry run"
   task :split  => :environment do
      src = ENV['src']
      src = "/lib_content64" if src.nil?
      src = File.join(src, "Daily_Progress")
      part = ENV['part']
      raise "Part is required" if part.nil?
      dry_run = false
      dry_run = true if !ENV['test'].nil?

      puts "Source file: part#{part}.txt"
      puts ""
      puts "** DRY RUN: No directories will be created and no files moved **" if dry_run
      puts ""

      $stdout.sync = true
      f = File.open(Rails.root.join("data", "fix_dp/part#{part}.txt"),"r")
      f.each_line do |line|
         # first split the line into subdir & comma separated list of indexes
         line_parts = line.split("|")

         # split the comma separated indexes to array 
         bits = line_parts[1].split(",")

         # get path and issue from first part of line and ensure path exists
         issue_subdir = line_parts[0]
         issue_date = issue_subdir.split("/").last
         issue_path = File.join(src, issue_subdir)
         if !Dir.exist? issue_path
            puts "* WARNING: #{issue_path} missing"
            next
         end

         # Get a list of all .tif files in the source directory
         files = Dir["#{issue_path}/*.tif"]
         files.sort! # ensure they are ordered by page number ascending

         puts "Splitting #{issue_path}..."
         orig_date = issue_date
         bits.each do |page_num|
            page_num.strip!
            split_page_file = "#{page_num.rjust(5, '0')}.tif"
            issue_date = (issue_date.to_i+1).to_s
            new_dir = issue_path.gsub(/#{orig_date}/, issue_date)
            if File.exists?(new_dir)
               if dry_run
                  raise "Target split directory #{issue_date} already exists. Aborting issue #{orig_date}"
               else
                  puts "   * ERROR: Target split directory #{issue_date} already exists. Aborting issue #{orig_date}"
                  break
               end
            end

            puts  "   NEW ISSUE #{new_dir}, start: #{split_page_file}"
            print "   "
            if dry_run
               puts "Create directory #{new_dir}"
            else
               Dir.mkdir(new_dir)
               if !Dir.exist? new_dir
                  if dry_run
                     raise "Cannot create target split directory #{issue_date}. Aborting issue #{orig_date}"
                  else
                     puts "   * ERROR: Cannot create target split directory #{issue_date}. Aborting issue #{orig_date}"
                     break
                  end
               end
            end

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
               if dry_run
                  puts "      Move #{File.basename(files[i])} to #{File.basename(dest)}"
               else
                  FileUtils.mv(files[i], dest)
                  print "."
               end
               page += 1
            end
            puts ""
         end
      end
      f.close
   end
end
