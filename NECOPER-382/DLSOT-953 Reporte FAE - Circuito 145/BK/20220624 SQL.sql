select 
  fc.cuenta, 
  (select upper(trim(nombre||chr(32)||apellido)) from GELEC.ed_paciente_cliente where cuenta=fc.cuenta and rownum=1) paciente,
  upper(trim(cc.calle||chr(32)||cc.nro||chr(32)||trim(cc.piso_dpto))||chr(32)||chr(40)||trim(cc.localidad)||chr(41)) direccion, 
  cc.medidor, 
  cc.region, 
  (select trim(area_operativa) from NEXUS_CCYB.clientes_ccyb where cuenta=fc.cuenta) zona, 
  cc.ct, 
  fe.serie, 
  fe.potencia, 
  fe.capacidad, 
  fc.instalacion, 
  fc.retiro, 
  'ORD-'||to_char(fo.inicio,'YYYY-MM')||'-'||lpad(fo.id,5,0) nro_orden,
  ot.descripcion tipo, 
  fo.usuario, 
  fo.inicio, 
  fo.fin, 
  ef.descripcion estado, 
  fo.abonada, 
  fo.fecha_abonada
from 
  GELEC.ed_fae_cliente fc, 
  GELEC.ed_ordenes fo, 
  GELEC.ed_clientes cc, 
  GELEC.ed_equipo_fae fe, 
  GELEC.ed_tipo_orden ot, 
  GELEC.ed_estado_fae ef
where
  1=1
  and fc.id=fo.id_fae_cliente
  and fc.cuenta=cc.cuenta
  and fc.id_fae=fe.id(+)
  and fo.id_tipo=ot.id
  and fo.id_estado=ef.id
order by
  fc.cuenta, 
  fo.inicio
;