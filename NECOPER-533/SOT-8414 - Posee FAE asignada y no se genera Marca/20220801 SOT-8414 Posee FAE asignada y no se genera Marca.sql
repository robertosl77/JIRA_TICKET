-- SOT-8414
select * from all_tables where owner='GELEC' AND TABLE_NAME LIKE '%FAE%';
select * from gelec.ed_marcas where id=7; --id 7 es para fae
select * from gelec.ed_submarcas where id_marca=7; -- id_submarca 5 es no edp (la que corresponde dar de baja con lote)
select * from gelec.ed_marca_cliente where cuenta='2075744238'; -- no hay submarca 5 es decir no edp
SELECT FSCLIENTID, CUSTATT21 FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID='2075744238'; --custatt21 1252 es decir S/D en sprclients no es EDP
select * from nexus_ccyb.clientes_ccyb where cuenta='2075744238'; -- en clientes_ccyb sigue fecha de baja del 3000... es decir para ccyb sigue activo...
select * from gelec.ed_log where log_id in (1,	413944,	413945); -- comprobar que ninguno de los log_id es del lote o de marca
SELECT CUENTA, RAZON_SOCIAL, LOG_DESDE, LOG_HASTA FROM GELEC.ED_CLIENTES C WHERE C.CUENTA = '2075744238' ;
select * from GELEC.ed_estado_fae;

--cantidades
-- total 271
-- activos 161
-- ex fae sin otra fae activa 100

--marca "posee fae" activa
  select cuenta from gelec.ed_marca_cliente 
  where 
    id_marca=7 
    and id_submarca=18 
    and nvl(log_hasta,0)=0
    --and cuenta='8913735327' 
    ;


/*
1	Pendiente
2	Finalizado
3	Fallida
4	Cancelada

1	Pendiente
2	Pendiente de visita
3	Falta adecuar
4	Falta documentacion
5	Finalizada
6	Cancelada
7	Falta adecuar (c/FAE)
8	Visita fallida
9	Rechazada
10	EDP en tramite

select * from GELEC.ed_estado_fae;
select * from GELEC.ed_estado_ordenes;
select * from GELEC.ed_tipo_orden;
select * from GELEC.ed_ordenes where cuenta='6851537738';

*/


select 
    c.cuenta, 
    fc.* 
from 
    GELEC.ed_fae_cliente FC, 
    GELEC.ed_clientes C, 
    gelec.ed_marca_cliente MC
where9
    1=1
    and c.cuenta=fc.cuenta(+)
    and c.cuenta=mc.cuenta
    and id_marca=7
    and id_submarca=18
;
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--clientes con fae retirada, sin fecha de instalacion
  select * from gelec.ed_fae_cliente where id_fae is not null and instalacion is null and retiro is not null;
  
--obtiene la fecha de la instalacion de la fae
  select c.id_fae, o.cuenta, o.fin 
  from gelec.ed_ordenes o, gelec.ed_fae_cliente c 
  where 
      o.id_fae_cliente=c.id 
      and c.cuenta='9881907245' 
      and c.id_fae=92
      and o.id_tipo=1 
      and o.id_estado=2;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- verificar clientes sin fae con marca posee fae
    --clientes nunca fae con marca posee fae
    select * 
    from gelec.ed_clientes c 
    where 
      1=1
      and cuenta not in (select cuenta from gelec.ed_fae_cliente)
      and cuenta in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0);

    --query clientes ex fae, sin fae activa, con marca posee fae
    select * 
    from gelec.ed_fae_cliente 
    where 
      1=1
      and cuenta not in (select cuenta from gelec.ed_fae_cliente where id_fae is not null and instalacion is not null and retiro is null)
      and cuenta in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0);


-- verificar clientes con fae sin marca posee fae
    select *
    from gelec.ed_fae_cliente 
    where 
        id_fae is not null 
        and instalacion is not null 
        and retiro is null
        and cuenta not in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0)
        ;    

--registros de fae duplicados, vacios sin estado cancelado
    select * 
    from gelec.ed_fae_cliente 
    where 
      id not in (select id from gelec.ed_fae_cliente where id_fae is not null and instalacion is not null and retiro is null)
      and ((id_fae is null or instalacion is null or retiro is null) and id_estado<>6)
      ;
  


--PACKAGE GELEC.PKG_FAE
    PROCEDURE asociarfaecliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_fae           IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Asocia FAE_Cliente con id: '
                                     || p_id_fae_cliente
                                     || ' al equipo: '
                                     || p_id_fae, p_usuario);

        UPDATE gelec.ed_fae_cliente fc
        SET
            fc.id_fae = p_id_fae
        WHERE
            fc.id = p_id_fae_cliente;

        COMMIT;
        p_respuesta := 1;
    END;
