class Report
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

   # Generate data for a project breakdown by category
   #
   def self.categories(workflow_id, start_date, end_date)
      filter_p = ["p.workflow_id=#{workflow_id.to_i}"]
      filter_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")

      q= "select c.name, count(p.id) from projects p"
      q << " inner join categories c on c.id = p.category_id"
      q << " where #{filter_q}"
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

   # Generate a json report of rejections / step / workflow
   #
   def self.rejections(workflow_id, start_date, end_date)
      # first get all of the QA Steps for the workflow. These are the chart labels
      # They are also used to identify with QA step is associated with an error assignment
      steps = Workflow.find(workflow_id).steps.where("fail_step_id is not null")
      chart = { labels: steps.pluck("name"), data: [], raw: {} }
      totals = {}
      steps.each do |s|
         totals[s.id] = 0
         chart[:raw][s.name] = {rejections: 0, time: 0}
      end

      filter_p = []
      filter_p << "assignments.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      filter_p << "assignments.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      filter_q = filter_p.join(" and ")


      # Next, get all of the rejection assignments and the total of all assignments
      # Note: step type 2 is an error step
      rejections = Assignment.includes(:staff_member).joins(:step, :project)
         .where("steps.step_type=2 and projects.workflow_id=#{workflow_id.to_i} and #{filter_q}")
      total_assign = Assignment.joins(:project)
         .where("projects.workflow_id=#{workflow_id.to_i} and #{filter_q}").count

      # figure out which QA step was rejected
      users = {}
      rejections.each do |r|
         reject_step_id = r.step_id
         qa = steps.select { |s| s.fail_step_id == reject_step_id}
         totals[qa.first.id] += 1

         # track some raw rejection data to display in a data table along with the chart
         chart[:raw][qa.first.name][:rejections] += 1
         chart[:raw][qa.first.name][:time] += r.duration_minutes if !r.duration_minutes.nil?

         # the owner of the error step is always the original owner of the work
         # use this to track how many times each staff member has had their work rejected
         name =  r.staff_member.full_name
         if !users.has_key? name
            users[name] = 0
         end
         users[name] += 1
      end
      users = users.sort_by {|name, cnt| cnt}
      users = users.reverse[0...5].to_h

      top_rejectors = {}
      raw = Assignment.includes(:staff_member).joins(:project)
         .where("status=3 and projects.workflow_id=#{workflow_id.to_i} and #{filter_q}")
         .group(:staff_member_id).select('staff_member_id, COUNT(assignments.id) as cnt').order("cnt desc").limit(5).to_a
      raw.each do |r|
         top_rejectors[r.staff_member.full_name] = r.cnt
      end

      chart[:top_rejectors] = top_rejectors
      chart[:most_rejected] = users
      chart[:data] = totals.values
      chart[:total_rejects] = rejections.count
      chart[:total_assigments] = total_assign
      chart[:reject_percent] = ((chart[:total_rejects].to_f/total_assign.to_f)*100.0).ceil

      return chart
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
