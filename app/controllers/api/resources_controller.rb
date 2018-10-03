class Api::ResourcesController < ApplicationController

   # Show all details for a resource with the specified identifier
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
         administrative_url: ["#{Settings.tracksys_url}/admin/#{obj.url_fragment}/#{obj.id}"],
         service_url: [],
         metadata_url: []
      }

      json[:identifier] << obj.catalog_key if !obj.catalog_key.nil?
      json[:identifier] << obj.barcode if !obj.barcode.nil?
      json[:identifier] << obj.call_number if !obj.call_number.nil?

      if obj.type != "ExternalMetadata"
         virgo_url = "#{Settings.tracksys_url}/api/solr/#{obj.pid}"
         if obj.type == "SirsiMetadata"
            if !obj.catalog_key.nil?
               virgo_url = "#{Settings.solr_url}/core/select/?q=id:#{obj.catalog_key}"
            else
               virgo_url = "#{Settings.solr_url}/core/select/?q=barcode_facet:#{obj.barcode}"
            end
         else
            virgo_url = "#{Settings.tracksys_url}/api/solr/#{obj.pid}"
         end
         json[:service_url] <<  {url: virgo_url, protocol: "virgo-index"}
      end

      if obj.master_files.count > 0
         json[:service_url] <<  {url: "#{Settings.iiif_manifest_url}/#{obj.pid}", protocol: "iiif-presentation"}
      end

      if obj.type != "ExternalMetadata"
         json[:metadata_url] <<  {url: "#{Settings.tracksys_url}/api/metadata/#{obj.pid}?type=desc_metadata", schema: "mods"}
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
         service_url: [],
         metadata_url: [],
         master_file: File.join(ARCHIVE_DIR, "%09d" % obj.unit_id, obj.filename)
      }
      return json
   end

   def find_component(id)
      obj = Component.find_by(pid: id)
      obj = Component.find_by(barcode: id) if obj.nil?
      return nil if obj.nil?
   end
end
