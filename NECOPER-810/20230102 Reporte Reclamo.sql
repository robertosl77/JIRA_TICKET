select 
d.nro_documento, 
d.tipo_corte,
r.cuenta, 
r.nombre, 
t.description as tipo_reclamo, 
substr(r.descripcion,1,20), 
r.fecha_creacion_cliente as fecha,
nvl(r.reiteraciones,0) as reiteraciones,
r.ultima_reiteracion as ultimareiteracion,
r.fecha_cierre as fechafinreclamo,
d.region, 
d.zona, 
d.partido, 
d.localidad,
(select count(*) from gelec.ed_cliente_nota cn inner join gelec.ed_notas n on n.id_nota = cn.id_nota where cn.cuenta = r.cuenta and cn.id_documento = r.id_documento and n.id_tipo_nota = 4 and n.efectivo is not null) as llamadas, 
(select count(*) from gelec.ed_cliente_nota cn inner join gelec.ed_notas n on n.id_nota = cn.id_nota where cn.cuenta = r.cuenta and cn.id_documento = r.id_documento and n.id_tipo_nota = 4 and n.efectivo = 1) as llamadasefectivas 
from 
gelec.ed_documentos d,
gelec.ed_reclamos r, 
gelec.ed_tipo_reclamo t
where 
d.id_documento=r.id_documento
and r.id_tipo_reclamo=t.id
and rownum<20 --r.FECHA_CREACION_CLIENTE BETWEEN TO_DATE (:fechaInicio, 'DD/MM/YYYY')  AND TO_DATE (:fechaFin, 'DD/MM/YYYY')
order by r.FECHA_CREACION_CLIENTE desc

;
