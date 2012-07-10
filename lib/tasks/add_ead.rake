namespace :ead do
	require 'nokogiri'
	EAD_DATA_HOME="#{Rails.root}/tmp/ead_data"
	@ead_guides=[]
	desc "Grabs EAD XML chunks and adds as @legacy_ead"
	task :add_ead, [:specific_guide]  => [:environment, :list] do |t, args|
		@guides=[]
		if args.specific_guide
			@list = Dir.glob("#{EAD_DATA_HOME}/#{args.specific_guide}/#{args.specific_guide}.xml")
			@list.each {|g| g = File.basename(g, ".xml"); @guides << g }
			puts @guides.inspect
		else
			@guides = @ead_guides 
		end

		@guides.each do |guide|
			component=Component.where(['ead_id_att=?', guide]).first
			import_legacy_ead(component, guide)
			component.descendants.each do |descendant|
				import_legacy_ead(descendant, guide)
			end
		end
	end

	def import_legacy_ead(component, guide)
		puts "importing #{component.id} #{component.ead_id_att}, member of #{guide}"
		did=component.ead_id_att.to_s
		xmlfile=File.open("#{EAD_DATA_HOME}/#{guide}/#{did}.xml", 'r')
		contents=String.new
		xmlfile.each {|line| contents << line }
		xmlfile.close
		component.legacy_ead = contents
		if component.valid?
			component.save!
		else
			warn "Component #{component.id} is not valid (#{did})"
		end
	end

	desc "Constructs list of EAD guides (collections)"
	task :list do
		#list= %w(viu00001 viu00002 viu00003) 	
		list = []
		Component.where('ead_id_att like ?', "viu0%").each do |c| list << c.ead_id_att end
		list.each {|l| @ead_guides << l }
	end
end
