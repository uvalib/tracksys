class Api::JstorController < ApplicationController

   # Accept A CSV ofr jstor data. Lookup the filenames in the Filename column (col 2) and see if they exist.
   def finalize
      Rails.logger.info params
      out = []
      header = true
      count = 0
      virgo = 0
      tracksys = 0
      unknown = 0
      not_found = 0
      archived = 0
      fnidx = -1
      CSV.parse((params[:file].read)).each do |row|
         out_row = []

         if header
            header = false
            out_row << "Filename"
            out_row << "MasterFile PID"
            out_row << "Virgo URL"
            out_row << "IIIF URL"
            out_row << "Status"
            out << out_row
            row.each do |rn, idx|
               if rn.downcase == "filename"
                  fnidx = idx
                  break
               end
            end
            next
         end

         if fnidx == -1
            render plain: "CSV file is missing the Filename column", status: :bad_request
            return
         end

         count += 1

         csv_filename = row[1]

         base_filename = File.basename(csv_filename, File.extname(csv_filename))
         # Rails.logger.info "Check for masterfile #{base_filename}%"
         mf = MasterFile.where("filename like ?", "#{base_filename}%").first
         if mf.nil?
            Rails.logger.info "Masterfile #{base_filename}% NOT FOUND"
            out_row << csv_filename
            out_row << "N/A"  # not in TS, no PID
            out_row << "N/A"  # not in virgo
            out_row << "N/A"  # not in IIIF

            parts = csv_filename.split("_")
            if parts.length != 2
               Rails.logger.info "#{csv_filename} INVALID FORMAT, MORE OR LESS THN ONE UNDERSCORE"
               out_row << "Unrecognized filename format"
               unknown += 1
               out << out_row
               next
            end

            # Rails.logger.info "Check unit part of filename #{parts[0]}"
            if parts[0].length != 9
               if parts[0].include?("ARCH") || parts[0].include?("BSEL") || parts[0].include?("BSEL") || parts[0].include?("FBJ")|| parts[0].include?("AVRN")
                  archive_file = File.join(ARCHIVE_DIR, "#{parts[0]}", "#{base_filename}.tif")
                  Rails.logger.info "Does #{archive_file} exist?"
                  if File.exist? archive_file
                     out_row << "Archived"
                     archived += 1
                  else
                     out_row << "Not found"
                     not_found += 1
                  end
               else
                  out_row << "Unrecognized filename format"
                  unknown += 1
               end
               out << out_row
               next
            end

            # looks like a valid archive file.... see if it exists
            # Rails.logger.info "#{parts[0]} looks like a valid archive directory"
            archive_file = File.join(ARCHIVE_DIR, "#{parts[0]}", "#{csv_filename.gsub(/jpg/, 'tif')}")
            Rails.logger.info "Does #{archive_file} exist?"
            if File.exist? archive_file
               out_row << "Archived"
               archived += 1
            else
               out_row << "Not found"
               not_found += 1
            end

            out << out_row
         else
            # found master file in tracksys
            out_row << mf.filename
            out_row << mf.pid
            status = ""
            if mf.unit.include_in_dl
               out_row << "https://search.lib.virginia.edu/sources/images/items/#{mf.metadata.pid}"
               status = "Published to Virgo"
               virgo += 1
            else
               status = "Not Published to Virgo"
               out_row << "N/A"
               tracksys += 1
            end
            out_row << "https://iiif.lib.virginia.edu/iiif/#{mf.pid}/full/full/0/default.jpg"
            out_row << status
            out << out_row
         end
      end

      Rails.logger.info "JSTOR SUMMARY: Total #{count} items in CSV. Unknown: #{unknown}, Not Found: #{not_found}, TrackSys: #{tracksys}, Virgo: #{virgo}"
      csv_string = CSV.generate do |csv|
         out.each { |row| csv << row}
      end

      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => params[:file].original_filename)
   end
end
