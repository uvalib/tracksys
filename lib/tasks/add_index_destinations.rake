namespace :db do
  desc "adds three index locations to system"
  task :add_index_destinations => :environment do
    list={ :searchdev => {
      :nickname => 'searchdev',
      :hostname => 'libsvr25.lib.virginia.edu',
      :port     => '8984',
      :protocol => 'http',
      :context  => 'solr/dl'
   },
   :tracksys_core => {
      :nickname => 'tracksys_core',
      :hostname => 'libsvr25.lib.virginia.edu',
      :port     => '8080',
      :protocol => 'http',
      :context  => 'solr/tracksys'
   },
   :virgo => {
      :nickname => 'virgo',
      :hostname => 'index.lib.virginia.edu',
      :port     => '80',
      :protocol => 'http',
      :context  => 'virgobeta'
    }
}
    list.each do |k,hash|
      i=IndexDestination.new
      hash.each do |attr_name,val|
        i.send :"#{attr_name}=", val
      end
      puts i.inspect
      i.save!
    end
    puts "IndexDestination objects created."
  end
end
