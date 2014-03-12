#!/bin/sh

export RAILS_ENV=production

/usr/local/projects/tracksys/script/poller start -- process-group=technical_metadata_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=cache_management_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=copy_archived_files_to_production_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=order_email_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_order_zip_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=delete_unit_copy_for_deliverable_generation_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=copy_unit_for_deliverable_generation_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=lightweight_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=messages_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=messages_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=send_unit_to_archive_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=dl_ingestion_group_light
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=dl_ingestion_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_dl_deliverables_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_dl_deliverables_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_dl_deliverables_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_patron_deliverables_group
sleep 3
/usr/local/projects/tracksys/script/poller start -- process-group=create_patron_deliverables_group
sleep 3
touch /usr/local/projects/tracksys/tmp/restart.txt
echo "restarting production Rails app tracksys...."
exit 0
