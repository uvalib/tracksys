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
end
