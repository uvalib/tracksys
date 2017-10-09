class Report
   # Generate a JSON report of average time per page per workflow/category
   #
   def self.avg_times
      time_sql = "select project_id, sum(duration_minutes) as total_mins from assignments group by project_id"
      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select p.id, p.category_id, p.workflow_id, a.total_mins, m.cnt from projects p"
      q << " left join (#{time_sql}) a on p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " where p.finished_at is not null group by p.id  order by category_id, workflow_id"
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
            wf_data << { workflow: wf.id, mins: 0, mf: 0}
         end
         data << { category: cat.id, workflows: wf_data }
      end
      workflows.each do |wf|
         out[:datasets] << {label: wf.name, data:[] }
      end

      # walk results and fill in report
      results.each do |res|
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
            end
         end
      end

      # massage raw data into chart.js format; each workflow is a new dataset
      data.each do |d|
         d[:workflows].each do |wf|
            wf_id = wf[:workflow]
            avg = 0
            avg = (wf[:mins].to_f / wf[:mf].to_f).ceil if wf[:mf] > 0

            # Add this data to the right dataset
            # data in the dataset is sorted by asc category
            out[:datasets][wf_id-1][:data] << avg 
         end
      end

      return out
   end
end
