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

   desc "Count old items"
   task :old  => :environment do
      q = '(resource_type="text" or resource_type is null) and is_manuscript=0 and date_dl_ingest is not null'
      total = SirsiMetadata.where(q).count
      puts "Checking for old metadata records (#{total} total records)..."
      old_cnt = 0
      SirsiMetadata.where(q).find_each do |m|
         next if m.catalog_key.nil? && m.barcode.nil?
         year = Virgo.get_marc_publication_info(m.catalog_key, m.barcode)[:year]
         if !year.blank? && year.to_i < 1800
            puts "** #{m.id} is old: #{year} **"
            old_cnt +=  m.master_files.count
            puts "#{m.id} is old: #{year}. TOTAL: #{old_cnt}"
         end
         sleep 0.2
      end
      puts "FOUND #{old_cnt} records from before 1800"
   end
end
