class Report
   # Generate data for a project breakdown by category
   #
   def self.categories
      q= "select c.name, count(p.id) from projects p"
      q << " inner join categories c on c.id = p.category_id"
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
      steps = Workflow.find(workflow_id).steps.where("fail_step_id is not null")
      chart = { labels: steps.pluck("name"), data: [] }
      totals = {}
      steps.each { |s| totals[s.id] = 0}


      # Next, get all of the rejection assignments
      rejections = Assignment.joins(:step, :project)
         .where("steps.step_type=2 and projects.workflow_id=#{workflow_id.to_i}")
      total_assign = Assignment.joins(:project)
         .where("projects.workflow_id=#{workflow_id.to_i}").count

      # figure out which QA step was rejected
      rejections.each do |r|
         reject_step_id = r.step_id
         qa = steps.select { |s| s.fail_step_id == reject_step_id}
         totals[qa.first.id] += 1
      end

      chart[:data] = totals.values
      chart[:total_rejects] = rejections.count
      chart[:total_assigments] = total_assign

      return chart
   end

   # Generate a json report of problems
   #
   def self.problems(start_date, end_date)
      date_p = []
      date_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      date_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      date_q = date_p.join(" and ")
      q = "select problem_id,count(n.id) as cnt from notes n"
      q << " inner join projects p on project_id = p.id"
      q << " where note_type=2"
      if !date_q.blank?
         q << " and #{date_q}"
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
   def self.avg_times(start_date, end_date)
      date_p = []
      date_p << "p.finished_at >= #{sanitize(start_date)}" if !start_date.blank?
      date_p << "p.finished_at <= #{sanitize(end_date)}" if !end_date.blank?
      date_q = date_p.join(" and ")
      time_sql = "select project_id, sum(duration_minutes) as total_mins from assignments group by project_id"
      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select p.id, p.category_id, p.workflow_id, a.total_mins, m.cnt from projects p"
      q << " left join (#{time_sql}) a on p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " where p.finished_at is not null"
      if !date_q.blank?
         q << " and #{date_q}"
      end
      q << " group by p.id  order by category_id, workflow_id"
      results = Project.connection.execute(q)

      # build data structure to hold report
      categories = Category.all
      workflows = Workflow.all
      data = []
      out = {labels:[], datasets:[]}
      categories.each do |cat|
         out[:labels] << cat.name
         wf_data = []
         workflows.each do |wf|
            wf_data << { workflow: wf.id, name: wf.name, mins: 0, mf: 0, units: 0}
         end
         data << { category: cat.id, workflows: wf_data }
      end
      workflows.each do |wf|
         out[:datasets] << {label: wf.name, data:[] }
      end

      # walk results and fill in report
      cnt  =0
      results.each do |res|
         cnt += 1
         cat_id = res[1]
         wf_id = res[2]
         mins = res[3]
         mf_count = res[4]
         data.each do |d|
            next if d[:category] != cat_id
            d[:workflows].each do |wf|
               next if wf[:workflow] != wf_id
               wf[:mins] += mins
               wf[:mf] += mf_count
               wf[:units] += 1
            end
         end
      end

      # massage raw data into chart.js format; each workflow is a new dataset
      data.each do |d|
         hit = categories.select { |c| c.id == d[:category] }
         d[:category] = hit.first.name
         d[:workflows].each do |wf|
            wf_id = wf[:workflow]
            avg = 0
            avg = (wf[:mins].to_f / wf[:mf].to_f).ceil if wf[:mf] > 0

            # Add this data to the right dataset
            # data in the dataset is sorted by asc category
            out[:datasets][wf_id-1][:data] << avg
         end
      end

      out[:raw] = data
      return out
   end

   private
   def self.sanitize(text)
      return ActiveRecord::Base::connection.quote(text)
   end
end
