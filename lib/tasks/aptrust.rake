namespace :aptrust do
   desc "Test generate of a bag"
   task :test  => :environment do
   
      mf = MasterFile.find(365940)
      bag = Bagit::Bag.new({bag: "testbag", title: "000047671_0001.tif", pid: mf.metadata.pid}, Logger.new(STDOUT) )
      mfp = File.join(Settings.archive_mount, "000047671", "000047671_0001.tif")
      
      bag.add_file("000047671_0001.tif", mfp)
      bag.add_file("000047671_0001.xml") {|io| io.write mf.metadata.desc_metadata}
      bag.generate_manifests
      tarfile = bag.tar

      etag = ApTrust::submit( tarfile )
      puts "ETAG #{etag}"

      bag.cleanup
   end 
end