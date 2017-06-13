# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

Equipment.connection.execute("truncate equipment")
Note.connection.execute("truncate notes")
Category.connection.execute("truncate categories")
Problem.connection.execute("truncate problems")
Assignment.connection.execute("truncate assignments")
Project.connection.execute("truncate project_equipment")
Project.connection.execute("truncate projects")
Step.connection.execute("truncate steps")
Workstation.connection.execute("truncate workstations")
Workstation.connection.execute("truncate workstation_equipment")
Workflow.connection.execute("truncate workflows")

Workstation.create([{name: 'Jefferson'}, {name: 'Washington'}, {name: 'Lincoln'},
   {name: 'Roosevelt'}, {name: 'Cruse'}, {name: 'Flatbed Scanner'}, {name: 'Multispectral Scanner'}])

# Format: type,name,serial
csv_text = File.read(Rails.root.join('data', 'equipment.csv'))
CSV.parse(csv_text, headers: false).each do |row|
   Equipment.create(type: row[0], name: row[1], serial_number: row[2])
end

# Common problems and categories
Category.create([
   { name: 'Bound' }, { name: 'Flat' }, { name: 'Film' },{name: 'Oversize'}, {name: 'Special'}])
Problem.create([
   { name: 'Incorrect ICC Profile' }, { name: 'Duplicate Image' }, { name: 'Soft Focus' },
   { name: 'Incorrect Metadata' }, { name: 'Filesystem Problem' }, { name: 'Finalization Failure' }, { name: 'Other' }])

# STANDARD Workflow and steps (2 phase final QA) ============================================================================================
#
wf = Workflow.create(name: 'Standard', description: "Standard TrackSys workflow")

