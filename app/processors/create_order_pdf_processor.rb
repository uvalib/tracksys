  # Create a PDF file the contains all order metadata.  Each unit of digitization is enumerate with its Bibl records, citation statement,
# Component records, EADRef references and a list of the MasterFile images with their individual metadata.

class CreateOrderPdfProcessor < ApplicationProcessor

  subscribes_to :create_order_pdf, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :check_order_delivery_method
  
  require 'prawn'
  
  def on_message(message)
    logger.debug "CreateOrderPdfProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    
    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    raise "Parameter 'fee' is required" if hash[:fee].blank?

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @fee = hash[:fee]
    @customer = @working_order.customer

    @units_in_pdf = Array.new
    @working_order.units.each { |unit|        
      if unit.unit_status == 'approved'
       	@units_in_pdf.push(unit)
      end
    }

    @pdf = Prawn::Document.new
    @pdf.font "Helvetica", :encoding => nil
    @pdf.image "#{RAILS_ROOT}/app/assets/images/lib_letterhead.jpg", :position => :center, :width => 500
    @pdf.text "Digital Curation Services,  University of Virginia Library", :align => :center
    @pdf.text "Post Office Box 400155, Charlottesville, Virginia 22904 U.S.A.", :align => :center
    @pdf.text "\n\n"
    @pdf.text "Order ID: #{@working_order.id}", :align => :right, :font_size => 14
    @pdf.text "\n"
    @pdf.text "Dear #{@customer.first_name.capitalize} #{@customer.last_name.capitalize}, \n\n"  
    
    if @units_in_pdf.length > 1
      @pdf.text "On #{@working_order.date_request_submitted.strftime("%B %d, %Y")} you placed an order with Digitzation Services of the University of Virginia Library.  Your request comprised #{@units_in_pdf.length} items.  Below you will find a description of your digital order and how to cite the material for publication."
    else
      @pdf.text "On #{@working_order.date_request_submitted.strftime("%B %d, %Y")} you placed an order with Digitzation Services of the University of Virginia Library.  Your request comprised #{@units_in_pdf.length} item.  Below you will find a description of your digital order and how to cite the material for publication."
    end
    @pdf.text "\n"
    if not @fee.to_i.eql?(0)
      @pdf.text "Our records show that you accepted a fee of $#{@fee.to_i} for this order. This fee must be paid within 30 days.  Please write a check in the above amount made payable to <i>Rector and Board of Visitors of the University of Virginia</i> and send it to the following address:", :inline_format => true
      @pdf.text "\n"
      @pdf.text "Digital Curation Services", :left => 100
      @pdf.text "University of Virginia Library", :left => 100
      @pdf.text "Post Office Box 400155", :left => 100
      @pdf.text "Charlottesville, Virginia 22904  U.S.A", :left => 100
    end

    @pdf.text "Sincerely,", :left => 350
    @pdf.text "\n"
    @pdf.text "Digitization Services Staff", :left => 350
    # End cover page

    # Begin first page of invoice
    @pdf.start_new_page

    # @pdf.open_object do |heading| 
    #   @pdf.save_state 
    #   @pdf.stroke_color! Color::Black 
    #   @pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT 
    #   s = 10
    #   if not @fee.eql?("none")
    #     t = "Invoice For Order #{@working_order.id}" 
    #   else
    #     t = "Receipt for Order #{@working_order.id}"
    #   end
    #   w = @pdf.text_width(t, s) / 2.0 
    #   x = @pdf.margin_x_middle 
    #   y = @pdf.absolute_top_margin 
    #   @pdf.add_text(x - w, y, t, s)
    #   x = @pdf.absolute_left_margin 
    #   w = @pdf.absolute_right_margin 
    #   y -= (@pdf.font_height(s) * 1.01) 
    #   @pdf.line(x, y, w, y).stroke 
    #   @pdf.restore_state 
    #   @pdf.close_object 
    #   @pdf.add_object(heading, :all_pages)
    # end

    # # The letter sized document is 612 x 792
    # @pdf.start_page_numbering(550, 25, 10)

    @pdf.text "\n"
    @pdf.text "Digital Order Summary", :align => :center, :font_size => 16
    @pdf.text "\n"

    # Iterate through all the units belonging to this order
    @units_in_pdf.each { |unit|       
      # For pretty printing purposes, create pagebreak if there is less than 10 lines remaining on the current page.
      @pdf.start_new_page unless @pdf.cursor > 30

      # Add 1 to incrementation because index starts at 0
      item_number = @units_in_pdf.index(unit) + 1

      @pdf.text "Item ##{item_number}:", :font_size => 14
      @pdf.text "\n"

      # Begin work on Bibl record
      #
      # Output all present fields in Bibl record.  Almost all values in Bibl aoptional, so tests are required.
      @pdf.text "Title: #{unit.bibl.title}", :left => 14 unless unit.bibl.title?
      @pdf.text "Author: #{unit.bibl.creator_name}", :left => 14 unless unit.bibl.creator_name?
      @pdf.text "Call Number: #{unit.bibl.call_number}", :left => 14 unless unit.bibl.call_number?
      @pdf.text "Copy: #{unit.bibl.copy}", :left => 14 unless unit.bibl.copy?
      @pdf.text "Volume: #{unit.bibl.volume}", :left => 14 unless unit.bibl.volume?
      @pdf.text "Issue: #{unit.bibl.issue}", :left => 14 unless unit.bibl.issue?
      @pdf.text "\n"

      # Begin work on citation
      # When bibl records are created, there is new logic (as of 9/21/2010) to harvest the marc 524 field.  Commonly Special
      # Collections staff write a canonical citation statement here.  Therefore, if bibl.citation exists, this PDF creation
      # processor will use that.  Otherwise, it will create a citation from a template created in consultation with jcp5x.

      @pdf.text "Please cite this item as follows: \n\n", :left => 10

      if not unit.bibl.citation.blank?
        @pdf.text "#{unit.bibl.citation}", :left => 10
      else
        # Create and manage a Hash that contains the SIRSI location codes and their human readable values for citation purposes
        location_hash = Hash.new
        location_hash = {
          "ALD-STKS" => "Alderman Library, University of Virginia Library.", 
          "ASTRO-STKS" => "Astronomy Library, University of Virginia Library.",
          "DEC-IND-RM" => "Albert H. Small Declaration of Independence Collection, Special Collections, University of Virginia Library.",
          "FA-FOLIO" => "Fiske Kimball Fine Arts Library, University of Virginia Library.",
          "FA-OVERSIZE" => "Fiske Kimball Fine Arts Library, University of Virginia Library.",
          "FA-STKS" => "Fiske Kimball Fine Arts Library, University of Virginia Library.",
          "GEOSTAT" => "Alderman Library, University of Virginia Library.",
          "HS-CABELJR" => "Health Sciences Library, University of Virginia Library.",
          "HS-RAREOVS" => "Health Sciences Library, University of Virginia Library.",
          "HS-RARESHL" => "Health Sciences Library, University of Virginia Library.",
          "HS-RAREVLT" => "Health Sciences Library, University of Virginia Library.",
          "IVY-BOOK" => "Ivy Annex, University of Virginia Library.",
          "IVY-STKS" => "Ivy Annex, University of Virginia Library.",
          "IVYANNEX" => "Ivy Annex, University of Virginia Library." ,
          "LAW-IVY" => "Law Library, University of Virginia Library.",
          "SC-ARCHV" => "Special Collections, University of Virginia Library.",
          "SC-ARCHV-X" => "Special Collections, University of Virginia Library.",
          "SC-BARR-F" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-FF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-M" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-RM" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-ST" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-X" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-XF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARR-XZ" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-BARRXFF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia Library.",
          "SC-GARN-F" => "Garnett Family Library, Special Collections, University of Virginia Library.",
          "SC-GARN-RM" => "Garnett Family Library, Special Collections, University of Virginia Library.",
          "SC-IVY" => "Special Collections, University of Virginia Library.",
          "SC-MCGR-F" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-FF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-RM" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-ST" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-X" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-XF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGR-XZ" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-MCGRXFF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia Library.",
          "SC-REF" => "Special Collections, University of Virginia Library.",
          "SC-REF-F" => "Special Collections, University of Virginia Library.",
          "SC-SCOTT" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTT-F" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTT-M" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTT-X" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTTFF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTTXF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-SCOTTXZ" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia Library.",
          "SC-STKS" => "Special Collections, University of Virginia Library.",
          "SC-STKS-D" => "Special Collections, University of Virginia Library.",
          "SC-STKS-EF" => "Special Collections, University of Virginia Library.",
          "SC-STKS-F" => "Special Collections, University of Virginia Library.",
          "SC-STKS-FF" => "Special Collections, University of Virginia Library.",
          "SC-STKS-M" => "Special Collections, University of Virginia Library.",
          "SC-STKS-X" => "Special Collections, University of Virginia Library.",
          "SC-STKS-XF" => "Special Collections, University of Virginia Library.",
          "SC-STKS-XZ" => "Special Collections, University of Virginia Library.",
          "SC-STKSXFF" => "Special Collections, University of Virginia Library.",
          "SC-TATUM" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUM-F" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUM-M" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUM-X" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUMFF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUMXF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SC-TATUMXZ" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia Library.",
          "SPEC-COLL" => "Special Collections, University of Virginia Library.",
          "STACKS" => "Special Collections, University of Virginia Library.",
          "Reading Room" => "Special Collection, University of Virginia Libary"
        }
      

        # Get citation location by comparing Bibl value against location Hash
        # If citation does not exist in the hash, and the bibl.is_in_catalog is true, put boilerplate Library statement
        # If citation does not exist in the hash and the bibl.is_in_catalog is false, put nothing.

        if location_hash.has_key?(unit.bibl.location)
          citation_location = location_hash.fetch(unit.bibl.location)
          @pdf.text "#{unit.bibl.title} (#{unit.bibl.call_number}). #{citation_location}", :left => 10
        else
          if unit.bibl.is_in_catalog
            @pdf.text "#{unit.bibl.title} (#{unit.bibl.call_number}). University of Virginia Library.", :left => 10      
          else  
            @pdf.text "#{unit.bibl.title} (#{unit.bibl.call_number}).", :left => 10      
          end
        end
      end

      @pdf.text "\n"

      # Create special tables to hold component information
      if unit.components.any?
        unit.components.each do |component|
          # Output information for this unit using the Component template
          output_component_data(component)
        end
      else
        # Output information using the MasterFile only template.
        output_masterfile_data(unit.master_files.order(:filename))
      end
    }

    # Page numbering
    string = "page <page> of <total>"
    options = { :at => [@pdf.bounds.right - 150, 0],
              :width => 150,
              :align => :right,
              :start_count_at => 1 }
    @pdf.number_pages string, options

    # Write out the file
    @pdf.render_file(File.join("#{ASSEMBLE_DELIVERY_DIR}", "order_#{@order_id}", "#{@order_id}.pdf"))

    # Publish message
    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :check_order_delivery_method, message
    on_success "PDF created for order #{@order_id}."
  end 

  # Physical Component Methods
  def output_component_data(component)
    component.ancestor_ids.each {|component_id|
      c = Component.find(component_id)
      data = Array.new
      data = [["Title", "Description", "Date"]]
      data += [["#{component.name}", "#{component.content_desc}", "#{component.date}"]]

      @pdf.table(data, :column_widths => [140,200,200], :header => true, :row_colors => ["F0F0F0", "FFFFCC"])         
      @pdf.text "\n"

      if @pdf.cursor < 30
        @pdf.start_new_page
      end

      @pdf.text "\n"
    }

    output_masterfile_data(component.master_files.order(:filename))

    # data = [{"label"=> "#{component.label}", "desc"=> "#{component.content_desc}", "date"=> "#{component.date}", "barcode"=> "#{component.barcode}", "sequence_number"=> "#{component.seq_number}"}]
          
    # table = PDF::SimpleTable.new
    # table.title = "#{component.component_type.name.capitalize}"
    # table.column_order.push(*%w(label desc date barcode sequence_number))

    # table.columns["label"] = PDF::SimpleTable::Column.new("label")
    # table.columns["label"].heading = "Label"
    # table.columns["label"].width = 200
  
    # table.columns["desc"] = PDF::SimpleTable::Column.new("desc")
    # table.columns["desc"].heading = "Description"
    # table.columns["desc"].width = 100
      
    # table.columns["date"] = PDF::SimpleTable::Column.new("date")
    # table.columns["date"].heading = "Date"
    # table.columns["date"].width = 75
      
    # table.columns["barcode"] = PDF::SimpleTable::Column.new("barcode")
    # table.columns["barcode"].heading = "Barcode"
    # table.columns["barcode"].width = 75
      
    # table.columns["sequence_number"] = PDF::SimpleTable::Column.new("sequence_number")
    # table.columns["sequence_number"].heading = "Sequence Number"
    # table.columns["sequence_number"].width = 100    

    # table.show_lines = :all
    # table.show_headings = true
    # table.orientation = :right
    # table.position = :left
     
    # table.data.replace data

    # # Create pagebreak if necessary
    # if @pdf.lines_remaining < 10
    #   @pdf.start_new_page
    # end

    # table.render_on(@pdf)
    # @pdf.text "\n"   
  end

  # def check_for_component_masterfiles(component)
  #   if not component.master_files.empty?
  #     sorted_master_files = component.master_files.sort_by {|mf|
  #       mf.filename
  #     }
  #     output_masterfile_data(sorted_master_files)
  #   end
  # end

  # def check_for_child_components(component)
  #   if not component.child_components.empty?
  #     component.child_components.each{|component|
  #       output_component_data(component)
  #       check_for_component_masterfiles(component)
  #       check_for_child_components(component)
  #       output_null_text_component(component)
  #       }
  #   end
  # end

  # def output_null_text_component(component)
  #   if component.child_components.empty? and component.master_files.empty?
  #     @pdf.text "There are no master files or physical housing information at this level.", :align => :center
  #   end
  # end


  # Methods used by both Component and EAD Ref methods
  def output_masterfile_data(sorted_master_files)
    data = Array.new
    data = [["Filename", "Title", "Description"]]
    sorted_master_files.each {|master_file|
      data += [["#{master_file.filename}", "#{master_file.title}", "#{master_file.description}"]]
    }
    @pdf.table(data, :column_widths => [140,200,200], :header => true, :row_colors => ["F0F0F0", "FFFFCC"])         
    @pdf.text "\n"

    if @pdf.cursor < 30
      @pdf.start_new_page
    end

    @pdf.text "\n"
  end
end
