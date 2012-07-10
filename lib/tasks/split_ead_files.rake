namespace :ead do
	EAD_HOME="/usr/local/projects/ead_finding_aids/uva-sc"

	desc "Tests Nokogiri parsing EAD XML"
	task :test, [:specific_guide] => [:mkdir] do |t, args|
		@dirs=[]
		if args.specific_guide
			@dirs = Dir.glob("#{EAD_HOME}/#{args.specific_guide}.xml")
		else
			@dirs = Dir.glob("#{EAD_HOME}/viu*.xml")
		end
		viu=@dirs.first
		guide = File.basename(viu, ".xml")
#		input = File.open(viu, 'r')
#			input.close
		begin	
			xml=Nokogiri::XML(File.open(viu,'r')) {|config| config.noblanks }
			output = File.open("/tmp/#{guide}.xml", 'w') {|f| f.write(xml.to_xml) }
#			xml.write_to(output, :encoding => 'UTF-8', :indent => 2)
#			output.close
		rescue Nokogiri::XML::SyntaxError => e
			puts "caught exception: #{e}"
		end
	end

	desc "Splits EAD XML and stores chunks in named directories"
	task :split, [:specific_guide] => [:mkdir] do |t, args|
	  puts "Breaking up all viu*.xml files into chunks, to be stored in #{Rails.root}/tmp/ead_data"
		@dirs=[]
		if args.specific_guide
			@dirs = Dir.glob("#{EAD_HOME}/#{args.specific_guide}.xml")
		else
			@dirs = Dir.glob("#{EAD_HOME}/viu*.xml")
		end

			@dirs.each do |viu| 
				guide = File.basename(viu, ".xml")
				puts "#{Rails.root}/tmp/ead_data/#{guide}/#{guide}.xml"
				input = File.open(viu, 'r')
				xml=Nokogiri::XML::Document.parse(input) {|config| config.noblanks} 
				input.close
				id_list = xml.xpath("//*[starts-with(local-name(), 'c0')]/@id")
				id_list.each do |id|
					next unless id.is_a?(Nokogiri::XML::Attr)
					xml2=Nokogiri::XML::Document.parse(File.open(viu, 'r')) {|config| config.noblanks} 
					chunk = xml2.xpath("//*[@id='#{id}']")
					chunk.xpath("child::*[starts-with(local-name(), 'c0')]").remove
					output = Nokogiri::XML::Document.new do |config| config.noblanks end
					node = chunk.first
					puts "#{id} #{node.class}"
					file = File.open("#{Rails.root}/tmp/ead_data/#{guide}/#{id}.xml", "w") {|f| f.write(node.to_xml) }
#					node.write_to(file, :encoding => 'UTF-8', :indent => 2)
#					file.close
				end

				xml.xpath("//dsc/c01").remove
				output = File.open("#{Rails.root}/tmp/ead_data/#{guide}/#{guide}.xml", 'w') {|f| f.write(xml.to_xml) }
#				xml2.write_to(output, :encoding => 'UTF-8', :indent => 2)
			end
	end

	desc "build holding directories for EAD fragments"
	task :mkdir do
		 @dirs = Dir.glob("#{EAD_HOME}/viu*.xml")
		 @dirs.each { |fn| 
			bname=File.basename(fn, ".xml") 
			FileUtils.mkdir_p(File.join(Rails.root, "tmp/ead_data", bname)) #=> 0
		 }
	end

end