scan = Step.create( workflow: wf, name: "Scan", description: "Scan all materials",
   step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

process = Step.create( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", owner_type: :prior_owner,
   start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

catalog = Step.create( workflow: wf, name: "Build Catalog", description: "Build catalog file from processed images", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

metdata = Step.create( workflow: wf, name: "Create Metadata", description: "Create image metadata", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

qa1 = Step.create( workflow: wf, name: "First QA", description: "Inital QA; 100% check", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
fail_qa1 = Step.create( workflow: wf, name: "Fail First QA", description: "Rescan after failing first QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/70_second_qa")

qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass; student B 100% check", owner_type: :unique_owner,
   start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_QA")
fail_qa2 = Step.create( workflow: wf, name: "Fail Second QA", description: "Rescan after failing Second QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

qa3 = Step.create( workflow: wf, name: "Final QA 1", description: "Final QA 1; student C 10% check", owner_type: :unique_owner,
   start_dir: "scan/80_final_QA", finish_dir: "scan/80_final_QA")
fail_qa3 = Step.create( workflow: wf, name: "Fail Final QA 1", description: "Rescan after failing final QA 1", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

qa4 = Step.create( workflow: wf, name: "Final QA 2", description: "Final QA 2; student D 10% check", owner_type: :unique_owner,
   start_dir: "scan/80_final_QA", finish_dir: "scan/80_final_QA")
fail_qa4 = Step.create( workflow: wf, name: "Fail Final QA 2", description: "Rescan after failing final QA 2", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
   owner_type: :supervisor_owner, step_type: :end, start_dir: "scan/80_final_QA", finish_dir: "finalization/10_dropoff")
fail_finalize = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA",
   owner_type: :original_owner, step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

scan.update(next_step_id: process.id)
process.update(next_step_id: catalog.id)
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

# SPECIAL Workflow and steps (1 phase final QA) ============================================================================================
#
wf = Workflow.create(name: 'Experimental', description: "Experimental workflow with a one step 30% final QA")

scan = Step.create( workflow: wf, name: "Scan", description: "Scan all materials",
   step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

process = Step.create( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", owner_type: :prior_owner,
   start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

catalog = Step.create( workflow: wf, name: "Build Catalog", description: "Build catalog file from processed images", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

metdata = Step.create( workflow: wf, name: "Create Metadata", description: "Create image metadata", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

qa1 = Step.create( workflow: wf, name: "First QA", description: "Inital QA; 100% check", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
fail_qa1 = Step.create( workflow: wf, name: "Fail First QA", description: "Rescan after failing first QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/70_second_qa")

qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass; student B 100% check", owner_type: :unique_owner,
   start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_QA")
fail_qa2 = Step.create( workflow: wf, name: "Fail Second QA", description: "Rescan after failing Second QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

qa3 = Step.create( workflow: wf, name: "Final QA", description: "Final QA pass; student C 30% check", owner_type: :unique_owner,
   start_dir: "scan/80_final_QA", finish_dir: "scan/80_final_QA")
fail_qa3 = Step.create( workflow: wf, name: "Fail Final QA", description: "Rescan after failing final QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
   owner_type: :supervisor_owner, step_type: :end, start_dir: "scan/80_final_QA", finish_dir: "finalization/10_dropoff")
fail_finalize = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA",
   owner_type: :original_owner, step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

scan.update(next_step_id: process.id)
process.update(next_step_id: catalog.id)
catalog.update(next_step_id: metdata.id)
metdata.update(next_step_id: qa1.id)

qa1.update(next_step_id: qa2.id, fail_step_id: fail_qa1.id)
fail_qa1.update(next_step_id: qa2.id)

qa2.update(next_step_id: qa3.id, fail_step_id: fail_qa2.id)
fail_qa2.update(next_step_id: qa3.id)

qa3.update(next_step_id: finalize.id, fail_step_id: fail_qa3.id)
fail_qa3.update(next_step_id: finalize.id)

finalize.update(fail_step_id: fail_finalize.id)
fail_finalize.update(next_step_id: finalize.id)

# Workflow for SLIDES ============================================================================================
#
wf = Workflow.create(name: 'No Metadata', description: "Abbreviated workflow for items with no metadata, like slides")
scan = Step.create( workflow: wf, name: "Scan", description: "Scan all materials",
   step_type: :start, start_dir: "scan/10_raw", finish_dir: "scan/10_raw")

process = Step.create( workflow: wf, name: "Process", description: "Crop, rotate and process raw scans", owner_type: :prior_owner,
   start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")

catalog = Step.create( workflow: wf, name: "Build Catalog", description: "Build catalog file from processed images", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/40_first_QA")

qa1 = Step.create( workflow: wf, name: "First QA", description: "Inital QA; 100% check", owner_type: :prior_owner,
   start_dir: "scan/40_first_QA", finish_dir: "scan/70_second_qa")
fail_qa1 = Step.create( workflow: wf, name: "Fail First QA", description: "Rescan after failing first QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/70_second_qa")

qa2 = Step.create( workflow: wf, name: "Second QA", description: "Secondary QA pass; student B 100% check", owner_type: :unique_owner,
   start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_QA")
fail_qa2 = Step.create( workflow: wf, name: "Fail Second QA", description: "Rescan after failing Second QA", owner_type: :original_owner,
   step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

finalize = Step.create( workflow: wf, name: "Finalize", description: "Supervisor QA, generate XML, send to finalization directory",
   owner_type: :supervisor_owner, step_type: :end, start_dir: "scan/80_final_QA", finish_dir: "finalization/10_dropoff")
fail_finalize = Step.create( workflow: wf, name: "Fail Supervisor QA", description: "Rescan after failing supervisor QA",
   owner_type: :original_owner, step_type: :error, manual: true, finish_dir: "scan/80_final_QA")

scan.update(next_step_id: process.id)
process.update(next_step_id: catalog.id)
catalog.update(next_step_id: qa1.id)

qa1.update(next_step_id: qa2.id, fail_step_id: fail_qa1.id)
fail_qa1.update(next_step_id: qa2.id)

qa2.update(next_step_id: finalize.id, fail_step_id: fail_qa2.id)
fail_qa2.update(next_step_id: finalize.id)

finalize.update(fail_step_id: fail_finalize.id)
fail_finalize.update(next_step_id: finalize.id)
