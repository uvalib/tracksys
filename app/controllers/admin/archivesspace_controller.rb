class Admin::ArchivesspaceController < ApplicationController
   def lookup
      render json: ArchivesSpace.lookup(params[:uri])
   end

   # Convert an existing metadata record to external ArchivesSpace
   #
   def convert
      begin
         ConvertToAs.exec_now({metadata_id: params[:metadata_id], as_url: params[:as_url], staff_member: current_user })
         render plain: "Existing metadata converted to ArchivesSpace"
      rescue Exception=>e
         Rails.logger.error "ArchivesSpace conversion failed: #{e.to_s}"
         render plain: e.to_s, status:  :bad_request
      end
   end

   # validate the form of a URL. if it is sumbolic, convert to numeric. Verify link returns good data.
   def validate
      # format is: repositories/[repo_id]/[archival_objects|accessions|resources]/[object_id]
      tgt = params[:as_url]
      parts = tgt.split("/")
      if parts.length != 4
         render plain: "URL is malformed", status:  :bad_request
         return
      end

      Rails.logger.info "Get AS auth session"
      auth = ArchivesSpace.get_auth_session()

      # check for numeric repo
      Rails.logger.info "Validate repository ID [#{parts[1]}]"
      if is_number?(parts[1]) == false
         Rails.logger.info "Repo [#{parts[1]}] is not numeric, lookup existing repos..."
         repos = ArchivesSpace.get_repositories(auth)
         tgt_repo_id = nil
         repos.each do |r|
            Rails.logger.info "match #{r[:slug]}?"
            if r[:slug] == parts[1]
               tgt_repo_id = r[:id]
               Rails.logger.info "Found repo #{parts[1]} ID #{tgt_repo_id}"
               break
            end
         end
         if !tgt_repo_id.nil?
            parts[1] = tgt_repo_id
         else
            render plain: "invalid repository #{parts[1]}", status:  :bad_request
            return
         end
      end

      # make sure only supported object types are listed
      Rails.logger.info "Validate object type"
      supported_objs = ["archival_objects", "accessions", "resources"]
      if !supported_objs.include?(parts[2])
         render plain: "only archival_objects, accessions and resources are supported", status:  :bad_request
         return
      end

      # check for numeric object id
      Rails.logger.info "Validate object ID"
      if is_number?(parts[3]) == false
         Rails.logger.info "ObjectID [#{parts[3]}] is not numeric, search for match"
         begin
            # if the url is invalid for any reason an exception will be raised
            id = ArchivesSpace.lookup_object_slug(auth, parts[1], parts[3])
            parts[3] = id
          rescue => exception
            render plain: "invalid object ID #{parts[3]}", status:  :bad_request
          end
      end

       # now join all the corrected parts of the URL and see if we can pull AS data for it
       fixed_as = parts.join("/")
       Rails.logger.info "Validate updated URI #{fixed_as}"
       begin
         # if the url is invalid for any reason an exception will be raised
         ArchivesSpace.get_details(auth, fixed_as)
         render plain: fixed_as, status:  :ok
       rescue => exception
         render plain: "invalid URL #{exception}", status:  :bad_request
       end
   end

   def is_number? string
      true if Integer(string) rescue false
   end
end
