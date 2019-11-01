class Report
   # Generate data for on-time vs late deliveries for a year
   #
   def self.deliveries(year)
      orders = Order.patron_requests.where("order_status=? and date_completed like '#{year.to_i}%'", "completed")
      months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      chart = { labels:months, ontime:[], late:[], total: [] }
      data = {}
      orders.each do |o|
         month_num = o.date_completed.strftime("%m").to_i
         if !data.has_key? month_num
            data[month_num] = {ontime: 0, late: 0}
         end
         if o.date_completed > o.date_due
            data[month_num][:late] += 1
         else
            data[month_num][:ontime] += 1
         end
      end
      Hash[ data.sort_by { |key, val| key } ].each do |k,v|
         chart[:ontime] <<  v[:ontime]
         chart[:late] <<  v[:late]
         chart[:total] <<  (v[:late]+v[:ontime])
      end
      return chart
   end

   # Generate data for a productivity (units/masterfiles complete within timeframe per category)
   #
   def self.productivity(workflow_id, start_date, end_date)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")

      q= "select c.name, count(p.id) from projects p"
      q << " inner join categories c on c.id = p.category_id"
      q << " where finished_at is not null and #{filter_q}"
      q << " group by c.id"

      chart = { labels:[], data:[]}
      total = 0
      Project.connection.execute(q).each do |res|
         chart[:labels] << res[0]
         chart[:data] << res[1]
         total += res[1]
      end
      chart[:total] = total
      return chart
   end

   # Generate a json report of rejections / student / workflow
   #
   def self.staff_rates(workflow_id, start_date, end_date, sort_by=nil, sort_dir=nil)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")

      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select a.step_id,s.owner_type,sm.last_name,sm.first_name,"
      q << " duration_minutes, m.unit_id, m.cnt from assignments a"
      q << " inner join steps s on s.id = a.step_id"
      q << " inner join projects p on p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " inner join staff_members sm on sm.id = staff_member_id where "
      q << "#{filter_q}"
      data = {}
      Project.connection.execute(q).each do |res|
         step = { id: res[0], owner_type: res[1] }
         staff = "#{res[2]}, #{res[3]}"
         dur = res[4]
         dur = 5 if dur.nil?
         unit_id = res[5]
         pages = res[6]
         if !data.has_key? staff
            data[staff] = {
               scan_units:[], scan_images: 0, scan_time: 0, scan_rate: 0,
               qa_units:[], qa_images: 0, qa_time: 0, qa_rate: 0}
         end

         # user step & owner type to deterime if this is a QA step or a SCAN step
         # All Scanning is done by either Any (0), prior (1) or the original (3) user
         # QA is always done by a unique(2) or spervisor (4) user
         if step[:owner_type] == 2 || step[:owner_type] == 4
            # QA Step
            if !data[staff][:qa_units].include? unit_id
               data[staff][:qa_units] << unit_id
               data[staff][:qa_images] += pages
            end
            data[staff][:qa_time] += dur
            data[staff][:qa_rate] = (data[staff][:qa_images].to_f/data[staff][:qa_time].to_f).round(3)
         else
            # Scan Step
            if !data[staff][:scan_units].include? unit_id
               data[staff][:scan_units] << unit_id
               data[staff][:scan_images] += pages
            end
            data[staff][:scan_time] += dur
            data[staff][:scan_rate] = (data[staff][:scan_images].to_f/data[staff][:scan_time].to_f).round(3)
         end
      end

      # flatten hash out to array of objects and filter out unnecessary data (unit info)
      out = []
      data.each do |k,v|
         out << {
            staff: k, scan_images: v[:scan_images], scan_time: v[:scan_time], scan_rate: v[:scan_rate],
            qa_images: v[:qa_images], qa_time: v[:qa_time], qa_rate: v[:qa_rate]
         }
      end

      # Return sorted results (if requested)
      return out if sort_by.nil? || sort_dir.nil?
      return out.sort_by { |row| row[sort_by.to_sym] }.reverse! if sort_dir == "desc"
      return out.sort_by { |row| row[sort_by.to_sym] }
   end

   # Generate a json report of rejections / student / workflow
   #
   def self.rejections(workflow_id, start_date, end_date, sort_by, sort_dir)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")

      # NOTES: The student that was originally assigned to scan (step type = 0)
      # is always the one responsible when QA steps (type=3) are rejected
      raw = {}
      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select p.id, a.staff_member_id, step_type, s.name, status, m.cnt from assignments a"
      q << " inner join projects p ON p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " inner join steps s on s.id = step_id"
      q << " where a.status != 5 and (s.step_type = 0 or fail_step_id is not null)" # only QA and finalize have fail steps
      q << " and #{filter_q}"
      curr = {}
      staff = StaffMember.all
      Project.connection.execute(q).each do |res|
         project_id = res[0]
         staff_id = res[1]
         qa = (res[2] != 0)
         step = res[3]
         status = res[4]
         mf_cnt = res[5]
         if !raw.has_key? staff_id
            raw[staff_id] = {scans: 0, mf_count: 0, scan_reject: 0, qa: 0, qa_reject: 0}
         end
         if qa
            raw[staff_id][:qa] += 1
            if status == 3
               raw[staff_id][:qa_reject] +=1
               if curr[:project] == project_id
                  raw[curr[:staff]][:scan_reject] += 1
               end
            end
         else
            # scan step. reset curr and add stats
            curr = {project: project_id, staff: staff_id}
            raw[staff_id][:scans] += 1
            raw[staff_id][:mf_count] += mf_cnt
         end
      end

      # Flatten results into array of objects and add rates
      out = []
      raw.each do |k,v|
         project_scan_rate = 0
         if v[:scans] > 0
            project_scan_rate = (v[:scan_reject].to_f/v[:scans].to_f).round(3)
         end
         image_scan_rate = 0
         if v[:mf_count] > 0
            image_scan_rate = (v[:scan_reject].to_f/v[:mf_count].to_f).round(3)
         end
         qa_rate = 0
         if v[:qa] > 0
            qa_rate =  (v[:qa_reject].to_f/v[:qa].to_f*100).ceil
         end

         user = staff.select { |s| s.id == k }.first
         username = "#{user.last_name}, #{user.first_name}"

         out <<  {
            staff_id: k, staff: username, scan_count: v[:scans], mf_count: v[:mf_count],
            scan_reject: v[:scan_reject], project_scan_rate: project_scan_rate,
            image_scan_rate: image_scan_rate, qa_count: v[:qa], qa_reject: v[:qa_reject], qa_rate: qa_rate }
      end

      return out if sort_by.nil? || sort_dir.nil?
      return out.sort_by { |row| row[sort_by.to_sym] }.reverse! if sort_dir == "desc"
      return out.sort_by { |row| row[sort_by.to_sym] }
   end

   # Generate a json report of problems
   #
   def self.problems(workflow_id, start_date, end_date)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")
      q = "select problem_id,count(n.id) as cnt from notes n"
      q << " inner join notes_problems np on np.note_id = n.id"
      q << " inner join problems pb on pb.id = np.problem_id"
      q << " inner join projects p on project_id = p.id"
      q << " where note_type=2 and pb.label <> 'Filesystem' and pb.label <> 'Finalization'"
      if !filter_q.blank?
         q << " and #{filter_q}"
      end
      q << " group by problem_id"

      chart = { labels:[], data:[]}
      problems = Problem.non_automation
      problems.each { |p| chart[:labels] << p.label }
      raw = {}
      problems.each { |p| raw[p.id] =0 }
      Project.connection.execute(q).each do |res|
         raw[res[0]] = res[1]
      end
      chart[:data] = raw.values

      return chart
   end

   # Generate a JSON report of average time per page per workflow/category
   #
   def self.avg_times(workflow_id, start_date, end_date)
      filter_p = []
      filter_p << "p.workflow_id = #{workflow_id.to_i}"
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")
      time_sql = "select project_id, sum(duration_minutes) as total_mins from assignments group by project_id"
      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select p.id, p.category_id, a.total_mins, m.cnt from projects p"
      q << " left join (#{time_sql}) a on p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " where p.finished_at is not null"
      if !filter_q.blank?
         q << " and #{filter_q}"
      end
      q << " group by p.id  order by category_id, workflow_id"
      results = Project.connection.execute(q)

      # build data structure to hold report
      chart = {labels:[], data: [], raw: {} }
      categories = Category.all
      categories.each do |c|
          chart[:raw][c.name] = {mins: 0, mf:0, units: 0}
          chart[:labels] << c.name
       end

      # walk results and fill in raw data
      results.each do |res|
         cat_id = res[1]
         cat = categories.select { |c| c.id == cat_id }.first
         mins = res[2]
         mins = 0 if mins.nil?
         mf_count = res[3]
         chart[:raw][cat.name][:mins] += mins
         chart[:raw][cat.name][:mf] += mf_count
         chart[:raw][cat.name][:units] += 1
      end

      # massage raw data into chart.js format; each workflow is a new dataset
      chart[:labels].each do |cat|
         avg = 0.0
         if chart[:raw][cat][:mf] > 0
            avg = (chart[:raw][cat][:mins].to_f / chart[:raw][cat][:mf].to_f).round(2)
         end
         chart[:data] << avg
      end

      return chart
   end

   private
   def self.sanitize(text)
      return ActiveRecord::Base::connection.quote(text)
   end
end
