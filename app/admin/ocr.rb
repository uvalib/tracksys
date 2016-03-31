ActiveAdmin.register_page "OCR" do
   menu false
   content do
      mf = MasterFile.find(params[:mf])

      # Get list of tesseract supported languages
      lang_str = `tesseract --list-langs 2>&1`
      # gives something like: List of available languages (107):\nafr\...
      # split off info and make array
      lang_str = lang_str.split(":")[1].strip
      langs = lang_str.split("\n")

      div :class => 'two-column' do
         panel "Master File" do
            render partial: 'ocr', :locals => {:mf => mf, :langs=>langs }
         end
      end
      div :class => 'two-column' do
         panel "Transcription" do
            textarea :class=>"transcription", :rows=>52
         end
      end
   end
end
