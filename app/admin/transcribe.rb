ActiveAdmin.register_page "Transcribe" do
   menu false

   content :only=>:index do
      mf = MasterFile.find(params[:mf])

      div :class => 'two-column img-column' do
         panel "Master File" do
            render partial: 'image', :locals=>{:mf=>mf }
         end
      end
      div :class => 'two-column' do
         panel "Transcription", :class=>"transcription" do
            render partial: 'transcription', :locals=>{:mf=>mf }
         end
      end
   end

   page_action :zoom, method: :get do
      mf = MasterFile.find(params[:mf])
      # jpg_file = Tempfile.new(["#{mf.unit_id}", '.jpg'])
      # arch_file = File.join(ARCHIVE_DIR, "%09d" % mf.unit_id, mf.filename)
      # cmd = "convert -resize 2000 #{arch_file} jpg:-> #{jpg_file.path}"
      # `#{cmd}`
      iiif_url = URI.parse("#{Settings.iiif_url}/#{mf.metadata.pid}/full/,2000/0/default.jpg")
      send_data IO.binread(jpg_file.path), :type => 'image/jpg',:disposition => 'inline'
   end
end
