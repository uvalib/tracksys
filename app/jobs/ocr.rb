class Ocr < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=> message[:object_class], :originator_id=>message[:object_id])
   end

   def do_workflow(message)
      object_class = message[:object_class]
      object_id = message[:object_id]
      language = message[:language]
      object = object_class.classify.constantize.find(object_id)

      if object_class == "MasterFile"
         ocr_master_file(object, language)
         on_success("OCR complete")
      elsif object_class == "Unit"
         ocr_unit(object, language, message[:exclude] )
         on_success("OCR complete")
      else
         raise "OCR can only be performed on units or master files"
      end
   end

   def ocr_unit(unit, language, exclude)
      logger().info("OCR Masterfiles from unit #{unit.id}, EXCEPT #{exclude}")
      unit.master_files.each do |mf|
         next if exclude.include? mf.id
         mf.transcription_text = "PROCESSING"
         mf.save!
         ocr_master_file(mf, language)
      end
   end

   def ocr_master_file( mf, language )
      src = File.join(ARCHIVE_DIR, "%09d" % mf.unit_id, mf.filename)
      dest = File.join(IN_PROCESS_DIR, "%09d" % mf.unit_id,  "OCR_"+mf.filename)
      logger().info("Preprocess #{src} to #{dest}")
      conv_cmd = "convert -density 300 -units PixelsPerInch -type Grayscale +compress #{src} #{dest} 2>/dev/null"
      `#{conv_cmd}`
      if !File.exist? dest
         on_error("Preprocessed file #{dest} was not generated")
      end

      lang_param = ""
      lang_param = "-l #{language}" if !language.nil?
      tess = "tesseract #{lang_param} #{dest} #{dest.split('.tif')[0]}"
      logger().info("Running: #{tess}")
      `#{tess}`

      trans_file = dest.gsub /.tif/, ".txt"
      if !File.exist? trans_file
         on_error("OCR output file #{trans_file} was not generated")
      end
      logger().info("reading ocr result: #{trans_file}")
      file = File.open(trans_file, "r")
      mf.transcription_text = file.read
      file.close
      mf.save!
      mf.ocr!  # flag the text type as OCR

      logger().info("OCR Results added to master file #{mf.id}")

      logger().info("Cleaning up #{trans_file} and #{dest}")
      File.delete(trans_file)
      File.delete(dest)
   end
end
