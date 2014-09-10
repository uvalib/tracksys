# generate some reports about ead components ...

namespace :ead do

def guide_summary

	guides = Component.where( 'ead_id_att LIKE "viu0%"' ).sort_by { |c| c.ead_id_att }
	guides.map do |g|
		b = g.bibls && g.bibls.first
		s = { :ead_id => g.ead_id_att, :desc => g.content_desc, 
			  :bibl_id => b && b.id, 
			  :bibl_title => b && b.title,
			  :units => b && b.units && b.units.size, 
			  :mf_count => b && b.master_files && b.master_files.size, }
	end
end

def guide_report

	guides = Component.where( 'ead_id_att LIKE "viu0%"' ).sort_by { |c| c.ead_id_att }
	guides.map do |g|
		b = g.bibls && g.bibls.first
		s = { :component => g,  
			  :bibl => b,  
			  :units => b && Unit.where( "bibl_id = #{b.id}" ),
			  :mf_count => b && b.master_files && b.master_files.size, }
	end

end

desc "generate json/html summary report of 'viu0' EAD components attached to bibls"
task :component_summary => :environment do

	summary = guide_summary.select { |x| x[:bibl_id] } # select only ones with associated master_files

	output = File.new( 'guidesummary.html' , 'w' )
	output.awesome_print( summary, :html => true )
	puts output.to_path

end


desc "generate json/html full report of 'viu0' EAD components attached to bibls"
task :component_report => :environment do

	summary = guide_report.select { |x| x[:bibl] } # select only ones with associated master_files

	output = File.new( 'guidereport.html' , 'w' )
	output.awesome_print( summary, :html => true )
	puts output.to_path

end

end # namespace :ead
