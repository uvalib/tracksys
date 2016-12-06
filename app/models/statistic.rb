class Statistic < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true
   validates :value, presence: true

   def self.unit_count( user_type, start_date=nil, end_date = nil)
      query = ""
      if user_type == :all
         query = "select count(u.id) from units u where u.date_archived is not null"
      else
         query = "select count(u.id) from units u"
         query << " inner join orders o on o.id=u.order_id"
         query << " inner join customers c on c.id = o.customer_id"
         query << " inner join academic_statuses a on a.id = c.academic_status_id"
         query << " where u.date_archived is not null"
         if user_type == :faculty #5
            query << " and a.id = 5"
         elsif user_type == :staff #4
            query << " and a.id = 4"
         elsif user_type == :students #6-8
            query << " and a.id > 5"
         else
            raise "Invalid user type specified #{user_type}"
         end
      end

      if !start_date.nil?
         start_date.to_date
         query << " and u.created_at >= '#{start_date}'"
         if !end_date.nil?
         end_date.to_date
            query << " and u.created_at <= '#{end_date}'"
         end
      end

      return Statistic.connection.execute(query).first.first.to_i
   end

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

      return Statistic.connection.execute(query).first.first.to_f
   end

   # Gather a set of statistics
   #
   # Metadata:
   #
   # Total # of metadata records (now, on [date], added [date range])
   # Total # of (SIRSI, XML) metadata records (now, on [date], added [date range])
   # Total # of metadata records in DL (now, on [date], added [date range])
   # Total # of (SIRSI, XML) metadata records in DL (now, on [date], added [date range])
   # Total # of metadata records marked for DPLA (now, on [date], added [date range])
   # Total # of (SIRSI, XML) metadata records marked for DPLA (now, on [date], added [date range])
   #
   # Units:
   # # of units (total, archived, unarchived)
   # # of units archived as of [date], over [date range]
   # # of units archived for (faculty, students, staff) (now, on [date], [date range])
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

      # unit counts
      unit_cnt =  Statistic.connection.execute("select count(id) from units").first.first.to_i
      stat = Statistic.find_or_create_by(name: "Unit Count")
      stat.update(value: unit_cnt)
      cnt =  Statistic.connection.execute("select count(id) from units where date_archived is not null").first.first.to_i
      stat = Statistic.find_or_create_by(name: "Archived Unit Count")
      stat.update(value: cnt)
      stat = Statistic.find_or_create_by(name: "Unarchived Unit Count")
      stat.update(value: unit_cnt-cnt)
   end
end
