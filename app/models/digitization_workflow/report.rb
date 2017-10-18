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
   def self.rejections(workflow_id, start_date, end_date)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")

      raw = {}
      q = "select p.id, a.staff_member_id, step_type, s.name, status from assignments a"
      q << " inner join projects p ON p.id = a.project_id"
      q << " inner join steps s on s.id = step_id"
      q << " where a.status != 5 and (s.step_type = 0 or s.step_type = 3 and fail_step_id is not null)"
      q << " and #{filter_q}"
      curr = {}
      staff = StaffMember.all
      Project.connection.execute(q).each do |res|
         project_id = res[0]
         staff_id = res[1]
         user = staff.select { |s| s.id == staff_id }.first
         qa = (res[2] != 0)
         step = res[3]
         status = res[4]
         # puts "P: #{project_id} #{step} by staff #{staff_id}"
         if !raw.has_key? user.full_name
            raw[user.full_name] = {scans: 0, scan_rejects: 0, qa: 0, qa_rejects: 0}
         end
         if qa
            raw[user.full_name][:qa] += 1
            if status == 3
               # puts "  REJECT: Staff #{staff_id} p #{project_id} vs CURR #{curr.to_json}"
               raw[user.full_name][:qa_rejects] +=1
               if curr[:project] == project_id
                  raw[curr[:staff]][:scan_rejects] += 1
                  # puts "      SCANNER #{curr[:staff]} gets a rejection"
               end
            end
         else
            # scan step. reset curr and add stats
            # puts "=================================================="
            # puts "  SCAN: Staff #{staff_id} p #{project_id}"
            curr = {project: project_id, staff: user.full_name}
            raw[user.full_name][:scans] += 1
         end
      end

      raw.each do |k,v|
         raw[k][:avg_scan_reject] = 0
         if v[:scans] > 0
            raw[k][:avg_scan_reject] ="#{(v[:scan_rejects].to_f/v[:scans].to_f*100).ceil}%"
         end
         raw[k][:avg_qa_reject] = 0
         if v[:qa] > 0
            raw[k][:avg_qa_reject] =  "#{(v[:qa_rejects].to_f/v[:qa].to_f*100).ceil}%"
         end
      end

      return raw
   end

   # Generate a json report of problems
   #
   def self.problems(workflow_id, start_date, end_date)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")
      q = "select problem_id,count(n.id) as cnt from notes n"
      q << " inner join projects p on project_id = p.id"
      q << " where note_type=2"
      if !filter_q.blank?
         q << " and #{filter_q}"
      end
      q << " group by problem_id"

      chart = { labels:[], data:[]}
      problems = Problem.all.order(id: :asc)
      problems.each { |p| chart[:labels] << p.label }
      Project.connection.execute(q).each do |res|
         chart[:data] << res[1]
      end

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
         mf_count = res[3]
         chart[:raw][cat.name][:mins] += mins
         chart[:raw][cat.name][:mf] += mf_count
         chart[:raw][cat.name][:units] += 1
      end

      # massage raw data into chart.js format; each workflow is a new dataset
      chart[:labels].each do |cat|
         avg = 0
         if chart[:raw][cat][:mf] > 0
            avg = (chart[:raw][cat][:mins].to_f / chart[:raw][cat][:mf].to_f).ceil
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
