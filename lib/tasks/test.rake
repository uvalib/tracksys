#encoding: utf-8
#require 'solr'
#require 'rest-client'

SOLR_URL="http://localhost:8983/solr"

namespace :test do
   desc "Publish to test solr index by querying APIs for avaialble data as of Date.today"
   task :publish  => :environment do
      port = ENV['port']
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
         resp = RestClient.get "#{api_root}/solr/#{pid}", {:accept => :xml}
         puts resp
      end
   end
end
