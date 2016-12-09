class Statistic < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true
   validates :value, presence: true

   def self.unit_count( type=:all, user=:all, start_date=nil, end_date = nil)
      raise "Invalid unit type #{type}" if type != :all && type != :archived && type != :unarchived
      raise "Invalid user type #{user}" if user != :all && user != :student && user != :faculty && user != :staff && user != :nonuva
      query = "select count(u.id) from units u"
      if user != :all
         query << " inner join orders o on o.id=u.order_id"
         query << " inner join customers c on c.id = o.customer_id"
         query << " inner join academic_statuses a on a.id = c.academic_status_id"
      end

      conditions = []
      conditions << "u.date_archived is not null" if type == :archived
      conditions << "u.date_archived is null" if type == :unarchived

      conditions << "a.id = 1" if user == :nonuva
      conditions << "a.id = 4" if user == :staff
      conditions << "a.id = 5" if user == :faculty
      conditions << "a.id > 5" if user == :student

      if !start_date.nil?
         start_date.to_date
         conditions << "u.created_at >= '#{start_date}'"
         if !end_date.nil?
         end_date.to_date
            conditions << "u.created_at <= '#{end_date}'"
         end
      end

      if !conditions.empty?
         query << " where " << conditions.join(" and ")
      end

      return Statistic.connection.execute(query).first.first.to_i
   end

   def self.image_count( location=:all, start_date=nil, end_date = nil)
      raise "Invalid location #{location}" if location != :all && location != :dl && location != :dpla

      query = "select count(i.id) from master_files i"
      conditions = []
      conditions << "i.date_dl_ingest is not null" if location == :dl
      query << " inner join metadata m on i.metadata_id=m.id and m.dpla=1" if location == :dpla

      if !start_date.nil?
         start_date.to_date
         conditions << "created_at >= '#{start_date}'"
         if !end_date.nil?
         end_date.to_date
            conditions << "created_at <= '#{end_date}'"
         end
      end

      if !conditions.empty?
         query << " where " << conditions.join(" and ")
      end

      return Statistic.connection.execute(query).first.first
   end

   def self.image_size( location=:all, start_date=nil, end_date = nil)
      raise "Invalid location #{location}" if location != :all && location != :dl

      query = "select sum(filesize)/1073741824.0 as size_gb from master_files"
      conditions = []
      conditions << "date_dl_ingest is not null" if location == :dl

      if !start_date.nil?
         start_date.to_date
         conditions << "created_at >= '#{start_date}'"
         if !end_date.nil?
         end_date.to_date
            conditions << "created_at <= '#{end_date}'"
         end
      end

      if !conditions.empty?
         query << " where " << conditions.join(" and ")
      end
      return Statistic.connection.execute(query).first.first.to_f
   end

   def self.metadata_count(type=:all, location=:all, start_date=nil, end_date=nil)
      raise "Invalid metadata type #{type}" if type != :all && type != :sirsi && type != :xml
      raise "Invalid location #{location}" if location != :all && location != :dl && location != :dpla

      query = "select count(*) from metadata"
      conditions = []
      conditions << "type='SirsiMetadata'" if type == :sirsi
      conditions << "type='XmlMetadata'" if type == :xml

      conditions << "date_dl_ingest is not null" if location == :dl
      conditions << "dpla = true" if location == :dpla

      if !start_date.nil?
         start_date.to_date
         conditions << "created_at >= '#{start_date}'"
         if !end_date.nil?
         end_date.to_date
            conditions << "created_at <= '#{end_date}'"
         end
      end

      if !conditions.empty?
         query << " where " << conditions.join(" and ")
      end
      return Statistic.connection.execute(query).first.first.to_i
   end

   # Gather a set of statistics
   #
   def self.snapshot
      # Image counts
      cnt =  Statistic.image_count :all
      stat = Statistic.find_or_create_by(name: "Image Count")
      stat.update(value: cnt, group: "image")
      cnt =  Statistic.image_count :dl
      stat = Statistic.find_or_create_by(name: "DL Image Count")
      stat.update(value: cnt, group: "image")
      cnt =  Statistic.image_count :dpla
      stat = Statistic.find_or_create_by(name: "DPLA Image Count")
      stat.update(value: cnt, group: "image")

      # Total image size
      cnt =  Statistic.image_size :all
      stat = Statistic.find_or_create_by(name: "Total Image Size (GB)")
      stat.update(value: cnt, group: "size")
      cnt =  Statistic.image_size :dl
      stat = Statistic.find_or_create_by(name: "DL Total Image Size (GB)")
      stat.update(value: cnt, group: "size")

      # unit counts
      cnt =  Statistic.unit_count :all
      stat = Statistic.find_or_create_by(name: "Unit Count")
      stat.update(value: cnt, group: "unit")
      cnt =  Statistic.unit_count :archived
      stat = Statistic.find_or_create_by(name: "Archived Unit Count")
      stat.update(value: cnt, group: "unit")
      cnt = Statistic.unit_count :unarchived
      stat = Statistic.find_or_create_by(name: "Unarchived Unit Count")
      stat.update(value: cnt, group: "unit")
      cnt =  Statistic.unit_count :archived, :faculty
      stat = Statistic.find_or_create_by(name: "Faculty Archived Unit Count")
      stat.update(value: cnt, group: "unit")
      cnt =  Statistic.unit_count :archived, :staff
      stat = Statistic.find_or_create_by(name: "Staff Archived Unit Count")
      stat.update(value: cnt, group: "unit")
      cnt =  Statistic.unit_count :archived, :student
      stat = Statistic.find_or_create_by(name: "Student Archived Unit Count")
      stat.update(value: cnt, group: "unit")

      # Metadata counts
      cnt = Statistic.metadata_count
      stat = Statistic.find_or_create_by(name: "Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :sirsi
      stat = Statistic.find_or_create_by(name: "SIRSI Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :xml
      stat = Statistic.find_or_create_by(name: "XML Metadata Count")
      stat.update(value: cnt, group: "metadata")

      # Metadata DL counts
      cnt = Statistic.metadata_count :all, :dl
      stat = Statistic.find_or_create_by(name: "DL Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :sirsi, :dl
      stat = Statistic.find_or_create_by(name: "DL SIRSI Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :xml, :dl
      stat = Statistic.find_or_create_by(name: "DL XML Metadata Count")
      stat.update(value: cnt, group: "metadata")

      # Metadata DPLA counts
      cnt = Statistic.metadata_count :all, :dpla
      stat = Statistic.find_or_create_by(name: "DPLA Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :sirsi, :dpla
      stat = Statistic.find_or_create_by(name: "DPLA SIRSI Metadata Count")
      stat.update(value: cnt, group: "metadata")
      cnt = Statistic.metadata_count :xml, :dpla
      stat = Statistic.find_or_create_by(name: "DPLA XML Metadata Count")
      stat.update(value: cnt, group: "metadata")
   end
end
