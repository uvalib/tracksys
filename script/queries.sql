-- Get all manuscripts
select count(*) from bibls where call_number  like 'MSS%';

-- list of distinct lables and locations
select distinct label from legacy_identifiers;
select distinct location from bibls order by location asc;

-- count of items from special collections
select count(*) from bibls as SC_COUNT where location  not in ("3EAST", "BY-REQUEST", "Carr's Hill", "CATALOGING", "Center for Nursing Historical Inquiry", "CHECK-LOC", "DOC-US", "Heath Sciences Library", "Historical Collections Artifacts", "IVY-BOOK", "IVYANNEX", "JOURNALS", "LAW-IVY", "LOST", "LOSTCLOSED", "On loan from Oberlin College", "ORD-CLOSED", "Owned by Clifton McCleskey in Politics", "Personal Copy of Kathleen Wilson", "Personal Copy--Alison Booth", "personal item", "Personal Slide Collection", "REFATLAS", "REFERENCE", "SLIDES", "UCLA") and location is not NULL;

-- count of manuscript special collections
select count(*) from bibls as CS_MSS_COUNT where location  not in ("3EAST", "BY-REQUEST", "Carr's Hill", "CATALOGING", "Center for Nursing Historical Inquiry", "CHECK-LOC", "DOC-US", "Heath Sciences Library", "Historical Collections Artifacts", "IVY-BOOK", "IVYANNEX", "JOURNALS", "LAW-IVY", "LOST", "LOSTCLOSED", "On loan from Oberlin College", "ORD-CLOSED", "Owned by Clifton McCleskey in Politics", "Personal Copy of Kathleen Wilson", "Personal Copy--Alison Booth", "personal item", "Personal Slide Collection", "REFATLAS", "REFERENCE", "SLIDES", "UCLA") and location is not NULL and call_number like 'MSS%';

-- count images from special collections
select count(*) from master_files mf 
   inner join units u on u.id=mf.unit_id  
   inner join bibls b on u.bibl_id = b.id
where b.location not in ("3EAST", "BY-REQUEST", "Carr's Hill", "CATALOGING", "Center for Nursing Historical Inquiry", "CHECK-LOC", "DOC-US", "Heath Sciences Library", "Historical Collections Artifacts", "IVY-BOOK", "IVYANNEX", "JOURNALS", "LAW-IVY", "LOST", "LOSTCLOSED", "On loan from Oberlin College", "ORD-CLOSED", "Owned by Clifton McCleskey in Politics", "Personal Copy of Kathleen Wilson", "Personal Copy--Alison Booth", "personal item", "Personal Slide Collection", "REFATLAS", "REFERENCE", "SLIDES", "UCLA") and b.location is not NULL;
