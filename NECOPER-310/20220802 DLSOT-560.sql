--DLSOT-560
select * from all_tables where owner='GELEC' and table_name like '%DOC%';

select * from gelec.ED_DOCUMENTOS where nro_documento='D-22-07-064905'; --id doc 10401519
select * from gelec.ED_DOCUMENTOS where nro_documento='D-22-08-002346'; --id doc 10421257
select * from gelec.ED_DOCUMENTOS where nro_documento='D-22-08-000845'; --id doc 10397582
select * from gelec.ED_DOCUMENTOS where nro_documento='D-22-08-001029'; --id doc 10397586

select * from gelec.ED_DET_DOCUMENTOS_CLIENTES where id_documento=10421257;
select 
    DC.id_doc_cliente, 
    DC.id_documento, 
    DC.cuenta, 
    DC.estado_clie, 
    to_char(DC.fecha_inicio_corte,'DD-MM-YY HH24:MM:SS') ini, 
    to_char(DC.fecha_fin_corte,'DD-MM-YY HH24:MM:SS') fin, 
    to_char(DC.fecha_fin_editable,'DD-MM-YY HH24:MM:SS') manual, 
    DC.operacion,
    dc.usuario, 
    dc.ultima_modificacion
from gelec.ED_DET_DOCUMENTOS_CLIENTES DC
where 
    1=1
    --DC.id_documento=10421257 
    and dc.fecha_inicio_corte is not null
    and DC.fecha_fin_corte is null
    --and dc.operacion is null
    --and DC.cuenta='3532526835'
order by
    dc.id_doc_cliente desc
;


