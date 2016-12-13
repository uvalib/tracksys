ActiveAdmin.register_page "Statistics" do
   menu :priority => 2

   content do
      div :class => 'two-column' do
         panel "Image Statictics", :namespace => :admin, :priority => 1 do
            render partial: 'statistics', locals: { stat_group: "image"}
            render partial: 'image_query'
         end
         panel "Unit Statictics", :namespace => :admin, :priority => 3 do
            render partial: 'statistics', locals: { stat_group: "unit"}
         end
      end

      div :class => 'two-column' do
         panel "Storage Statictics", :namespace => :admin, :priority => 2 do
            render partial: 'statistics', locals: { stat_group: "size"}
         end
         panel "Metadata Statictics", :namespace => :admin, :priority => 4 do
            render partial: 'statistics', locals: { stat_group: "metadata"}
         end
      end

   end

   controller do
      before_filter :get_stats
      def get_stats
         @stats = Statistic.get
      end
   end
end
