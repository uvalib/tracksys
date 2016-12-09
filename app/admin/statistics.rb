ActiveAdmin.register_page "Statistics" do
   menu :priority => 2

   content do
      div :class => 'two-column' do
         panel "Image Statictics" do
         end
      end

      div :class => 'two-column' do
         panel "Storage Statictics" do
         end
      end


      div :class => 'two-column' do
         panel "Unit Statictics" do
         end
      end

      div :class => 'two-column' do
         panel "Metadata Statictics" do
         end
      end
   end
end
