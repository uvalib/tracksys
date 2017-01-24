# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

wf = Workflow.create(name: 'Standard', description: "Standard TrackSys workflow")
Step.create( workflow: wf, sequence: 1, name: "Scan", description: "Scan all materials",
             start_dir: "scan/10_raw", finish_dir: "scan/10_raw")
Step.create( workflow: wf, sequence: 2, name: "Process", description: "Crop, rotate and process raw scans",
             start_dir: "scan/10_raw", finish_dir: "scan/40_first_QA")
Step.create( workflow: wf, sequence: 3, name: "First QA", description: "Inital QA pass",
             start_dir: "scan/40_first_QA", finish_dir: "scan/50_create_metadata")
Step.create( workflow: wf, sequence: 4, name: "Build Catalog", description: "Build catalog file from processed images",
             start_dir: "scan/50_create_metadata", finish_dir: "scan/50_create_metadata")
Step.create( workflow: wf, sequence: 5, name: "Create Metadata", description: "Create image metadata",
             start_dir: "scan/50_create_metadata", finish_dir: "scan/70_second_QA")
Step.create( workflow: wf, sequence: 6, name: "Second QA", description: "Secondary QA pass",
             start_dir: "scan/70_second_qa", finish_dir: "scan/80_final_qa")
Step.create( workflow: wf, sequence: 7, name: "Final QA", description: "Final QA pass",
             start_dir: "scan/80_final_qa", finish_dir: "scan/100_finalization")
Step.create( workflow: wf, sequence: 8, name: "Finalize", description: "Supervisor QA and ready for ingest",
             start_dir: "scan/100_finalization", finish_dir: "finalization/10_dropoff")
