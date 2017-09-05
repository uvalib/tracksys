namespace :medium_rare_workflow do
   desc "Create medium rare workflow"
   task :create  => :environment do
      base = ENV['base']
      abort("base is required") if base.nil?
      
      wf = Workflow.create!(name: 'Medium Rare', description: "Medium rare workflow")

      scan = Step.create!( workflow: wf, name: "Scan", description: "Scan all materials",
         step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

      process = Step.create!( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", owner_type: :prior_owner,
         start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

      catalog = Step.create!( workflow: wf, name: "Build Catalog", description: "Build catalog file from processed images", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

      metdata = Step.create!( workflow: wf, name: "Create Metadata", description: "Create image metadata", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

      qa1 = Step.create!( workflow: wf, name: "First QA", description: "Inital QA; 100% check", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
      fail_qa1 = Step.create!( workflow: wf, name: "Fail First QA", description: "Rescan after failing first QA", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/70_second_qa")

      qa2 = Step.create!( workflow: wf, name: "Second QA", description: "Secondary QA pass; 100% metadata check, 50% image check", owner_type: :unique_owner,
         start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_QA")
      fail_qa2 = Step.create!( workflow: wf, name: "Fail Second QA", description: "Rescan after failing Second QA", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      finalize = Step.create!( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
         owner_type: :supervisor_owner, step_type: :end, start_dir: "scan/80_final_QA", finish_dir: "finalization/10_dropoff")
      fail_finalize = Step.create!( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA",
         owner_type: :original_owner, step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      scan.update!(next_step_id: process.id)
      process.update!(next_step_id: catalog.id)
      catalog.update!(next_step_id: metdata.id)
      metdata.update!(next_step_id: qa1.id)

      qa1.update!(next_step_id: qa2.id, fail_step_id: fail_qa1.id)
      fail_qa1.update!(next_step_id: qa2.id)

      qa2.update!(next_step_id: finalize.id, fail_step_id: fail_qa2.id)
      fail_qa2.update!(next_step_id: finalize.id)

      finalize.update!(fail_step_id: fail_finalize.id)
      fail_finalize.update!(next_step_id: finalize.id)
   end
end
