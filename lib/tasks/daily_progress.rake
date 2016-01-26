#encoding: utf-8

namespace :daily_progress do

   def update_followed_by(parent_component, new_component)
      prior = nil
      linked = false
      parent_component.children.order("date asc").each do |c|
         if linked
            puts "Finish linking; #{prior.date} followed by #{c.date}"
            prior.update_attribute(:followed_by_id, c.id)
            break
         end

         if new_component.date == c.date
            if !prior.nil?
               puts "Set #{prior.date} followed by #{new_component.date}"
               prior.update_attribute(:followed_by_id, new_component.id)
            end
            linked = true
         end

         prior = c
      end
   end

   desc "ingest daily progress issues (src=src_dir, box=nn, fedora=Y/N [OPTIONAL, default Y], year=yyyy [OPTIONAL], issue=yyyymmdd [OPTIONAL], order=order_id [OPTIONAL, default 5341])"
   task :ingest => :environment do
      src = ENV['src']
      box_num = ENV['box']
      raise "src is required!" if src.nil?
      raise "box is required!" if box_num.nil?
      box = "Box#{box_num}"

      # optional params
      ingest = !(ENV['fedora'] == 'N' || ENV['fedora'] == 'n')
      order_id = ENV['order']
      order_id = 5341 if order_id.nil?
      tgt_issue = ENV['issue']
      tgt_year = ENV['year']

      # Get the daily progress order, top level component and other required objects
      order = Order.find(order_id)
      bibl = Bibl.find(15226)
      dp_component = Component.find(497769)
      series = ComponentType.where(name:'series').first
      subseries = ComponentType.where(name:'subseries').first
      item = ComponentType.where(name:'item').first
      archive = Archive.find(5)
      ingested = File.open("log/dp_#{box}_ingested.txt", "w+")

      # Set top level directory for images to be 'Daily Progress/BoxNN'
      # Expected structure:
      #   ./Daily Progress/BoxNN/Date From-Date To/Issue Date (YYYYMMDD)/page images (00001.tif)
      root_dir = File.join(src, "Daily_Progress/#{box}")
      raise "Source directory does not exist!" if !Dir.exist? root_dir
      years = {}
      months = {}
      curr_issue = nil
      issue_unit = nil
      pagenum = 1
      skip_issue = false
      issue_date = ""
      puts "Scanning #{root_dir}..."
      Dir.glob("#{root_dir}/**/*.tif") do |f|
         # The AAA folder doesn't follow the expected structure. Skip it for now
         next if f.include? "AAA - Extras"

         # Filename like:
         #    lib_content64/Daily_Progress/Box01/Apr 21, 1930 - Sep 6, 1930/19300422/00001.tif
         parts = f.split("/")
         tif = parts[parts.length-1]         # format: 0-padded pagenumber .tif
         issue_date = parts[parts.length-2]  # format: YYYYMMDD

         # If a specific issue has been flagged, skip all others
         next if !tgt_issue.nil? && issue_date != tgt_issue

         # parse out reel info to add as a content_desc for the issue Item compobent
         date_range = parts[parts.length-3]
         box = parts[parts.length-4]
         legacy_fn = "#{date_range}/#{issue_date}/#{tif}"

         # construct the component hierarchy based on the issue date
         year = issue_date[0...4]
         next if !tgt_year.nil? && year != tgt_year

         if !years.include? year
            puts "* Find/Create SERIES component for YEAR #{year}"
            year_component = Component.where(date: year, parent_component_id: dp_component.id).first
            if year_component.nil?
               year_component = Component.new
               year_component.discoverability = 0
               year_component.indexing_scenario_id = 1
               year_component.index_destination_id = 3
               year_component.availability_policy_id = 1
               year_component.component_type = series
               year_component.date = year
               year_component.title = "Issues from #{year}"
               year_component.parent_component_id = dp_component.id
               year_component.save!
               update_followed_by(dp_component, year_component)
            end
            years[year] = year_component
         else
            year_component = years[year]
         end

         month_num = issue_date[4...6]
         month_str = Date::MONTHNAMES[month_num.to_i]
         month = "#{year}-#{month_num}"
         if !months.include? month
            puts "* Find/Create SUBSERIES component for YEAR/MONTH #{month}"
            month_component = Component.where(date: month, parent_component_id: year_component.id).first
            if month_component.nil?
               month_component = Component.new
               month_component.discoverability = 0
               month_component.indexing_scenario_id = 1
               month_component.index_destination_id = 3
               month_component.availability_policy_id = 1
               month_component.component_type = subseries
               month_component.date = month
               month_component.title = "Daily Progress Issues from #{month_str} #{year}"
               month_component.parent_component_id = year_component.id
               month_component.save!
               update_followed_by(year_component, month_component)
            end
            months[month] = month_component
         else
            month_component = months[month]
         end

         issue = "#{month}-#{issue_date[6...8]}"
         if curr_issue.nil? || curr_issue.date != issue
            content_desc = "From reel #{date_range}"
            content_desc = content_desc.gsub(/,/,'')
            puts "* Find/Create ITEM component for ISSUE #{issue}. ContentDesc: #{content_desc}"
            skip_issue = false

            if !curr_issue.nil?
               # ingest the previous issue unit, if one exists
               ingested << "#{issue_date}\n"
               if ingest
                  puts "   => Start ingest for unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{pagenum-1} master files"
                  StartIngestFromArchive.exec_now( { :unit_id => "#{issue_unit.id}" })
               end
            end

            curr_issue = Component.where(date: issue, parent_component_id: month_component.id).first
            if curr_issue.nil?
               curr_issue = Component.new
               curr_issue.discoverability = 0
               curr_issue.index_destination_id = 3
               curr_issue.indexing_scenario_id = 1
               curr_issue.availability_policy_id = 1
               curr_issue.component_type = item
               curr_issue.date = issue
               curr_issue.content_desc = content_desc
               curr_issue.title = "Daily Progress, #{month_str} #{issue_date[6...8]}, #{year}"
               curr_issue.parent_component_id = month_component.id
               curr_issue.save!
               update_followed_by(month_component, curr_issue)

               puts "   *  Create Unit for issue #{issue}"
               issue_unit = Unit.new
               issue_unit.order = order
               issue_unit.indexing_scenario_id = 1    # default
               issue_unit.availability_policy_id = 1  # public
               issue_unit.intended_use_id = 110       # Digital collectin building
               issue_unit.archive_id = 5              # temporary storage
               issue_unit.special_instructions = "Reel: #{date_range}\nIssue: #{issue}".gsub(/,/,'')
               issue_unit.staff_notes = "From #{box}"
               issue_unit.unit_status = 'approved'
               issue_unit.bibl = bibl
               issue_unit.save!
               pagenum = 1
            else
               puts "   * Issue already exists, SKIPPING"
               skip_issue = true
            end
         end

         # this issue was already ingested, skip it
         next if skip_issue

         puts "   - Master file for #{issue_date}: #{tif}"
         mf = MasterFile.new
         mf.discoverability = 0
         mf.indexing_scenario_id = 1
         mf.availability_policy_id = 1
         mf.unit = issue_unit
         mf.title = pagenum
         mf.tech_meta_type = "image"
         mf.type = 'Tiff'
         mf.component = curr_issue
         mf.filename = "%09d" % issue_unit.id + "_" + "%04d" % pagenum + ".tif"
         mf.filesize = File.size(f)
         mf.save!
         pagenum += 1

         # Add legacy identifiers
         lid1 = LegacyIdentifier.new
         lid1.label = "Daily Progress"
         lid1.description = "Daily Progress Vendor Filename"
         lid1.legacy_identifier = tif
         lid1.save!
         lid2 = LegacyIdentifier.new
         lid2.label = "Daily Progress"
         lid2.description = "Daily Progress Issue Date"
         lid2.legacy_identifier = issue_date
         lid2.save!
         mf.legacy_identifiers << lid1
         mf.legacy_identifiers << lid2
         mf.save!

         # Move the original file into the archive directory with the new name
         dest_dir = File.join(archive.directory, "%09d" % issue_unit.id)
         FileUtils.makedirs(dest_dir)
         dest_file = File.join(dest_dir, mf.filename )
         FileUtils.copy(f, dest_file)

         # checksum to ensure good copy. Save MD5
         source_md5 = Digest::MD5.hexdigest(File.read(f))
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
         if source_md5 != dest_md5
            puts "   ** Error in copy operation: source file '#{f}' to '#{dest_file}': MD5 checksums do not match"
         else
            mf.md5 = dest_md5
            mf.save!
         end

         # Create metadata from the file moved above
         payload = {source: dest_file, master_file_id: mf.id, last: 0}
         job = CreateImageTechnicalMetadataAndThumbnail.exec_now( payload )
      end

      # ingest the last unit, unless it was already ingested
      if !skip_issue && !issue_unit.nil?
         ingested << "#{issue_date}\n"
         if ingest
            puts "   => Start ingest for FINAL unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{pagenum-1} master files"
            StartIngestFromArchive.exec_now({ :unit_id => "#{issue_unit.id}" })
         end
      end

      # close out the ingested tracekr
      ingested.close
   end

   desc "detect badly named issues (src=src_dir) box=NN"
   task :detect_bad_names => :environment do
      src = ENV['src']
      raise "src is required!" if src.nil?
      boxn = ENV['box']
      raise "box is required!" if boxn.nil?
      box = "Box#{boxn}"

      root_dir = File.join(src, "Daily_Progress/#{box}")
      raise "Source directory does not exist!" if !Dir.exist? root_dir
      puts "Scanning #{root_dir} for badly named issues..."

      log = File.open("log/dp_#{box}_bad_issue_name.txt", "w")

      page_cnt = 0
      curr_issue = nil
      bad = 0
      Dir.glob("#{root_dir}/**/*.tif") do |f|
         next if f.include? "AAA - Extras"
         issue_dir = File.dirname(f)

         if curr_issue.nil? || curr_issue != issue_dir
            curr_issue = issue_dir
            parts = f.split("/")
            issue_date = parts[parts.length-2]  # expected format: YYYYMMDD
            if issue_date != issue_date.to_i.to_s
               puts "Bad issue date format: #{curr_issue}"
               log << "Bad issue date format: #{curr_issue}"
            end
         end
      end
      log.close
   end

   desc "detect merged issues (src=src_dir) box=NN"
   task :detect_merges => :environment do
      src = ENV['src']
      raise "src is required!" if src.nil?
      boxn = ENV['box']
      raise "box is required!" if boxn.nil?
      box = "Box#{boxn}"

      merge_threshold = 20
      merge_threshold = 24 if boxn == "03" || boxn == "04"

      root_dir = File.join(src, "Daily_Progress/#{box}")
      raise "Source directory does not exist!" if !Dir.exist? root_dir
      puts "Scanning #{root_dir} for issues with > #{merge_threshold} pages..."

      log = File.open("log/dp_#{box}_warn.txt", "w")

      page_cnt = 0
      curr_issue = nil
      bad = 0
      Dir.glob("#{root_dir}/**/*.tif") do |f|
         next if f.include? "AAA - Extras"
         issue_dir = File.dirname(f)
         if curr_issue.nil? || curr_issue != issue_dir
            if page_cnt > merge_threshold
               puts "Issue #{curr_issue} has #{page_cnt} pages"
               log << "Issue #{curr_issue} has #{page_cnt} pages\n"
               bad += 1
            end
            curr_issue = issue_dir
            page_cnt = 0
         end

         page_cnt += 1
      end
      if page_cnt > merge_threshold
         puts "Issue #{curr_issue} has #{page_cnt} pages"
         log << "Issue #{curr_issue} has #{page_cnt} pages\n"
         bad += 1
      end

      puts "===> TOTAL issues found: #{bad}"
      log <<  "===> TOTAL issues found: #{bad}"
      log.close
   end
end
