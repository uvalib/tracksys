class Api::AriesController < ApplicationController

   # Used by aries to ping this API and see if it is alive. Just return
   # a status string
   #
   def index
      render plain: "TrackSys Aries API", status: :ok
   end

   # Implemenmtation of the Aries API:
   # Show all details for a resource with the specified identifier. 404 if
   # tracksys does not manage a matching resource
   #
   def show
      # Look for the supplied ID in all of the candidate resource types managed
      # by tracksys; metadata, masterfile, component
      id = params[:id]
      json = find_metadata(id)
      json = find_masterfile(id) if json.nil?
      json = find_component(id) if json.nil?
      if json.nil?
         render plain: "#{params[:id]} not found", status: :not_found
      else
         render json: json
      end
   end

   private
   def find_metadata(id)
      obj = Metadata.find_by(pid: id)
      obj = Metadata.find_by(catalog_key: id) if obj.nil?
      obj = Metadata.find_by(barcode: id) if obj.nil?
      return nil if obj.nil?

      json = {
         identifier: [obj.pid],
         administrative_url: ["#{Settings.tracksys_url}/admin/#{obj.url_fragment}/#{obj.id}"]
      }

      json[:identifier] << obj.catalog_key if !obj.catalog_key.nil?
      json[:identifier] << obj.barcode if !obj.barcode.nil?
      json[:identifier] << obj.call_number if !obj.call_number.nil?
      json[:service_url] = []
      json[:metadata_url] = []

      json[:metadata_url] <<  {url: "#{Settings.tracksys_url}/api/metadata/#{obj.pid}?type=brief", schema: "json"}

      if obj.type != "ExternalMetadata"
         if obj.type == "XmlMetadata"
            virgo_url = "#{Settings.tracksys_url}/api/solr/#{obj.pid}"
            json[:service_url] <<  {url: virgo_url, protocol: "virgo-index"}
         end
         if !obj.catalog_key.blank?
            json[:service_url] <<  {url: "#{Settings.tracksys_url}/api/sirsi/#{obj.catalog_key}", protocol: "sirsi-wrapper"}
         end
         if !obj.availability_policy.blank?
            json[:access_restriction] = obj.availability_policy.name.split.first.downcase
         else
            json[:access_restriction] = "private"
         end
         json[:metadata_url] <<  {url: "#{Settings.tracksys_url}/api/metadata/#{obj.pid}?type=desc_metadata", schema: "mods"}
      end

      if obj.master_files.count > 0
         json[:service_url] <<  {url: "#{Settings.iiif_manifest_url}/#{obj.pid}", protocol: "iiif-presentation"}
         json[:service_url] <<  {url: "#{Settings.tracksys_url}/api/manifest/#{obj.pid}", protocol: "json-manifest"}
      end
      return json
   end

   def find_masterfile(id)
      obj = MasterFile.find_by(pid: id)
      obj = MasterFile.find_by(filename: id) if obj.nil?
      return nil if obj.nil?

      json = {
         identifier: [obj.pid],
         administrative_url: ["#{Settings.tracksys_url}/admin/master_files/#{obj.id}"],
         master_file: [File.join(ARCHIVE_DIR, "%09d" % obj.unit_id, obj.filename)]
      }

      if !obj.transcription_text.blank?
         json[:service_url] = [ {url: "#{Settings.tracksys_url}/api/fulltext/#{obj.pid}", protocol: "transcription"} ]
      end

      return json
   end

   def find_component(id)
      obj = Component.find_by(pid: id)
      obj = Component.find_by(barcode: id) if obj.nil?
      return nil if obj.nil?

      json = {
         identifier: [obj.pid],
         administrative_url: ["#{Settings.tracksys_url}/admin/components/#{obj.id}"]
      }
      json[:identifier] << obj.barcode if !obj.barcode.nil?
      if obj.master_files.count > 0
         json[:service_url] =  [{url: "#{Settings.iiif_manifest_url}/#{obj.pid}", protocol: "iiif-presentation"}]
      end
      return json
   end
end
