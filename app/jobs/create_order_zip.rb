class CreateOrderZip < BaseJob

   require 'zip/zip'

   def perform(message)
      Job_Log.debug "CreateOrderZipProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      # Test for existing order*_1.zip file.  Warn staff if present and stop working.
      if File.exist?(File.join("#{DELIVERY_DIR}", "order_#{@order_id}_1.zip"))
         on_error "A .zip archive for Order #{@order_id} already exists."
      end

      dirs = Array.new

      # The filenames will be stored in an array and passed to the create_order_email_processor
      delivery_files = Array.new

      # To alllow for multiple zip archives, we need a variable which holds the incrementation
      part = 1

      # Make path the parent directory of the order's deliverables
      path = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{@order_id}")

      # Add the order's root directory to the array of directories that will be added
      # to the order zip file. Since the order's root is carried in the order number
      # we need to add a blank entry in the array to represent the root.
      dirs.push("")

      # Get all subdirectories of path
      Dir.chdir(path)
      Dir.glob("**/").each {|dir|
         dirs.push(dir)
      }

      # Create template for .zip filename
      zip_filename = "order_#{@order_id}_#{part}.zip"

      # Must add the first file to the delivery_files array up front
      delivery_files.push("#{zip_filename}")

      dirs.each { |dir|
         contents = Dir.entries(File.join("#{path}", "#{dir}"))
         contents.each { |content|

            if not File.directory?("#{content}")
               Zip::ZipFile.open(File.join("#{DELIVERY_DIR}", "#{zip_filename}"), Zip::ZipFile::CREATE) { |zipfile|
                  zipfile.add(File.join("#{@order_id}", "#{dir}", "#{content}"), File.join("#{path}", "#{dir}", "#{content}"))
                  zipfile.commit

                  # If the zip archive is larger than 500MB, create a new archive
                  size = File.size("#{zipfile}")
                  if size > 500.megabyte and not content.to_s == contents.last.to_s
                     part += 1
                     zip_filename = "order_#{@order_id}_#{part}.zip"
                     delivery_files.push("#{zip_filename}")
                  end
               }
            end
         }
      }

      # Must capture the filename of the last file after the zipping process is done.
      delivery_files.each {|delivery_file|
         File.chmod(0664, File.join("#{DELIVERY_DIR}", "#{delivery_file}"))
      }

      CreateOrderEmail.exec_now({:order_id => @order_id, :delivery_files => delivery_files})
      on_success("#{part} zip file(s) have been created for order #{@order_id} ")
   end
end
