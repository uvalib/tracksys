
#
# The master files for the Reed guide are largely miss-assigned to the wrong components
# due to a bug in the import_iview_xml code.
# This does a reassignment from the iview catalog.
# code largely clipped from the FIXED import_iview_xml.rb
#

namespace :component  do

require 'nokogiri'


def check_unit( unit_id, fix=false, xmlfile=nil )
raise "NO LONGER SUPPORTED; PRODUCTION_METADATA_DIR NOT USED ANYMORE"
	range_dir = nil
	good = 0; bad = 0; total=0;

    # Get Unit object
    begin
      unit = Unit.find(unit_id)
    rescue ActiveRecord::RecordNotFound
      raise ImportError, "Unit #{unit_id} does not exist"
    end

	if  not xmlfile  #  look for the iview xml file in PRODUCTION_METADATA_DIR...
	# get metadata directory code cut and pasted from
	# app/processors/copy_metadata_to_metadata_directory_processor.rb

		unit_dir = "%09d" % unit_id

		# Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
		# will eliminate other directories that are of non-Tracksys managed content.
		metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
		metadata_dir_contents.each {|dir|
		  range = dir.split('-')
		  if unit_id.to_i.between?(range.first.to_i, range.last.to_i)
			range_dir = dir
		  end
		}

		if not range_dir
		  puts "No subdirectories of #{PRODUCTION_METADATA_DIR} appear to be suitable for #{unit_id}."
		end

		xmlfile = File.join(PRODUCTION_METADATA_DIR,  range_dir, unit_dir, unit_dir+'.xml' )

		if not File.exists?( xmlfile )
		  puts "#{ xmlfile } does not exist!"
		end
	end # if not xmlfile

	# open and parse an iview xml catalog:
	begin
		doc = Nokogiri.XML( File.new(xmlfile))
    rescue Exception => e
      	raise ImportError, "Can't read file #{xmlfile} as XML: #{e.message}"
    end

	root = doc.root


# for each MediaItem
# get filename, find master_file by filename...
#

    root.xpath('MediaItemList').each do |list|
        list.xpath('MediaItem').each do |item|

        	element = item.xpath('AssetProperties/UniqueID').first
          		iview_id = element.nil? ? nil : element.text
          	if iview_id.blank?
            	raise ImportError, "Missing or empty <UniqueID> for <MediaItem>"
          	end

			filename = item.xpath( 'AssetProperties/Filename' ).first.text
			master_file = unit.master_files.where( "filename = '#{filename}'" ).first
			ts_component = Component.find(master_file.component_id)

          # Only attempt to link MasterFiles with Components if the MasterFile's Bibl record is a manuscript item
          if unit.bibl && unit.bibl.is_manuscript?
            # Determine if this newly created MasterFile's <UniqueID> (now saved in the iview_id variable)
            # is part of a <Set> within this Iview XML.  If so grab it and find the PID value.
            #
            # If the setname does not include a PID value, raise an error.
            setname = root.xpath("//SetName/following-sibling::UniqueID[normalize-space()='#{iview_id}']/preceding-sibling::SetName").last.text
            pid = setname[/pid=([-a-z]+:[0-9]+)/, 1]
            if pid.nil?
              raise ImportError, "Setname '#{setname}' does not contain a PID, therefore preventing assignment of Component to MasterFile"
            else
            	total += 1
            	iview_component = Component.where( "pid = '#{pid}'" ).first
            	if ts_component == iview_component
            		good += 1
            	else
            		bad += 1
            		printf  "# %p %s %s\n" , ( ts_component == iview_component ),element,filename
					printf  "%d : %s\n", ts_component.id, ts_component.title
					printf  "%d : %s\n", iview_component.id, iview_component.title
					if fix
						puts "FIX: update_attribute mf_id:#{master_file.id}, cp_id: #{iview_component.id}"
						# both of these give "Connection refused ..."
						# AHA! Problem was that activemq needs to be running for active_message
						# (It was active_mq connection refused, not mysql.)
						master_file.update_attribute(:component_id, iview_component.id )
						# master_file.component_id = iview_component.id ; master_file.save
					end
               	end
            end
          else
          	printf "unit: #{unit_id}, bibl: #{unit.bibl.id} not a manuscript"
          end # if
		end
	end
	printf "### Unit #{unit_id}: #{bad} bad component assignments found out of #{total}.\n"
end

  #-----------------------------------------------------------------------------
  # private supporting classes
  #-----------------------------------------------------------------------------

private

  class ImportError < RuntimeError  #:nodoc:
  end

desc "test the component check procedure in rake"
task :test => :environment do
  check_unit( 28500 )
end

desc "checkunit[unit]"
task :checkunit, [:unit] => [:environment] do |t, args|
	puts "Unit = #{args[:unit]}"
	unit = args[:unit].to_i
	check_unit( unit )
end

desc "checkbibl[bibl]"
task :checkbibl, [:bibl] => [:environment] do |t, args|
	bibl_id = args[:bibl].to_i
	puts Bibl.find( bibl_id ).title
	units = Unit.where( "bibl_id = #{bibl_id}" )
	puts "#{units.size} units found."
	units.each { |u| check_unit( u.id ) }
end

desc "fixunit[unit]"
task :fixunit, [:unit] => [:environment] do |t, args|
	puts "Unit = #{args[:unit]}"
	unit = args[:unit].to_i
	check_unit( unit, true )
end

desc "fixbibl[bibl]"
task :fixbibl, [:bibl] => [:environment] do |t, args|
	bibl_id = args[:bibl].to_i
	puts Bibl.find( bibl_id ).title
	units = Unit.where( "bibl_id = #{bibl_id}" )
	puts "#{units.size} units found."
	units.each { |u| check_unit( u.id, true ) }
end


desc "pushdl[comp_id] send component, children and master_files to Fedora"
task :pushdl, [:comp_id] => [:environment] do |t, args|
	Component.find(args[:comp_id]).descendants.each { |cx| push_fedora(cx) }
end

end #namespace
