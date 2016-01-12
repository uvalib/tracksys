#!/bin/bash
echo 'Starting tech metadata group...'
./script/poller start -- process-group=technical_metadata_group
sleep 1
echo 'Starting cache management group...'
./script/poller start -- process-group=cache_management_group
sleep 1
echo 'Starting copy archive to production group...'
./script/poller start -- process-group=copy_archived_files_to_production_group
sleep 1
echo 'Starting order email group...'
./script/poller start -- process-group=order_email_group
sleep 1
echo 'Starting create order zip group...'
./script/poller start -- process-group=create_order_zip_group
sleep 1
echo 'Starting delete unit copy group...'
./script/poller start -- process-group=delete_unit_copy_for_deliverable_generation_group
sleep 1
echo 'Starting copy unit deliverable group...'
./script/poller start -- process-group=copy_unit_for_deliverable_generation_group
sleep 1
echo 'Starting lightweight group...'
./script/poller start -- process-group=lightweight_group
sleep 1
echo 'Starting message group 1...'
./script/poller start -- process-group=messages_group
sleep 1
echo 'Starting messages group 2...'
./script/poller start -- process-group=messages_group
sleep 1
echo 'Starting unit to archive group...'
./script/poller start -- process-group=send_unit_to_archive_group
sleep 1
echo 'Starting dl ingest group light...'
./script/poller start -- process-group=dl_ingestion_group_light
sleep 1
echo 'Starting dl ingestion group...'
./script/poller start -- process-group=dl_ingestion_group
sleep 1
echo 'Starting dl deliverables group 1...'
./script/poller start -- process-group=create_dl_deliverables_group
sleep 1
echo 'Starting dl deliverables group 2...'
./script/poller start -- process-group=create_dl_deliverables_group
sleep 1
echo 'Starting dl deliverables group 3...'
./script/poller start -- process-group=create_dl_deliverables_group
sleep 1
echo 'Starting patron deliverables group 1...'
./script/poller start -- process-group=create_patron_deliverables_group
sleep 1
echo 'Starting patron deliverables group 2...'
./script/poller start -- process-group=create_patron_deliverables_group
