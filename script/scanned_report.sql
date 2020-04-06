select u.id as unit_id,m.title,m.call_number,IF(m.call_number LIKE 'MSS%', "Yes", "No") as manuscript,
	if(l.container_id is not null,l.container_id, "N/A") as box_id,
	count(f.id) as master_file_count from units u 
	inner join master_files f on f.unit_id = u.id
	inner join metadata m on m.id = u.metadata_id
	left outer join locations l on l.metadata_id = m.id
where u.include_in_dl = 1 
group by u.id;