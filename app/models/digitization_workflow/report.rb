class Report
   # Generate a JSON report of average time per page per workflow/category
   #
   def self.avg_times
      time_sql = "select project_id, sum(duration_minutes) as total_mins from assignments group by project_id"
      mf_cnt_sql = "select unit_id,count(id) as cnt from master_files group by unit_id"
      q = "select p.id, p.category_id, p.workflow_id, a.total_mins, m.cnt from projects p"
      q << " left join (#{time_sql}) a on p.id = a.project_id"
      q << " left join (#{mf_cnt_sql}) m on m.unit_id = p.unit_id"
      q << " where p.finished_at is not null group by p.id"
      res = Project.connection.execute(q)
      puts res.to_json
   end
end
