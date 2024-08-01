set serveroutput on
declare
	--autor: rsleiva@edenor.com
	--fecha: 03/08/2022
	--
	cursor cuentas is (
  
    select * from (  
        select 
            fc.*, 
            (select fin from gelec.ed_ordenes where cuenta=fc.cuenta and id_fae_cliente=fc.id and id_tipo=1 and id_estado=2) fecha_instalacion, 
            (select fin from gelec.ed_ordenes where cuenta=fc.cuenta and id_fae_cliente=fc.id and id_tipo=4 and id_estado=2) fecha_retiro, 
            (select count(1) from gelec.ed_ordenes where cuenta=fc.cuenta and id_fae_cliente=fc.id and fin is null) ordenes_abiertas, 
            (select count(1) from gelec.ed_ordenes where cuenta=fc.cuenta and id_fae_cliente=fc.id) ordenes_cantidad, 
            (select descripcion from gelec.ed_estado_fae where id=fc.id_estado) estado, 
            (select serie from gelec.ed_equipo_fae where id=fc.id_fae) fae
        from 
            gelec.ed_fae_cliente fc
        where
            1=1
            --and fc.id between 300 and 400
      ) f
      where
          1=1
          and not (f.id_fae is not null and f.instalacion is not null and retiro is null and id_estado=5 and f.instalacion=f.fecha_instalacion and f.fecha_retiro is null and f.ordenes_abiertas=0)       --instaladas ok
          and not (f.id_fae is not null and f.instalacion is not null and retiro is not null and id_estado=6 and f.instalacion=f.fecha_instalacion and f.retiro=f.fecha_retiro and f.ordenes_abiertas=0)  --retiradas ok
          and not (f.id_fae is null and f.instalacion is null and f.retiro is null and f.id_estado=6 and f.fecha_instalacion is null and f.fecha_retiro is null and f.ordenes_abiertas=0)                 --canceladas ok
          and not (f.id_fae is null and f.instalacion is null and f.retiro is null and f.id_estado=2 and f.fecha_instalacion is null and f.fecha_retiro is null and f.ordenes_abiertas>0)                 --Pendiente de visita ok
          and not (f.id_fae is null and f.instalacion is null and f.retiro is null and f.id_estado=1 and f.fecha_instalacion is null and f.fecha_retiro is null and f.ordenes_abiertas=0)                 --incompletas ok


	);
	--
begin
	dbms_output.put_line('ANALISIS DE ESTADOS Y ORDENES');
	dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
	for cl in cuentas loop
      dbms_output.put_line('ID: '||cl.id||' - Cuenta: '||cl.cuenta);
      --con fae
          --activa
          if cl.id_fae is not null and cl.retiro is null then
              dbms_output.put_line('>>> Fae Activa');
              if cl.id_estado<>5 and cl.ordenes_abiertas=0 and cl.instalacion is not null then
                  dbms_output.put_line('>>> Estado corresponde Finalizada');
              elsif cl.id_estado=5 and cl.ordenes_abiertas<>0 then
                  dbms_output.put_line('>>> Estado corresponde Pendiente de Visita');
              elsif cl.instalacion is null and cl.retiro is null and cl.fecha_instalacion is null and cl.fecha_retiro is null then
                  dbms_output.put_line('>>> FAE seleccionada sin ordenes.');
              end if;

          end if;
         
          --retirada
          if cl.id_fae is not null and cl.retiro is not null then
              dbms_output.put_line('>>> Fae Retirada');
              if cl.id_estado<>6 then 
                  dbms_output.put_line('>>> Estado corresponde Cancelado');
              elsif cl.ordenes_abiertas>0 then
                  dbms_output.put_line('>>> Todavia posee ordenes abiertas');
              end if;
          
          end if;
          
          --sin ordenes
          if cl.id_fae is not null and cl.id_estado<>5 then
              dbms_output.put_line('>>> FAE instalada pero con estado incorrecto');
          end if;
      
      --sin fae
      if cl.id_fae is null then
          --canceladas
          if cl.id_estado=6 then
              dbms_output.put_line('>>> Fae Cancelada');
              
              if cl.ordenes_abiertas>0 then
                  dbms_output.put_line('>>> No puede poseer ordenes abiertas');
              end if;          
          end if;          
          
          --incompleta
          if cl.id_estado<>6 and cl.ordenes_cantidad=0 then
              dbms_output.put_line('>>> Fae Incompleta');
              
              if cl.id_estado not in (1,6) then
                  dbms_output.put_line('>>> Estado corresponde Pendiente o Cancelado');
              end if;
          end if;
          
          
          --pendiente
          if cl.id_estado<>6 and cl.ordenes_cantidad>0 then
              dbms_output.put_line('>>> Fae Pendiente');
              
              if cl.id_fae is null and cl.instalacion is not null then
                  dbms_output.put_line('>>> Falta seleccionar FAE');
              elsif cl.id_estado in (5,6) then
                  dbms_output.put_line('>>> El estado '||cl.estado||' no es correcto');
              elsif cl.id_estado=2 and cl.ordenes_abiertas=0 then
                  dbms_output.put_line('>>> El estado corresponde Pendiente');
              elsif cl.id_estado=1 and cl.ordenes_abiertas>0 then
                  dbms_output.put_line('>>> El estado corresponde Pendiente de Visita');
              elsif cl.id_estado=8 and cl.ordenes_abiertas>0 then
                  dbms_output.put_line('>>> Ex Fallida, el estado corresponde Pendiente de Visita');
              end if;
          end if;
      end if;

      -- fecha de instalacion
      if not (cl.instalacion is null and cl.fecha_instalacion is null) then
          if cl.instalacion=cl.fecha_instalacion then
              null;
          else    
              dbms_output.put_line('>>> Fecha de Instalacion es `'||cl.instalacion||'` corresponde '||cl.fecha_instalacion);
          end if;    
      end if;        
      -- fecha de retiro
      if not (cl.retiro is null and cl.fecha_retiro is null) then
          if cl.retiro=cl.fecha_retiro or null in (cl.retiro,cl.fecha_retiro) then
              null;
          else    
              dbms_output.put_line('>>> Fecha de Retiro es `'||cl.retiro||'` corresponde '||cl.fecha_retiro);
          end if;  
      end if;    


	dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
	end loop;

exception 
	when no_data_found then
		dbms_output.put_line('Sin Cuentas');
end;

/*

GELEC.ED_ESTADO_FAE
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

GELEC.ED_TIPO_ORDEN
1	Instalacion FAE
3	Preventivo FAE
4	Retiro FAE
6	Correctivo FAE
7	Mudanza FAE
8	Actualizacion

GELEC.ED_ESTADO_ORDENES
1	Pendiente
2	Finalizado
3	Fallida
4	Cancelada


GELEC.ED_FAE_CLIENTE.ID
38

*/





