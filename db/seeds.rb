# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

Step.connection.execute("truncate steps")
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
fail_qa1 = Step.create( workflow: wf, name: "Fail QA 1", description: "Rescan after failing QA 1", step_type: :fail)

qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass; student B 100% check",
   start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_qa")
fail_qa2 = Step.create( workflow: wf, name: "Fail QA 2", description: "Rescan after failing QA 2", step_type: :fail)

final_qa = Step.create( workflow: wf, name: "Final QA", description: "Final QA pass (student C 30% check)",
   start_dir: "scan/80_final_qa", finish_dir: "scan/80_final_qa")
fail_qa3 = Step.create( workflow: wf, name: "Fail Final QA", description: "Rescan after failing final QA", step_type: :fail)

finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
   step_type: :finish, start_dir: "scan/80_final_qa", finish_dir: "finalization/10_dropoff")
fail_qa4 = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA", step_type: :fail)

scan.update(next_step: process)
process.update(next_step: catalog)
catalog.update(next_step: metdata)
metdata.update(next_step: qa1)
qa1.update(next_step: qa2, fail_step: fail_qa1)
qa2.update(next_step: final_qa, fail_step: fail_qa2)
final_qa.update(next_step: finalize, fail_step: fail_qa3)
finalize.update(fail_step: fail_qa4)
