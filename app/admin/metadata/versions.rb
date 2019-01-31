ActiveAdmin.register_page "Versions" do
   belongs_to :xml_metadata, optional: true
   menu false

   content :only=>:index do
      xmd = XmlMetadata.find(params[:xml_metadatum_id])
      panel "Version History for XML Metadata PID #{xmd.pid}" do
         table_for xmd.metadata_versions.order(created_at: :desc) do |v|
            column :created_at do |v|
               v.created_at.strftime("%F %r")
            end
            column ("Created By") do |v|
               v.staff_member.full_name
            end
            column :version_tag
            column ("Records Changed") do |v|
               MetadataVersion.where(version_tag: v.version_tag).count
            end
            column ("Actions") do |v|
               span class: "btn diff", 'data-tag': v.version_tag do "Diff" end 
               span class: "btn restore", 'data-tag': v.version_tag  do "Restore" end 
               if MetadataVersion.where(version_tag: v.version_tag).count > 1
                  span class: "btn restore-all" do "Restore All" end 
               end   
            end
         end
      end

      div id: "dimmer" do
         div id: "diff-viewer-modal", class: "modal" do 
            h1 id: "diff-header" do "Version Diff" end
            div class: "content" do 
               div id: "diff-scroller" do 
               end
            end
            div class: "buttons" do
               input type: "button", id: "close-diff-viewer", value: "Close"
            end
         end
      end
   end
end