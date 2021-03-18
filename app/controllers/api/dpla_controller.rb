class Api::DplaController < ApplicationController
   def published
      out = []
      q = "select distinct mp.id, mp.pid from metadata mc"
      q << " inner join metadata mp on mc.parent_metadata_id = mp.id"
      q << " where mc.parent_metadata_id > 0 and mp.dpla = 1 and mp.date_dl_ingest is not null"
      q << " order by mp.id asc"
      Metadata.find_by_sql(q).each do |m|
         m.children.find_each do |meta|

            next if !meta.dpla || meta.date_dl_ingest.blank?
            next if meta.units.count == 1 && meta.units.first.unit_status == "canceled"
            out << meta.pid
         end
      end
      Rails.logger.info "Found #{out.length} DPLA items in collections"

       # Now get stand-along DPLA flagged metadata and generate the records
       q = "select distinct m.id, m.pid from metadata m"
       q << " inner join units u on u.metadata_id = m.id"
       q << " where parent_metadata_id = 0 and dpla = 1 and date_dl_ingest is not null"
       q << " and u.include_in_dl=1"
       cnt = 0
       Metadata.find_by_sql(q).each do |meta|
         out << meta.pid
         cnt +=1
       end
       Rails.logger.info "Found #{cnt} standalone DPLA items"

       # More orphaned items...
       q = "select id,pid from metadata where dpla=1 and parent_metadata_id=0"
       q << " and date_dl_ingest is not null and type='XmlMetadata'"
       cnt = 0
       Metadata.find_by_sql(q).each do |meta|
         out << meta.pid
         cnt +=1
       end
       Rails.logger.info "Found #{cnt} other DPLA items"

      Rails.logger.info "TOTAL DPLA items found: #{out.length}"
      render plain: out.join(", ")
   end
end