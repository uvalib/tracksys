class Statistic < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true
   validates :value, presence: true

   def self.image_count( location, start_date, end_date = nil)
      query = ""
      if location == :all
         query = "select count(id) from master_files i"
      elsif location == :dl
         query = "select count(id) from master_files i where i.date_dl_ingest is not null"
      elsif location == :dpla
         query = "select count(i.id) from master_files i inner join metadata m on i.metadata_id=m.id and m.dpla=1"
      else
         raise "Invalid location specified #{location}"
      end

      # this will rais an exception if the date is not valid
      start_date.to_date

      if query.include? "where"
         query << " and "
      else
         query << " where "
      end
      query << "i.created_at >= '#{start_date}'"
      if !end_date.nil?
      end_date.to_date
         query << " and i.created_at <= '#{end_date}'"
      end

      return Statistic.connection.execute(query).first.first
   end

   def self.image_size( location, start_date, end_date = nil)
      query = ""
      if location == :all
         query = "select sum(filesize)/1073741824.0 as size_gb from master_files"
      elsif location == :dl
         query = "select sum(filesize)/1073741824.0 as size_gb from master_files where date_dl_ingest is not null"
      else
         raise "Invalid location specified #{location}"
      end

      # this will rais an exception if the date is not valid
      start_date.to_date

      if query.include? "where"
         query << " and "
      else
         query << " where "
      end
      query << "created_at >= '#{start_date}'"
      if !end_date.nil?
      end_date.to_date
         query << " and created_at <= '#{end_date}'"
      end

      return Statistic.connection.execute(query).first.first.to_s
   end

   # Gather a set of statistics
   #
   def self.gather
      # Image count
      cnt =  Statistic.connection.execute("select count(id) from master_files").first.first
      stat = Statistic.find_or_create_by(name: "Image Count")
      stat.update(value: cnt)

      # DL Image count
      cnt =  Statistic.connection.execute("select count(id) from master_files where date_dl_ingest is not null").first.first
      stat = Statistic.find_or_create_by(name: "DL Image Count")
      stat.update(value: cnt)

      # DPLA Image count
      q = "select count(i.id) from master_files i inner join metadata m on i.metadata_id=m.id and m.dpla=1"
      cnt =  Statistic.connection.execute(q).first.first
      stat = Statistic.find_or_create_by(name: "DPLA Image Count")
      stat.update(value: cnt)

      # Total image size
      cnt =  Statistic.connection.execute("select sum(filesize)/1073741824.0 as size_gb from master_files").first.first
      stat = Statistic.find_or_create_by(name: "Total Image Size (GB)")
      stat.update(value: cnt)
      cnt =  Statistic.connection.execute("select sum(filesize)/1073741824.0 as size_gb from master_files where date_dl_ingest is not null").first.first
      stat = Statistic.find_or_create_by(name: "DL Total Image Size (GB)")
      stat.update(value: cnt)
   end
end
