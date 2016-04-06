ActiveAdmin.register_page "OCR" do
   menu false
   content :only=>:index do
      mf = MasterFile.find(params[:mf])
      ocr_job = JobStatus.where("originator_type=? and originator_id=? and (status=? or status=?)", "MasterFile", 48, "pending", "running").first
      job_id = 0
      job_id = ocr_job.id if !ocr_job.nil?

      # Get list of tesseract supported languages
      lang_str = `tesseract --list-langs 2>&1`
      # gives something like: List of available languages (107):\nafr\...
      # split off info and make array
      lang_str = lang_str.split(":")[1].strip
      langs = lang_str.split("\n")

      div :class => 'two-column img-column' do
         panel "Master File" do
            render partial: 'ocr', :locals => {:mf => mf, :langs=>langs, :working=>(!ocr_job.nil?), :job_id=>job_id }
         end
      end
      div :class => 'two-column' do
         panel "Transcription", :class=>"transcription" do
            render partial: 'transcription', :locals=>{:mf=>mf, :working=>(!ocr_job.nil?) }
         end
      end
   end

   # POST to save to update transcription text for a master file
   #
   page_action :save, method: :post do
      mf = MasterFile.find(params[:id])
      mf.transcription_text = params[:transcription]
      if mf.save
         render :text=>"ok", :status=>:ok
      else
         render :text=>mf.errors.full_messages.to_sentence, :status=>:error
      end
   end

   # POST to start to start an OCR job. Payload includes starting object type and ID
   #
   page_action :start, method: :post do
      job_id = Ocr.exec({ :object_class=>params[:type], :object_id=>params[:id], :language=>params[:lang] })
      render :text=>job_id, :status=>:ok
   end

   page_action :zoom, method: :get do
      mf = MasterFile.find(params[:mf])
      jpg_file = Tempfile.new(["#{mf.unit_id}", '.jpg'])
      arch_file = File.join(ARCHIVE_DIR, "%09d" % mf.unit_id, mf.filename)
      cmd = "convert -resize 2000 #{arch_file} jpg:-> #{jpg_file.path}"
      `#{cmd}`
      send_data IO.binread(jpg_file.path), :type => 'image/jpg',:disposition => 'inline'
   end

   # GET to status to get status of job ID passed as query param
   #
   page_action :status, method: :get do
      begin
         job = JobStatus.find(params[:job].to_i)
         resp = {status: job.status}
         if job.status == 'failure'
            resp[:error] = job.error
         elsif job.status == 'success'
            if job.originator_type == "MasterFile"
               mf = MasterFile.find(job.originator_id)
               resp[:transcription] = mf.transcription_text
            end
         end
         render :json=>resp, :status=>:ok
      rescue Exception => e
         render :text=>"Unable to find job "+params[:job], :status=>:not_found
      end
   end
end
