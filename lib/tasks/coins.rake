require 'open-uri'
require "rmagick"

namespace :coins do
   SITE_ROOT = "http://coins.lib.virginia.edu"
   COLLECTION_TITLE = "Fralin Numismatic Collection"

   desc "Setup for ingest; create order,unit and metadata"
   task :setup => :environment do
      customer = Customer.find_by(email: "lf6f@virginia.edu")

      order = Order.find_by(order_title: COLLECTION_TITLE)
      if order.nil?
         puts "Creating order"
         today = DateTime.now
         order = Order.create(order_title: COLLECTION_TITLE, order_status: "approved",
            staff_notes: "Order to ingest Fralin coins collection",
            date_request_submitted: today, date_due: "2017-12-31",
            customer: customer, is_approved: true, date_order_approved: today
         )
      else
         puts "Using existing order #{order.id}"
      end

      if order.units.count == 0
         xml = XmlMetadata.find_by(title: COLLECTION_TITLE)
         if xml.nil?
            metadata  = '<?xml version="1.0" encoding="UTF-8"?>\n'
            metadata << '<mods xmlns="http://www.loc.gov/mods/v3"\n'
            metadata << '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
            metadata << '    xmlns:mods="http://www.loc.gov/mods/v3"\n'
            metadata << '    xsi:schemaLocation="http://www.loc.gov/mods/v3\n'
            metadata << '    http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">\n'
            metadata << '   <titleInfo>\n'
            metadata << "      <title>#{COLLECTION_TITLE}</title>\n"
            metadata << '   </titleInfo>\n'
            metadata << '</mods>'
            puts "Create XML metadata for collection"
            xml = XmlMetadata.create(title: COLLECTION_TITLE, is_approved: true, discoverability: false,
               availability_policy_id: 1, dpla: false, resource_type_id: 7, ocr_hint_id: 2,
               desc_metadata: metadata, use_right_id: 2
            )
         else
            puts "Using existing collection XML metadata #{xml.id}"
         end

         unit = Unit.create(
            metadata: xml, unit_status: "approved", order: order,
            intended_use_id: 110, staff_notes: "Unit for #{COLLECTION_TITLE}", include_in_dl: 0
         )
         puts "Created unit. Setup is complete."
      else
         puts "Order already has a unit. Setup is complete"
      end
   end

   desc "Ingest coins XML and scrape JPG from website"
   task :ingest  => :environment do
      base_dir = ENV['dir']
      abort("dir is required") if base_dir.blank?
      order = Order.find_by(order_title: COLLECTION_TITLE)
      abort("Order named #{COLLECTION_TITLE} not found") if order.nil?

      # pull unit from order (there is only one)
      unit = order.units.first
      tmp_dir = "#{Rails.root}/tmp"
      unit_fn = "%09d" % unit.id

      unit_archive_dir = File.join(ARCHIVE_DIR, unit_fn)
      if !Dir.exist? unit_archive_dir
         puts "Creating unit directory in the archive"
         FileUtils.makedirs(unit_archive_dir)
         FileUtils.chmod(0775, unit_archive_dir)
      end

      file_num = 1
      Dir.glob( File.join(base_dir, "coins_xml", "*.xml")).each do |xml_file|
         puts "Processing #{File.basename(xml_file)}..."
         doc = Nokogiri.XML( File.open(xml_file))
         doc.remove_namespaces!
         xml = doc.root
         title = xml.xpath("/nuds/descMeta/title").text

         # Find or create metadata with matching title
         md = XmlMetadata.find_by(title: title)
         if md.nil?
            puts "Creating XML Metadata record for #{title}..."
            md = XmlMetadata.create!(
               title: title, desc_metadata: xml.to_s, is_approved: 1, discoverability: 1, availability_policy_id: 1,
               dpla: 0, resource_type_id: 7, ocr_hint_id: 2, use_right_id: 2
            )
         else
            puts "Using existing meatdata record for #{title}"
         end

         # Process images for each side of the coin...
         ["obverse", "reverse"].each do |side|
            # Find key bits of data in the XML; legend (title), description and HREF
            legend = xml.xpath("/nuds/descMeta/typeDesc/#{side}/legend").text
            desc = xml.xpath("/nuds/descMeta/typeDesc/#{side}/type/description").text
            side_uri = xml.xpath("/nuds/digRep/fileSec/fileGrp[@USE='#{side}']/file[@USE='master']/FLocat/@href").text

            puts "Downloading #{side} image from ./#{side_uri}..."
            num_str = "%04d" % file_num
            jpg_filename = "#{unit_fn}_#{num_str}.jpg"
            filename = jpg_filename.gsub(/.jpg/, ".tif")
            jpg_dest_fn = File.join(tmp_dir, jpg_filename)
            open(jpg_dest_fn, 'wb') do |file|
              file << open("#{SITE_ROOT}/#{side_uri}").read
            end

            # make jpg into a tif. This makes the coins collection consistent
            # with other collections and makes it easier to send to IIIF
            puts "Convert source .jpg to .tif..."
            dest_fn = jpg_dest_fn.gsub(/.jpg/, ".tif")
            cmd = "convert #{jpg_dest_fn} #{dest_fn}"
            `#{cmd}`

            # Get some file stats
            md5 = Digest::MD5.hexdigest(File.read(dest_fn))
            fsz = File.size(dest_fn)

            # Create master file and tie to unit / MD
            mf = MasterFile.find_by(filename: filename)
            if mf.nil?
               puts "Create master file for #{filename}"
               mf = MasterFile.create!(
                  unit: unit, metadata: md, filename: filename, title: legend,
                  description: desc, filesize: fsz, md5: md5)
            else
               puts "Using existing master file #{filename}"
            end

            if mf.image_tech_meta.nil?
               puts "Creating tech metadata for the master file"
               TechMetadata.create(mf, dest_fn)
            else
               puts "Tech metadata already exists for this master file"
            end

            # send to IIIF server (converting to jp2k)
            publish_to_iiif(mf, dest_fn)

            # send to archive
            archive_coins_file(unit_archive_dir, mf, dest_fn)

            # delete tmp file
            puts "Cleaning up temp files"
            FileUtils.rm(dest_fn)
            FileUtils.rm(jpg_dest_fn)

            file_num +=1
         end
      end
      unit.update(master_files_count: file_num-1)
      puts "DONE. #{file_num-1} files ingested."
   end

   def archive_coins_file(archive_dir, master_file, src_img_path)
      puts "Sending source [#{src_img_path}] to archive [#{archive_dir}]..."
      filename = File.basename src_img_path
      archive_file = File.join(archive_dir, filename)
      FileUtils.copy(src_img_path, archive_file)
      FileUtils.chmod(0664, archive_file)
      dest_md5 = Digest::MD5.hexdigest(File.read(archive_file) )
      if dest_md5 != master_file.md5
         puts "WARNING: MD5 mismatch for #{archive_file}"
      end
      master_file.update(date_archived: Time.now)
   end
end
