select 
  fc.cuenta, 
  (select upper(trim(nombre||chr(32)||apellido)) from GELEC.ed_paciente_cliente where cuenta=fc.cuenta and rownum=1) paciente,
  upper(trim(cc.calle||chr(32)||cc.nro||chr(32)||trim(cc.piso_dpto))||chr(32)||chr(40)||trim(cc.localidad)||chr(41)) direccion, 
  cc.medidor, 
  CC.REGION, 
  upper((SELECT z.zona FROM NEXUS_GIS.SPRCLIENTS s, nexus_gis.partido_zona z where s.fsclientid=cc.cuenta and s.leveltwoareaid=z.areaid)) zona,
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
  FO.FIN, 
  eo.descripcion estado, 
  fo.abonada, 
  fo.fecha_abonada
from 
  GELEC.ed_fae_cliente fc, 
  GELEC.ed_ordenes fo, 
  GELEC.ed_clientes cc, 
  GELEC.ed_equipo_fae fe, 
  GELEC.ed_tipo_orden ot, 
  GELEC.ED_ESTADO_FAE EF,
  GELEC.ED_ESTADO_ORDENES EO
where
  1=1
  and fc.id=fo.id_fae_cliente
  and fc.cuenta=cc.cuenta
  and fc.id_fae=fe.id(+)
  and fo.id_tipo=ot.id
  AND FO.ID_ESTADO=EF.ID
  and fo.id_estado=eo.id
order by
  fc.cuenta, 
  fo.inicio
;






