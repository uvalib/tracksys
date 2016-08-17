class CreateDlManifest < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:staff_member].id)
   end

   def do_workflow(message)

      send_email = message[:deliver]
      send_email = true if send_email.nil?
      staff_member = message[:staff_member]

      report_file = create_workbook()

      if send_email
         ReportMailer.send_dl_manifest(staff_member).deliver
         File.delete(report_file)
         on_success "DL Manifest emailed to #{staff_member.full_name}."
      else
         on_success "DL Manifest created here: #{report_file}."
      end
   end

   def create_workbook
      filename = "#{Rails.root}/tmp/dl_manifest_#{Time.now.strftime('%Y%m%d')}.xlsx"
      p = Axlsx::Package.new
      p.use_shared_strings = true
      p.workbook do |wb|
         wb.styles do |s|
            @wrap_text_odd = s.add_style :fg_color=> "FFFFFF",
                                   :bg_color => "004586",
                                   :sz => 14,
                                   :border => { :style => :thin, :color => "00" },
                                   :alignment => { :horizontal => :left,
                                                   :vertical => :center,
                                                   :wrap_text => true}

            @wrap_text_even = s.add_style :fg_color=> "FFFFFF",
                                   :bg_color => "3366FF",
                                   :sz => 14,
                                   :border => { :style => :thin, :color => "00" },
                                   :alignment => { :horizontal => :left,
                                                   :vertical => :center,
                                                   :wrap_text => true}

            @header_text = s.add_style  :fg_color => "FFFFFF",
                                       :bg_color => "FF9900",
                                       :sz => 18,
                                       :border => { :style => :thin, :color => "00" },
                                       :alignment => { :horizontal => :center,
                                                       :vertical => :center,
                                                       :wrap_text => true}

            @blue_link = s.add_style :fg_color => '0000FF',
                                   :sz => 14,
                                   :border => { :style => :thin, :color => "00" },
                                   :alignment => { :horizontal => :left,
                                                   :vertical => :center,
                                                   :wrap_text => true}

            @summary_headings = s.add_style :bg_color => "FFCC99",
                                           :fg_color => "004586",
                                           :sz => 20,
                                           :alignment => { :horizontal => :center,
                                                   :vertical => :center,
                                                   :wrap_text => true}

            @summary_subheadings = s.add_style  :fg_color => "FFFFFF",
                                               :bg_color => "FF9900",
                                               :sz => 16,
                                               :alignment => { :horizontal => :center,
                                                   :vertical => :center,
                                                   :wrap_text => true}

            @summary_table_text_content = s.add_style :fg_color => "FFFFFF",
                                                     :bg_color => "004586",
                                                     :sz => 16,
                                                     :alignment => {:horizontal => :left,
                                                       :vertical => :center,
                                                       :wrap_text => true}

            @summary_table_number_content = s.add_style :fg_color => "FFFFFF",
                                                       :bg_color => "004586",
                                                       :sz => 16,
                                                       :num_fmt => 3,
                                                       :alignment => {:horizontal => :right,
                                                         :vertical => :center,
                                                         :wrap_text => true}

            @summary_table_totals = s.add_style :b => true,
                                               :sz => 16,
                                               :num_fmt => 3

            wb.add_worksheet(:name => "Summary") do |sheet|
               sheet.add_row
               sheet.add_row [nil, "Summary Information", nil, nil, nil, nil, nil], :style => [nil, @summary_headings, @summary_headings]
               sheet.merge_cells("B2:F2")
               sheet.add_row

               # Image Counts
               public_image_count = MasterFile.in_digital_library.joins(:metadata).where("metadata.availability_policy_id = 1").count
               uva_only_image_count = MasterFile.in_digital_library.joins(:metadata).where("metadata.availability_policy_id = 3").count
               total_image_count = MasterFile.in_digital_library.count

               # Metadata Record Counts
               public_metadata_record_count = Metadata.in_digital_library.where(:discoverability => true).where(:availability_policy_id => 1).count
               uva_only_metadata_record_count = Metadata.in_digital_library.where(:discoverability => true).where(:availability_policy_id => 3).count
               total_metadata_count = Metadata.in_digital_library.count

               sheet.add_row [nil, "Image Counts", nil, nil, "Catalog Record Counts", nil, nil], :style => [nil, @summary_subheadings, @summary_subheadings, nil, @summary_subheadings, @summary_subheadings, nil]
               sheet.add_row [nil, "Public", "#{public_image_count}", nil, "Public", "#{public_metadata_record_count}", nil], :style => [nil, @summary_table_text_content, @summary_table_number_content, nil, @summary_table_text_content, @summary_table_number_content, nil]
               sheet.add_row [nil, "UVA Only", "#{uva_only_image_count}", nil, "UVA Only", "#{uva_only_metadata_record_count}", nil], :style => [nil, @summary_table_text_content, @summary_table_number_content, nil, @summary_table_text_content, @summary_table_number_content, nil]
               sheet.add_row [nil, "Total", "#{total_image_count}", nil, "Total", "#{total_metadata_count}", nil], :style => [nil, @summary_table_totals, @summary_table_totals, nil, @summary_table_totals, @summary_table_totals, nil]
               sheet.merge_cells("B4:C4")
               sheet.merge_cells("E4:F4")

               # Growth of Digital Images Chart
               first_ingest_mf = MasterFile.select(:date_dl_ingest).where('date_dl_ingest is not null').order(:date_dl_ingest).first
               if !first_ingest_mf.nil?
                  earliest_date = first_ingest_mf.date_dl_ingest
                  current_month = Time.new(earliest_date.year, earliest_date.month)
                  months = Array.new
                  totals = Array.new
                  total = 0
                  while current_month <= Time.now.beginning_of_month
                     count = MasterFile.select(:date_dl_ingest).where("MONTH(date_dl_ingest) = ? and YEAR(date_dl_ingest) = ?", current_month.month, current_month.year).count
                     # sheet.add_row [nil, "#{current_month.strftime('%B %Y')}", "#{count}" ]
                     months << "#{current_month.strftime('%B %Y')}"
                     total = total + count
                     totals << total
                     current_month = current_month.next_month
                  end
               end

               sheet.add_chart(Axlsx::Bar3DChart, :start_at => [1,21], :end_at => [6, 47], :title => "Growth of Digital Images") do |chart|
                  chart.bar_dir = :bar
                  chart.show_legend = false
                  chart.add_series :data => totals, :labels => months, :title => 'Months'
               end

               sheet.add_chart(Axlsx::Pie3DChart, :start_at => [1,8], :end_at => [3,20], :title => "Image Counts") do |chart|
                  chart.add_series :data => sheet["C5:C6"], :labels => sheet["B5:B6"]
                  chart.d_lbls.show_val = true
               end

               sheet.add_chart(Axlsx::Pie3DChart, :start_at => [4,8], :end_at => [6, 20], :title => "Catalog Record Counts") do |chart|
                  chart.add_series :data => sheet["F5:F6"], :labels => sheet["E5:E6"]
                  chart.d_lbls.show_val = true
               end

               sheet.column_info[0].width = 2
               sheet.column_info[1].width = 25
               sheet.column_info[2].width = 12
               sheet.column_info[3].width = 10
               sheet.column_info[4].width = 25
               sheet.column_info[5].width = 12
               sheet.column_info[6].width = 2
            end

            generate_worksheet(wb, 'Publicly Available', Metadata.in_digital_library.where(:discoverability => true).where(:availability_policy_id => 1))
            generate_worksheet(wb, 'UVA Only', Metadata.in_digital_library.where(:discoverability => true).where(:availability_policy_id => 3))
         end
         p.use_autowidth = false
         s = p.to_stream()
         File.open(filename, 'w') { |f| f.write(s.read) }
      end
      return filename
   end

  # Helper method for creating DL Manifest XLS file
  def generate_worksheet(wb, name, metadata_records)
     wb.add_worksheet(:name => name) do |sheet|
        row_number = 2 # Since title row is 1, we start at 2.
        sheet.add_row ['Title', 'Author', 'Call Number', 'Date Created', '# of images', 'Date Ingested', 'Link'], :style => @header_text
        metadata_records.each do |md|
           call_number = "N/A"
           year = "N/A"
           if md.type == "SirsiMetadata"
             smd = md.becomes(SirsiMetadata)
             call_number = smd.call_number
             year = smd.get_full_metadata[:year]
           end
           style = row_number.odd? ? @wrap_text_even : @wrap_text_odd
           row = sheet.add_row [
             "#{md.title}", "#{md.creator_name}", "#{call_number}", "#{year}", "#{md.master_files.in_digital_library.count}",
             "#{md.date_dl_ingest.strftime('%Y-%m-%d')}", "VIRGO"], :style => style
           sheet.add_hyperlink :location => "http://search.lib.virginia.edu/catalog/#{md.pid}", :ref => "G#{row.row_index + 1}"
           sheet["G#{row.row_index + 1}"].style = @blue_link
           row_number += 1
        end
        sheet.column_info[0].width = 60 # Title
        sheet.column_info[1].width = 35 # Author
        sheet.column_info[2].width = 30 # Call Number
        sheet.column_info[3].width = 12 # Date Created
        sheet.column_info[4].width = 10 # Number of Images
        sheet.column_info[5].width = 15 # Date Ingested
        sheet.column_info[6].width = 10 # Link
     end
  end
end
