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
