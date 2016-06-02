#encoding: utf-8

namespace :daily_progress do

   desc "Fix archived dates"
   task :fix_archived_dates => :environment do
      Unit.where(order_id: 5341, date_archived: nil).each do |u|
         puts u.special_instructions.split("\n")[1]
         timestamp = DateTime.now
         u.date_archived = timestamp
         u.save
         u.master_files.each do |mf|
           mf.date_archived = timestamp
           mf.save
         end
      end
   end

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

   desc "Update SOLR for somponent. Cascade to children"
   task :update_solr_datastreams => :environment do
      component_id = ENV['id']
      puts "Update SOLR for component ID: #{component_id}"
      include ActiveMessaging::MessageSender
      c = Component.find(component_id)
      message = ActiveSupport::JSON.encode(  {
         :cascade=>true, :object_class => "Component", :object_id => component_id, :datastream => "solr_doc" } )
      Object.publish :update_fedora_datastreams, message
   end

#   desc "Update image tech meta for all MF in a UNIT"
#   task :update_tech_meta => :environment do
#      u_id = ENV['id']
#      puts "Update tech meta for UNIT ID: #{u_id}"
#      include ActiveMessaging::MessageSender
#      u = Unit.find(u_id)
#      u.master_files.each do |mf|
#         puts "   update MF #{mf.id}"
#         message = ActiveSupport::JSON.encode(  {
#            :object_class => "MasterFile", :object_id => mf.id, :datastream => "tech_metadata" } )
#         Object.publish :update_fedora_datastreams, message
#      end
#   end

   # NOTE This is here because approximately 4000 pages from box04 (1951-1953) do not
   # have a technicalMetadata stream in Fedora. Cause was asynchronous processing. Generating
   # thumbnail and metadata in tracksys was in one message queue, and the process that extracted
   # it for fedora in another. Generation is slow, so that queue fell behind. Process to
   # extract for fedora was serviced first, and there was no data to harvest. I've Since
   # made this synchronous to eliminate the problem.
   #
   # This task can be used to fix one year at a time by passing that years component ID.
   # year 1951: 512824, year 1952: 512579, year 1953: 512661
   #
   desc "Update image tech meta for all MF in a YEAR"
   task :update_tech_meta => :environment do
      id = ENV['id']
      puts "Update tech meta for Year component ID: #{id}"
      include ActiveMessaging::MessageSender
      cnt = 0
      yc = Component.find(id)
      yc.children.each do |mc|
         mc.children.each do |mdc|
            puts mdc.title
            mdc.master_files.each do |mf|
               puts "   #{mf.filename}"
               cnt += 1
               message = ActiveSupport::JSON.encode(  {
                  :object_class => "MasterFile", :object_id => mf.id, :datastream => "tech_metadata" } )
               Object.publish :update_fedora_datastreams, message
               sleep 0.2
            end
         end
      end
      puts "TOTAL: #{cnt}"
   end

   def update_followed_by(parent_component, new_component )
      prior = nil
      linked = false
      update_rels_ext = []
      parent_component.children.order("date asc").each do |c|
         if linked
            puts "Finish linking; #{prior.date} followed by #{c.date}"
            prior.update_attribute(:followed_by_id, c.id)
            update_rels_ext << c.id if new_component.id != c.id
            break
         end

         if new_component.date == c.date
            if !prior.nil?
               puts "Set #{prior.date} followed by #{new_component.date}"
               prior.update_attribute(:followed_by_id, new_component.id)
               update_rels_ext << c.id if new_component.id != c.id
            end
            linked = true
         end

         prior = c
      end
      return update_rels_ext
   end

   desc "ingest daily progress issues (src=src_dir, box=nn, folder=date_rnge, fedora=Y/N [OPTIONAL, default Y], set=yyyymmdd/yyyymm/yyyy)"
   task :ingest => :environment do
      src = ENV['src']
      box_num = ENV['box']
      raise "src is required!" if src.nil?
      raise "box is required!" if box_num.nil?
      box = "Box#{box_num}"

      progress_logfile = "log/daily_progress/#{DateTime.now.strftime('%Y%m%d-%H%M%S')}_ingest.txt"
      progress_log = Logger.new(progress_logfile)
      progress_log.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end

      legacy = false
      legacy = true if !ENV['legacy'].nil?

      if legacy == true
         include ActiveMessaging::MessageSender
         ARCHIVE_DIR = "/lib_content44/RMDS_archive/CheckSummed_archive"
         progress_log.info "** USING ACTIVE MESSAGING AND ARCHIVE #{ARCHIVE_DIR} **"
      end

      # extract target issue, month or year if requested
      target = ENV['set']
      if !target.nil?
         tgt_type = :issue
         tgt_type = :year if target.length == 4
         tgt_type = :year_month if target.length == 6
         progress_log.info "Ingest Daily progress #{tgt_type} #{target}"
      else
         tgt_type = :box
         progress_log.info "Ingest ALL data in #{box}"
      end

      # optional params
      ingest = !(ENV['fedora'] == 'N' || ENV['fedora'] == 'n')
      folder = ENV['folder']

      # Get the daily progress order, top level component and other required objects
      order = Order.find(5341)
      bibl = Bibl.find(15226)
      dp_component = Component.find(497769)
      series = ComponentType.where(name:'series').first
      subseries = ComponentType.where(name:'subseries').first
      item = ComponentType.where(name:'item').first

      # read all previously ingested issues into an array
      log_file_name = "log/daily_progress/dp_#{box}_ingested.txt"
      skip_logged = []
      already_ingested = []
      if File.exist? log_file_name
         log = File.open(log_file_name, "r")
         contents = log.read
         log.close
         already_ingested = contents.split("\n")
      end

      # open log file for writing newly ingested issues
      log = File.open(log_file_name, "a")

      # Set top level directory for images to be 'Daily Progress/BoxNN'
      # Expected structure:
      #   ./Daily Progress/BoxNN/Date From-Date To/Issue Date (YYYYMMDD)/page images (00001.tif)
      root_dir = File.join(src, "Daily_Progress/#{box}")
      if !folder.nil?
         root_dir = File.join(root_dir, folder)
      end
      raise "Source directory does not exist!" if !Dir.exist? root_dir
      years = {}
      months = {}
      curr_issue = nil
      curr_issue_date = ""
      update_rels_ext = []
      issue_unit = nil
      page_cnt = 0
      skip_issue = false
      issue_date = ""
      tgt_issue_found = false
      progress_log.info "Scanning #{root_dir}/ ..."
      Dir.glob("#{root_dir}/**/*.tif").sort.each do |f|

         # Filename like:
         #    lib_content64/Daily_Progress/Box01/Apr 21, 1930 - Sep 6, 1930/19300422/00001.tif
         parts = f.split("/")
         tif = parts[parts.length-1]         # format: 0-padded pagenumber .tif
         pagenum = tif.split(".")[0].to_i    # convert to integer
         issue_date = parts[parts.length-2]  # format: YYYYMMDD

         # If a specific issue has been flagged, skip all others
         if tgt_type == :issue && issue_date != target
            # if target issue has been found, we are done
            next if tgt_issue_found == false
            break if tgt_issue_found == true
         else
            tgt_issue_found = true
         end

         # Skip issue directories that are not 8 digits (YYYYMMDD)
         if (/^\d{8}$/ =~ issue_date).nil?
            if !skip_logged.include?(issue_date)
               skip_logged << issue_date
               progress_log.error "* Invalid issue name '#{issue_date}', SKIPPING"
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
               progress_log.info "* Issue #{issue_date} already ingested, SKIPPING"
            end
            next
         end

         # parse out reel info to add as a content_desc for the issue Item compobent
         date_range = parts[parts.length-3]
         box = parts[parts.length-4]
         legacy_fn = "#{date_range}/#{issue_date}/#{tif}"

         # construct the component hierarchy based on the issue date
         if !years.include? year
            progress_log.info "* Find/Create SERIES component for YEAR #{year}"
            year_component = Component.where(date: year, parent_component_id: dp_component.id).first
            if year_component.nil?
               year_component = Component.new
               year_component.discoverability = 0
               year_component.indexing_scenario_id = 1
               year_component.availability_policy_id = 1
               year_component.component_type = series
               year_component.date = year
               year_component.title = "Issues from #{year}"
               year_component.parent_component_id = dp_component.id
               year_component.save!
               update_rels_ext << update_followed_by(dp_component, year_component)
            end
            years[year] = year_component
         else
            year_component = years[year]
         end

         month_num = issue_date[4...6]
         month_str = Date::MONTHNAMES[month_num.to_i]
         month = "#{year}-#{month_num}"
         if !months.include? month
            progress_log.info "* Find/Create SUBSERIES component for YEAR/MONTH #{month}"
            month_component = Component.where(date: month, parent_component_id: year_component.id).first
            if month_component.nil?
               month_component = Component.new
               month_component.discoverability = 0
               month_component.indexing_scenario_id = 1
               month_component.availability_policy_id = 1
               month_component.component_type = subseries
               month_component.date = month
               month_component.title = "Daily Progress Issues from #{month_str} #{year}"
               month_component.parent_component_id = year_component.id
               month_component.save!
               update_rels_ext << update_followed_by(year_component, month_component)
            end
            months[month] = month_component
         else
            month_component = months[month]
         end

         issue = "#{month}-#{issue_date[6...8]}"
         if curr_issue.nil? || curr_issue.date != issue
            content_desc = "From reel #{date_range}"
            content_desc = content_desc.gsub(/,/,'')
            progress_log.info "* Find/Create ITEM component for ISSUE #{issue}. ContentDesc: #{content_desc}"
            skip_issue = false

            if !curr_issue_date.empty?
               # ingest the previous issue unit, if one exists
               log << "#{curr_issue_date}\n"
               issue_unit.date_archived = DateTime.now
               issue_unit.save
               if ingest
                  progress_log.info "   => Start ingest for unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{page_cnt} master files"
                  if legacy == true
                     message = ActiveSupport::JSON.encode( { :unit_id => "#{issue_unit.id}" })
                     Object.publish :start_ingest_from_archive, message
                  else
                     StartIngestFromArchive.exec_now( { :unit => issue_unit })
                  end
               end
            end

            curr_issue_date = issue_date
            curr_issue = Component.where(date: issue, parent_component_id: month_component.id).first
            if curr_issue.nil?
               curr_issue = Component.new
               curr_issue.discoverability = 0
               curr_issue.indexing_scenario_id = 1
               curr_issue.availability_policy_id = 1
               curr_issue.component_type = item
               curr_issue.date = issue
               curr_issue.content_desc = content_desc
               curr_issue.title = "Daily Progress, #{month_str} #{issue_date[6...8]}, #{year}"
               curr_issue.parent_component_id = month_component.id
               curr_issue.save!
               update_rels_ext << update_followed_by(month_component, curr_issue)

               progress_log.info "   *  Create Unit for issue #{issue}"
               issue_unit = Unit.new
               issue_unit.order = order
               issue_unit.archive_id = 5 if legacy == true
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
               progress_log.info "   * Issue already exists, SKIPPING"
               skip_issue = true
            end
         end

         # this issue was already ingested, skip it
         next if skip_issue

         progress_log.info "   - Master file for #{issue_date}: #{tif}"
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
            progress_log.error "   ** Error in copy operation: source file '#{f}' to '#{dest_file}': MD5 checksums do not match"
         else
            mf.md5 = dest_md5
            mf.date_archived = DateTime.now
            mf.save!
         end

         # Create metadata from the file moved above
         payload = {source: dest_file, master_file_id: mf.id, last: 0, quiet: true}
         if legacy == true
            #ActiveMessaging::MessageSender.publish :create_image_technical_metadata_and_thumbnail, payload.to_json
            # EXEC SYNCHRONOUSLY SO INGEST METADATA WILL HAVE TECH METADATA PRESENT
            p = CreateImageTechnicalMetadataAndThumbnailProcessor.new
            p.on_message( payload.to_json )
         else
            CreateImageTechnicalMetadataAndThumbnail.exec_now( payload )
         end
      end

      # ingest the last unit, unless it was already ingested
      if !skip_issue && !issue_unit.nil?
         log << "#{curr_issue_date}\n"
         if ingest
            progress_log.info "   => Start ingest for FINAL unit #{issue_unit.id}:#{issue_unit.special_instructions} containing #{page_cnt} master files"
            if legacy == true
               message = ActiveSupport::JSON.encode( { :unit_id => "#{issue_unit.id}" })
               Object.publish :start_ingest_from_archive, message
            else
               StartIngestFromArchive.exec_now( { :unit => issue_unit })
            end
         end
      end

      # update compnents on either side of newly added components. ex:
      # 1930/03 was added and 1930/02 and 1930/04 already existed. The 02 and 04
      # components need to have their rels_ext updated
      update_rels_ext_datastreams( update_rels_ext.flatten.uniq, legacy )

      # close out the ingested tracekr
      log.close
      progress_log.close
   end

   task :fix => :environment do
      issue_unit = Unit.find(35619)
      mf = MasterFile.find(1278321)
      f = "/lib_content64/Daily_Progress/Box04/Jul 1 - Sep 30 1952/19520730/00018.tif"

         include ActiveMessaging::MessageSender
         ARCHIVE_DIR = "/lib_content44/RMDS_archive/CheckSummed_archive"
         puts "** USING ACTIVE MESSAGING AND ARCHIVE #{ARCHIVE_DIR} **"

      # Move the original file into the archive directory with the new name
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % issue_unit.id)
         FileUtils.makedirs(dest_dir)
         dest_file = File.join(dest_dir, mf.filename )
      puts "Moving #{f} to #{dest_file}"
         FileUtils.copy(f, dest_file)

         # checksum to ensure good copy. Save MD5
         puts "..checksum"
         source_md5 = Digest::MD5.hexdigest(File.read(f))
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
         if source_md5 != dest_md5
            puts "   ** Error in copy operation: source file '#{f}' to '#{dest_file}': MD5 checksums do not match"
         else
            mf.md5 = dest_md5
            mf.date_archived = DateTime.now
            mf.save!
         end

         # Create metadata from the file moved above
         puts "thumb and meta"
         payload = {source: dest_file, master_file_id: mf.id, last: 0}
         ActiveMessaging::MessageSender.publish :create_image_technical_metadata_and_thumbnail, payload.to_json

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
