# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
Note.connection.execute("truncate notes")
Assignment.connection.execute("truncate assignments")
Task.connection.execute("truncate tasks")
Problem.connection.execute("truncate problems")
Step.connection.execute("truncate steps")

# Common problems
Problem.create([
   { name: 'Incorrect ICC Profile' }, { name: 'Duplicate Image' }, { name: 'Soft Focus' },
   { name: 'Incorrect Metadata' }, { name: 'Other' }])

# Workflow and steps
Workflow.connection.execute("truncate workflows")
wf = Workflow.create(name: 'Standard', description: "Standard TrackSys workflow")

scan = Step.create( workflow: wf, name: "Scan", description: "Scan all materials", propagate_owner: true,
   step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

process = Step.create( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", propagate_owner: true,
   start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

catalog = Step.create( workflow: wf, name: "Build Catalog", description: "Build catalog file from processed images", propagate_owner: true,
   start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

metdata = Step.create( workflow: wf, name: "Create Metadata", description: "Create image metadata",
   start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

qa1 = Step.create( workflow: wf, name: "First QA", description: "Inital QA; student A 100% check",
   start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
fail_qa1 = Step.create( workflow: wf, name: "Fail QA 1", description: "Rescan after failing QA 1", step_type: :error)

qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass; student B 100% check",
   start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_qa")
fail_qa2 = Step.create( workflow: wf, name: "Fail QA 2", description: "Rescan after failing QA 2", step_type: :error)

qa3 = Step.create( workflow: wf, name: "Final QA", description: "Final QA pass (student C 30% check)",
   start_dir: "scan/80_final_qa", finish_dir: "scan/80_final_qa")
fail_qa3 = Step.create( workflow: wf, name: "Fail Final QA", description: "Rescan after failing final QA", step_type: :error)

finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
   step_type: :end, start_dir: "scan/80_final_qa", finish_dir: "finalization/10_dropoff")
fail_qa4 = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA", step_type: :error)

scan.update(next_step_id: process.id)
process.update(next_step_id: catalog.id)
catalog.update(next_step_id: metdata.id)
metdata.update(next_step_id: qa1.id)

# Note: not sure why, but trying to update next and fail without ID
# does not work. Sets only next.
qa1.update(next_step_id: qa2.id, fail_step_id: fail_qa1.id)
fail_qa1.update(next_step_id: qa1.id)

qa2.update(next_step_id: qa3.id, fail_step_id: fail_qa2.id)
fail_qa2.update(next_step_id: qa2.id)

qa3.update(next_step_id: finalize.id, fail_step_id: fail_qa3.id)
fail_qa3.update(next_step_id: qa3.id)

finalize.update(fail_step_id: fail_qa4.id)
fail_qa4.update(next_step_id: finalize.id)
