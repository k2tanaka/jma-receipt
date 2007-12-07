\set ON_ERROR_STOP

COPY tbl_mstkanri FROM stdin;
0	ORCADB15	R-030500-1-20070708-4	R-030500-1-20070708-4			        		
\.

insert into tbl_mstkanri
select
b.hospnum,
a.kanricd,
a.dbrversion1,
a.dbrversion2,
a.termid,
a.opid,
a.creymd,
a.upymd,
a.uphms
from  tbl_mstkanri a,tbl_sysbase b where a.hospnum = 0 and a.kanricd = 'ORCADB15';

delete from tbl_mstkanri where hospnum = 0 and kanricd = 'ORCADB15';
