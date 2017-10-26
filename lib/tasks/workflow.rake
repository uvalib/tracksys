namespace :workflow do
   desc "Create new workflow for clone projects"
   task :create_clone  => :environment do
      wf = Workflow.create(name: 'Clone', description: "Workflow for cloning existing master files")
      clone = Step.create( workflow: wf, name: "Clone", description: "Identify and clone existing master files",
         step_type: :start, owner_type: :supervisor_owner, manual: true)
      zip = Step.create( workflow: wf, name: "Generate Deliverables", description: "Generate patron .zip deliverables",
         step_type: :end, owner_type: :supervisor_owner, manual: true)
      clone.update(next_step_id: zip.id)
   end

   desc "Create new workflow for manuscript projects"
   task :create_manuscript  => :environment do
      # wf = Workflow.create(name: 'Manuscript', description: "Workflow for manuscripts. Subfolders required.")
      wf = Workflow.find(5)

      scan = Step.create( workflow: wf, name: "Scan", description: "Scan all materials",
         step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

      process = Step.create( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", owner_type: :prior_owner,
         start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

      organize = Step.create( workflow: wf, name: "Organize", description: "Organize files into subdirs named to match physical folders", owner_type: :prior_owner,
         start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

      catalog = Step.create( workflow: wf, name: "Build Catalog", description: "Build catalog file from organized images", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

      metdata = Step.create( workflow: wf, name: "Create Metadata", description: "Create image metadata", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

      qa1 = Step.create( workflow: wf, name: "First QA", description: "Inital QA: 100% check", owner_type: :prior_owner,
         start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
      fail_qa1 = Step.create( workflow: wf, name: "Fail First QA", description: "Rescan after failing first QA", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/70_second_qa")

      qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass: Student B 100% check", owner_type: :unique_owner,
         start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_QA")
      fail_qa2 = Step.create( workflow: wf, name: "Fail Second QA", description: "Rescan after failing Second QA", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      qa3 = Step.create( workflow: wf, name: "Final QA 1", description: "Final QA 1: Student C 10% check", owner_type: :unique_owner,
         start_dir: "scan/80_final_QA", finish_dir: "scan/80_final_QA")
      fail_qa3 = Step.create( workflow: wf, name: "Fail Final QA 1", description: "Rescan after failing final QA 1", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      qa4 = Step.create( workflow: wf, name: "Final QA 2", description: "Final QA 2: Student D 10% check", owner_type: :unique_owner,
         start_dir: "scan/80_final_QA", finish_dir: "scan/80_final_QA")
      fail_qa4 = Step.create( workflow: wf, name: "Fail Final QA 2", description: "Rescan after failing final QA 2", owner_type: :original_owner,
         step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, begin finalization",
         owner_type: :supervisor_owner, step_type: :end, start_dir: "scan/80_final_QA", finish_dir: "finalization/10_dropoff")
      fail_finalize = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA",
         owner_type: :original_owner, step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

      scan.update(next_step_id: process.id)
      process.update(next_step_id: organize.id)
      organize.update(next_step_id: catalog.id)
      catalog.update(next_step_id: metdata.id)
      metdata.update(next_step_id: qa1.id)

      qa1.update(next_step_id: qa2.id, fail_step_id: fail_qa1.id)
      fail_qa1.update(next_step_id: qa2.id)

      qa2.update(next_step_id: qa3.id, fail_step_id: fail_qa2.id)
      fail_qa2.update(next_step_id: qa3.id)

      qa3.update(next_step_id: qa4.id, fail_step_id: fail_qa3.id)
      fail_qa3.update(next_step_id: qa4.id)

      qa4.update(next_step_id: finalize.id, fail_step_id: fail_qa4.id)
      fail_qa4.update(next_step_id: finalize.id)

      finalize.update(fail_step_id: fail_finalize.id)
      fail_finalize.update(next_step_id: finalize.id)
   end

   desc "Split Promlem.filesystem into a few new categories"
   task :problems_split  => :environment do
      unsaved = Problem.find_by(label: "Unsaved")
      if unsaved.nil?
         unsaved = Problem.create(name: "Unsaved Changes", label: "Unsaved")
      end
      filename = Problem.find_by(label: "Filename")
      if filename.nil?
         filename = Problem.create(name: "Bad Filename", label: "Filename")
      end
      metadata = Problem.find_by(label: "Metadata")

      Note.where(problem_id: 5).each do |note|
         if note.note.include?("unsaved changes")
            note.update(problem_id: unsaved.id)
         end
         if note.note.include?("incorrectly named") || note.note.include?("sequence number")
            note.update(problem_id: filename.id)
         end
         if note.note.include?("Missing")
            note.update(problem_id: metadata.id)
         end
      end
   end
end
