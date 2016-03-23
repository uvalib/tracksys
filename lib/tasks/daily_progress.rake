#encoding: utf-8

namespace :daily_progress do

   desc "Ingest unit from archive using active messaging"
   task :ingest_unit => :environment do
      id = ENV['id']
      raise "ID is required" if id.nil?
      unit = Unit.find(id)

      include ActiveMessaging::MessageSender

      puts "   => Start ingest for unit #{unit.id}:#{unit.special_instructions}"
      message = ActiveSupport::JSON.encode( { :unit_id => "#{unit.id}" })
      Object.publish :start_ingest_from_archive, message
   end

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

   desc "ingest daily progress issues (src=src_dir, box=nn, fedora=Y/N [OPTIONAL, default Y], set=yyyymmdd/yyyymm/yyyy, order=order_id [OPTIONAL, default 5341])"
   task :ingest => :environment do
      src = ENV['src']
      box_num = ENV['box']
      target = ENV['set']
      raise "src is required!" if src.nil?
      raise "box is required!" if box_num.nil?
      raise "set is required!" if target.nil?
      box = "Box#{box_num}"
      legacy = false
      legacy = true if !ENV['legacy'].nil?

      if legacy == true
         include ActiveMessaging::MessageSender
         ARCHIVE_DIR = "/lib_content44/RMDS_archive/CheckSummed_archive"
         puts "** USING ACTIVE MESSAGING AND ARCHIVE #{ARCHIVE_DIR} **"
      end

      # extract target issue, month or year
      tgt_type = :issue
      tgt_type = :year if target.length == 4
      tgt_type = :year_month if target.length == 6
      puts "Ingest Daily progress #{tgt_type} #{target}"

      # optional params
      ingest = !(ENV['fedora'] == 'N' || ENV['fedora'] == 'n')
      order_id = ENV['order']
      order_id = 5341 if order_id.nil?

      # Get the daily progress order, top level component and other required objects
      order = Order.find(order_id)
      bibl = Bibl.find(15226)
      dp_component = Component.find(497769)
      series = ComponentType.where(name:'series').first
      subseries = ComponentType.where(name:'subseries').first
      item = ComponentType.where(name:'item').first

      # read all previously ingested issues into an array
      log = File.open("log/daily_progress/dp_#{box}_ingested.txt", "r")
      contents = log.read
      log.close
      already_ingested = contents.split("\n")
      skip_logged = []

      # open log file for writing newly ingested issues
      log = File.open("log/daily_progress/dp_#{box}_ingested.txt", "a")

      # Set top level directory for images to be 'Daily Progress/BoxNN'
      # Expected structure:
      #   ./Daily Progress/BoxNN/Date From-Date To/Issue Date (YYYYMMDD)/page images (00001.tif)
      root_dir = File.join(src, "Daily_Progress/#{box}")
      raise "Source directory does not exist!" if !Dir.exist? root_dir
      years = {}
      months = {}
      curr_issue = nil
      curr_issue_date = ""
      issue_unit = nil
      page_cnt = 0
      skip_issue = false
      issue_date = ""
      puts "Scanning #{root_dir}..."
      Dir.glob("#{root_dir}/**/*.tif").sort.each do |f|

         # Filename like:
         #    lib_content64/Daily_Progress/Box01/Apr 21, 1930 - Sep 6, 1930/19300422/00001.tif
         parts = f.split("/")
         tif = parts[parts.length-1]         # format: 0-padded pagenumber .tif
         pagenum = tif.split(".")[0].to_i    # convert to integer
         issue_date = parts[parts.length-2]  # format: YYYYMMDD

         # If a specific issue has been flagged, skip all others
         next if tgt_type == :issue && issue_date != target

         # Skip issue directories that are not 8 digits (YYYYMMDD)
         if (/^\d{8}$/ =~ issue_date).nil?
            if !skip_logged.include?(issue_date)
               skip_logged << issue_date
               puts "* Invalid issue name '#{issue_date}', SKIPPING"
            end
            next
         end

         # SKIP if a tgt year is specified and this is not a match
         year = issue_date[0...4]
         next if tgt_type == :year &&  year != target

         # SKIP if year/month is specified and this is not a match
         year_month = issue_date[0...6]
         next if tgt_type == :year_month &&  year_month != target

         # SKIP if this issue is already on the ingested list
         if already_ingested.include? issue_date
            if !skip_logged.include?(issue_date)
               skip_logged << issue_date
               puts "* Issue #{issue_date} already ingested, SKIPPING"
            end
            next
         end

         # parse out reel info to add as a content_desc for the issue Item compobent
         date_range = parts[parts.length-3]
         box = parts[parts.length-4]
         legacy_fn = "#{date_range}/#{issue_date}/#{tif}"

         # construct the component hierarchy based on the issue date
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

            if !curr_issue_date.empty?
               # ingest the previous issue unit, if one exists
               log << "#{curr_issue_date}\n"
               if ingest
                  puts "   => Start ingest for unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{page_cnt} master files"
                  if legacy == true
                     message = ActiveSupport::JSON.encode( { :unit_id => "#{issue_unit.id}" })
                     Object.publish :start_ingest_from_archive, message
                  else
                     StartIngestFromArchive.exec_now( { :unit_id => "#{issue_unit.id}" })
                  end
               end
            end

            curr_issue_date = issue_date
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
               issue_unit.archive_id = 5 if legacy = true
               issue_unit.index_destination_id = 3    # virgo
               issue_unit.indexing_scenario_id = 1    # default
               issue_unit.availability_policy_id = 1  # public
               issue_unit.intended_use_id = 110       # Digital collection building
               issue_unit.special_instructions = "Reel: #{date_range}\nIssue: #{issue}".gsub(/,/,'')
               issue_unit.staff_notes = "From #{box}"
               issue_unit.unit_status = 'approved'
               issue_unit.bibl = bibl
               issue_unit.save!
               page_cnt = 0
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
         mf.title = pagenum.to_s
         mf.tech_meta_type = "image"
         mf.component = curr_issue
         mf.filename = "%09d" % issue_unit.id + "_" + "%04d" % pagenum + ".tif"
         mf.filesize = File.size(f)
         mf.save!
         page_cnt += 1

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
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % issue_unit.id)
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
         if legacy == true
            ActiveMessaging::MessageSender.publish :create_image_technical_metadata_and_thumbnail, payload.to_json
         else
            CreateImageTechnicalMetadataAndThumbnail.exec_now( payload )
         end
      end

      # ingest the last unit, unless it was already ingested
      if !skip_issue && !issue_unit.nil?
         log << "#{curr_issue_date}\n"
         if ingest
            puts "   => Start ingest for FINAL unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{page_cnt} master files"
            if legacy == true
               message = ActiveSupport::JSON.encode( { :unit_id => "#{issue_unit.id}" })
               Object.publish :start_ingest_from_archive, message
            else
               StartIngestFromArchive.exec_now( { :unit_id => "#{issue_unit.id}" })
            end
         end
      end

      # close out the ingested tracekr
      log.close
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

      log = File.open("log/daily_progress/bad_names/dp_#{box}_bad_issue_name.txt", "w")

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

      log = File.open("log/daily_progress/page_count_warnings/dp_#{box}_warn.txt", "w")

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
