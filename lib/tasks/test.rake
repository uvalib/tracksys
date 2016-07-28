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
end
