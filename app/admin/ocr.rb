ActiveAdmin.register_page "OCR" do
   menu false

   content :only=>:index do
      # Get list of tesseract supported languages
      lang_str = `tesseract --list-langs 2>&1`
      # gives something like: List of available languages (107):\nafr\...
      # split off info and make array
      lang_str = lang_str.split(":")[1].strip
      langs = lang_str.split("\n")

      if !params[:mf].nil?
         mf = MasterFile.find(params[:mf])
         ocr_job = JobStatus.where("originator_type=? and originator_id=? and (status=? or status=?)", "MasterFile", params[:mf], "pending", "running").first

         div :class => 'two-column img-column' do
            panel "Master File" do
               render partial: 'ocr', :locals => {:mf => mf, :langs=>langs, :job=>ocr_job }
            end
         end
         div :class => 'two-column' do
            panel "Transcription", :class=>"transcription" do
               render partial: 'transcription', :locals=>{:mf=>mf, :job=>ocr_job }
            end
         end
      else
         u = Unit.find(params[:u])
         ocr_job = JobStatus.where("originator_type=? and originator_id=? and (status=? or status=?)", "Unit", params[:u], "pending", "running").first

         div :class => 'two-column' do
            panel "OCR" do
               render partial: 'unit_ocr', :locals=>{:unit=>u, :langs=>langs, :job=>ocr_job }
            end
         end
         div :class => 'two-column' do
            panel "Master Files" do
               render partial: 'master_files', :locals=>{:unit=>u, :job=>ocr_job }
            end
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
   # and other startup info: language and which pages to exclude
   #
   page_action :start, method: :post do
      exclude = []
      if !params[:exclude].nil?
         exclude = params[:exclude].map { |id_str| id_str.to_i }
      end
      job_id = Ocr.exec({ :object_class=>params[:type], :object_id=>params[:id], :language=>params[:lang], :exclude=>exclude })
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
         resp = {status: job.status, type: job.originator_type }
         if job.status == 'failure'
            resp[:error] = job.error
         elsif job.status == 'success'
            if job.originator_type == "MasterFile"
               mf = MasterFile.find(job.originator_id)
               resp[:transcription] = mf.transcription_text
            end
         elsif job.status == 'running' && job.originator_type == "Unit"
            # check for transcriptions on MFs that are part of this job and include
            # in response as completed
            jp = JSON.parse(job.params)
            excluded = jp["exclude"]
            done = []
            job.originator.master_files.each do |mf|
               if !excluded.include?(mf.id) && !mf.transcription_text.nil? && mf.transcription_text != "PROCESSING"
                  puts "TEXT #{mf.transcription_text}"
                  done << mf.id
               end
            end
            resp[:complete] = done
         end
         render :json=>resp, :status=>:ok
      rescue Exception => e
         render :text=>"Unable to find job "+params[:job], :status=>:not_found
      end
   end
end
