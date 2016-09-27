#encoding: utf-8

SOLR_URL="http://docker1.lib.virginia.edu:8060/solr"

namespace :test do
   desc "Publish to test solr index by querying APIs for avaialble data as of Date.today"
   task :publish  => :environment do
      port = ENV['port']
      core = ENV['core']
      core = 'core' if core.blank?
      api_root = "http://localhost"
      api_root << ":#{port}" if !port.blank?
      api_root << "/api"
      ts = Date.today.to_time.to_i

      puts "Get items that are ready to go to DL today..."
      url = "#{api_root}/solr?timestamp=#{ts}"
      resp = RestClient.get url
      pids = resp.split(",")
      pids.each do |pid|
         puts "====> Get Solr index for #{pid}..."
         xml = RestClient.get "#{api_root}/solr/#{pid}", {:accept => :xml}
         puts "====> Sending to #{SOLR_URL}/#{core}..."
         response = RestClient.post "#{SOLR_URL}/#{core}/update?commit=true", xml, {:content_type => 'application/xml'}
         puts response
      end
   end

   desc "Publish one masterfile to dev SOLR"
   task :publish_mf => :environment do
      core = ENV['core']
      core = 'virgo' if core.blank?
      id = ENV['id']
      abort("ID is required") if id.nil?
      mf = MasterFile.find(id)
      abort("Invalid ID") if mf.nil?
      if !mf.metadata.discoverability
         puts "Updating discoverability"
         mf.metadata.update(discoverability: 1)
      end
      if mf.metadata.indexing_scenario.blank?
         puts "Indexing not set; dfaulting to holsinger"
         mf.metadata.update(indexing_scenario_id: 2)
      end

      api_root = "https://tracksys.lib.virginia.edu/api"
      puts "Publish master file #{mf.id}: #{mf.filename} to dev solr: #{SOLR_URL}"
      metadata_url = "#{api_root}/solr/#{mf.metadata.pid}"
      puts "Metadata URL: #{metadata_url}"
      xml = RestClient.get metadata_url, {:accept => :xml}
      RestClient.post "#{SOLR_URL}/#{core}/update?commit=true", xml, {:content_type => 'application/xml'}
      puts "Published PID: #{mf.pid}"
   end
end
