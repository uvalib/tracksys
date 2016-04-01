class Ocr < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=> message[:object_class], :originator_id=>message[:object_id])
   end

   def do_workflow(message)
      object_class = message[:object_class]
      object_id = message[:object_id]
      object = object_class.classify.constantize.find(object_id)

      if object_class == "MasterFile"
      else
         raise "OCR can only be performed on master files"
      end
   end
end
