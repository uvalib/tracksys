# generate some reports about ead components ...

namespace :ead do

def guide_summary

	guides = Component.where( 'ead_id_att LIKE "viu%"' ).sort_by { |c| c.ead_id_att }
	guides.map do |g|
		b = g.bibls && g.bibls.first
		s = { :ead_id => g.ead_id_att, :desc => g.content_desc, 
			  :bibl_id => b && b.id, 
			  :bibl_title => b && b.title,
			  :units => b && b.units && b.units.size, 
			  :mf_count => b && b.master_files && b.master_files.size,
			  :desc_mf_count => g.descendant_master_file_count }
	end
end

def guide_report

	guides = Component.where( 'ead_id_att LIKE "viu%"' ).sort_by { |c| c.ead_id_att }
	guides.map do |g|
		b = g.bibls && g.bibls.first
		s = { :component => g,  
			  :bibl => b,  
			  :units => b && Unit.where( "bibl_id = #{b.id}" ),
			  :bibl_mf_count => b && b.master_files && b.master_files.size, 
			  :comp_desc_mf_count => g.descendant_master_file_count }
	end

end

TS_URL = "http://tracksys.lib.virginia.edu"
# add:  mf.link_to_dl_thumbnail, mf.link_to_static_thumbnail 
# there is also .link_to_dl_pageturner, but only works if Bibl is discoverable in Virgo 
#  need to check both .in_dl? && bibl.index_destination.id = 3 ( or .index_destination.nickname = "virgo" )
# link_to_dl_thumbnail is a bit small -- can change the scale parameter to get larger size 
def build (hash)
  hash.collect do |k,v|
    { :ead_id => k.ead_id_att, :ead_id_cache => k.ead_id_atts_depth_cache, 
    	:level => k.level, :pid => k.pid, 
    	:desc => k.content_desc, 
      :master_files => k.master_files.collect { |mf| 
          mfhash = { pid: mf.pid, filename: mf.filename, static_thumb: TS_URL + mf.link_to_static_thumbnail }
          mfhash[:dl_thumb] = mf.link_to_dl_thumbnail  if mf.in_dl? 
          mfhash[:pageturner] = mf.link_to_dl_page_turner if mf.in_dl? && mf.bibl && mf.bibl.in_dl? && mf.bibl.index_destination && mf.bibl.index_destination == 3
          mfhash
        },
    	:children => (  if v.is_a?(Hash) and not v.empty? 
    						build(v)
    					end
    					),
    }.delete_if { |k,v| v.nil? }
  end
end

desc ":component_json[:eadid] - Dump component summary to json"
task :component_json, [:ead_id] => [:environment] do |t, args| 
	# find top level component with ead_id
	subtree = Component.where("ead_id_att = '#{args[:ead_id]}'")[0].subtree.arrange 
	summary = build(subtree) # generate summary
	# and dump hierarchy to json file
	puts "Writing output to: #{args[:ead_id]}.json ..."
	File.new( "#{args[:ead_id]}.json", "w" ).write( summary.to_json )

	puts "Writing output to: #{args[:ead_id]}.xml ..."
	File.new( "#{args[:ead_id]}.xml", "w" ).write( summary.to_xml )
	
	puts "Writing output to #{args[:ead_id]}.html ..." 
	File.new( "#{args[:ead_id]}.html", "w" ).awesome_print( summary, :html => true )
end

desc "generate json/html summary report of 'viu' EAD components attached to bibls"
task :component_summary => :environment do

	summary = guide_summary.select { |x| x[:bibl_id] } # select only ones with associated master_files

	output = File.new( 'guidesummary.html' , 'w' )
	output.awesome_print( summary, :html => true )
	puts output.to_path
	puts "writing: guidesummary.json"
	File.new( 'guidesummary.json', 'w' ).write( summary.to_json )

end


desc "generate json/html full report of 'viu' EAD components attached to bibls"
task :component_report => :environment do

	summary = guide_report.select { |x| x[:bibl] } # select only ones with associated master_files

	output = File.new( 'guidereport.html' , 'w' )
	output.awesome_print( summary, :html => true )
	puts output.to_path
	puts "writing: guidereport.json"
	File.new( 'guidereport.json', 'w' ).write( summary.to_json )

end

end # namespace :ead
