class Api::MetadataController < ApplicationController
   def show
      render :text=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      render :text=>"#{type} is not supported", status: :bad_request and return if type != "desc_metadata" && type != "dpla_metadata"
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         object = MasterFile.find_by(pid: params[:pid])
      end
      render :text=>"PID is invalid", status: :bad_request and return if object.nil?

      if type == "desc_metadata"
         render :xml=> Hydra.desc(object)
      end

      if type == "dpla_metadata"
         xsl = File.join(Rails.root, "lib", "xslt", "DPLA", "MODStoDPLAMODS.xsl")
         saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"
         params = "pid=#{object.pid} exemplarPid=#{object.pid}"

         tmp = Tempfile.new(object.pid)
         tmp.write(Hydra.desc(object))
         tmp.close

         cmd = "#{saxon} -s:#{tmp.path} -xsl:#{xsl} #{params}"   #-o:#{out} #{params}"
         puts "     #{cmd}"
         render :xml=> `#{cmd}`
      end
   end
end
