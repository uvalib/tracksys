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
end
