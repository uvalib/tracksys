ActiveAdmin.register_page "Versions" do
   belongs_to :xml_metadata, optional: true
   menu false

   content :only=>:index do
      h1 do "Placeholder" end
   end
end