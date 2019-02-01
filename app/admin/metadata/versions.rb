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
            h1 id: "diff-header" do end
            div class: "content" do 
               div class: "diff-tabs" do 
                  span class: "tab-btn", id: "diff-btn" do "Diff" end
                  span class: "tab-btn", id: "curr-btn" do "Current" end
                  span class: "tab-btn", id: "tagged-btn" do "Diff" end
               end
               div id: "diff-tab", class: "diff-scroller" do 
                  pre id: "diff" 
               end
               div id: "curr-tab", class: "diff-scroller", style: "display:none" do 
                  pre id: "curr" 
               end
               div id: "tagged-tab", class: "diff-scroller", style: "display:none" do 
                  pre id: "tagged"
               end
            end
            div class: "buttons" do
               input type: "button", id: "close-diff-viewer", value: "Close"
            end
         end
      end
   end

   page_action :diff do
      tag = params[:tag]
      md = XmlMetadata.find(params[:xml_metadatum_id])
      old = MetadataVersion.find_by(metadata_id: md.id, version_tag: tag)
      diff = Diffy::Diff.new(old.desc_metadata, md.desc_metadata).to_s()
      render json: { status: "success", diff: diff, curr: md.desc_metadata, tagged: old.desc_metadata}
   end

   page_action :revert, method: "post" do
      tag = params[:tag]
      md = XmlMetadata.find(params[:xml_metadatum_id])
      tgt = MetadataVersion.find_by(metadata_id: md.id, version_tag: tag)
      if tgt.nil?
         render json: { status: "failed", message:"Version not found"}, status: :error
         return
      end

      del = 0
      MetadataVersion.where(metadata_id: md.id).order(created_at: :desc).each do |v|
         del += 1
         if v.version_tag != tag 
            v.destroy
         else
            md.update(desc_metadata: v.desc_metadata)
            v.destroy
            break
         end
      end
      render json: { status: "success", message: "#{tag} restored. #{del} intermediate versions removed."}
   end
end