-- telefonos para el ticket NECOPER-181
select cuenta,nombre,telefono,tipo_contacto,fecha_baja,
 ( select fulladdress from NEXUS_GIS.SPRCLIENTS where fsclientid = cuenta) as direccion,
  ( select areaname from NEXUS_GIS.SPRCLIENTS,NEXUS_GIS.amareas  where leveloneareaid=areaid and fsclientid = cuenta ) as localidad,
  (  select areaname from NEXUS_GIS.SPRCLIENTS,NEXUS_GIS.amareas  where leveltwoareaid=areaid and fsclientid = cuenta ) as partido
 from GELEC.ED_CONTACTOS_CLIENTES order by cuenta,tipo_contacto,telefono;
 
 
 
select * from all_tables where owner='GELEC' and table_name like '%CONT%';

select * from GELEC.ed_clientes;
SELECT * FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA='0031779024' order by id_tel desc;
SELECT * FROM GELEC.ed_cliente_nota WHERE CUENTA='0031779024';
select * from GELEC.ed_notas where IDDESTINO =10029666;

    
    SELECT 
        C.CUENTA, 
        C.RAZON_SOCIAL NOMBRE, 
        T.TELEFONO, 
        T.TIPO_CONTACTO TIPO, 
        NVL(SUM(N.EFECTIVO),0) EFECTIVO
    FROM 
        GELEC.ED_CLIENTES C, 
        GELEC.ED_CONTACTOS_CLIENTES T,
        GELEC.ED_NOTAS N
    WHERE
      C.CUENTA=T.CUENTA
      AND C.F_BAJA IS NULL
      AND NVL(T.LOG_HASTA,0)=0
      AND T.ID_TEL=N.IDDESTINO(+)
    GROUP BY
      C.CUENTA, C.RAZON_SOCIAL, T.TELEFONO, T.TIPO_CONTACTO
    ORDER BY
      C.CUENTA, NVL( SUM(N.EFECTIVO),0) DESC;


