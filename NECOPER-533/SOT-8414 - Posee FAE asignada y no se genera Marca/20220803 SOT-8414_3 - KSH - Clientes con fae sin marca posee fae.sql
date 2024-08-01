set serveroutput on
declare
	--autor: rsleiva@edenor.com
	--fecha: 03/08/2022
	V_LOG_ID            NUMBER;
	V_ID_NOTA           GELEC.ED_NOTAS.ID_NOTA%type;
	V_ID_MARCA_CLIENTE  GELEC.ED_MARCA_CLIENTE.ID%TYPE;
	V_CONT              NUMBER;
	--
	cursor cuentas is (
		select cuenta
		from gelec.ed_fae_cliente 
		where 
			id_fae is not null 
			and instalacion is not null 
			and retiro is null
			and cuenta not in (select cuenta from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18 and nvl(log_hasta,0)=0)
			--and rownum=1
	);
	--
begin
	dbms_output.put_line('CLIENTES CON FAE SIN MARCA POSEE FAE');
	dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
	for cuenta in cuentas loop
		--dbms_output.put_line(cuenta.cuenta);
		V_LOG_ID := GELEC.INSERT_LOG ('Modifica marca: '|| 7|| ' | Submarca: '|| 18|| ' | en cuenta nro: '|| cuenta.cuenta,'Aplicación');
		--dbms_output.put_line(cuenta.cuenta||','||v_log_id);
    
		if (v_log_id >0) then
			-- muestro lo que esta en el log_hasta
			for s in (select * from gelec.ed_log where log_id=v_log_id) loop
				dbms_output.put_line('GELEC.ED_LOG >>>'||s.log_id||','||s.detalle||','||s.fecha||','||s.usuario);
			end loop;
      
			-- muestro lo que esta en marcas
			V_CONT:=0;
			for s in (select * from gelec.ed_marca_cliente where cuenta=cuenta.cuenta and id_marca=7 and id_submarca=18) loop
				dbms_output.put_line('GELEC.ED_MARCA_CLIENTE >>>'||s.id||','||s.cuenta||','||s.id_marca||','||s.id_submarca||','||s.log_desde||','||nvl(s.log_hasta,0));
				V_CONT:=1;
			end loop;
			if (v_cont=0) then
				dbms_output.put_line('GELEC.ED_MARCA_CLIENTE >>>Sin marca Posee FAE anterior a insertar.');
			end if;  

        
			--inserto la nota y la marca
			--gelec.pkg_otros.insertar_marca('Aplicación',7,18,cuenta.cuenta,'[Marca: Cliente | Submarca: POSEE FAE]',v_id_nota);
			--GELEC.PKG_OTROS.INSERTAR_MARCA('Aplicación',7,18,cuenta.cuenta,'[Marca: Cliente | Submarca: POSEE FAE]',V_ID_NOTA);
			V_ID_NOTA := GELEC.SEQ_NOTAS.NEXTVAL ();
			INSERT INTO GELEC.ED_NOTAS (ID_NOTA,USUARIO,IDDESTINO,FECHAHORA,OBSERVACIONES,EFECTIVO,LOG_DESDE,LOG_HASTA,ID_TIPO_NOTA)
				VALUES (v_id_nota,'Aplicación',null,sysdate,'[Marca: Cliente | Submarca: POSEE FAE]',NULL,V_LOG_ID,NULL,'3');

			V_ID_MARCA_CLIENTE := GELEC.SEQ_MARCA_CLIENTE.NEXTVAL ();
			INSERT INTO GELEC.ED_MARCA_CLIENTE MC (ID,CUENTA,ID_MARCA,ID_SUBMARCA,LOG_DESDE,LOG_HASTA)
				VALUES (V_ID_MARCA_CLIENTE,cuenta.cuenta,7,18,V_LOG_ID,NULL);      

			-- muestro lo que esta en notas
			V_CONT:=0;
			for s in (select * from GELEC.ED_NOTAS where ID_NOTA=V_ID_NOTA) LOOP
				dbms_output.put_line('GELEC.ED_NOTAS >>>'||s.id_nota||','||s.usuario||','||s.fechahora||','||s.observaciones||','||s.log_desde||','||nvl(s.log_hasta,0));
				V_CONT:=1;
			end loop;
			if (v_cont=0) then
				dbms_output.put_line('GELEC.ED_NOTAS >>>Sin Nota de Posee FAE.');
			end if;        

			-- muestro lo que esta en marcas despues de insertar
			V_CONT:=0;
			for s in (select * from gelec.ed_marca_cliente where cuenta=cuenta.cuenta and id_marca=7 and id_submarca=18) loop
				dbms_output.put_line('GELEC.ED_MARCA_CLIENTE >>>'||s.id||','||s.cuenta||','||s.id_marca||','||s.id_submarca||','||s.log_desde||','||nvl(s.log_hasta,0));
				V_CONT:=1;
			end loop;
			if (v_cont=0) then
				dbms_output.put_line('GELEC.ED_MARCA_CLIENTE >>>Sin marca Posee FAE posterior a insertar.');
			end if;        
			dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
		end if;
	end loop;
  
  COMMIT;

exception 
	when no_data_found then
		dbms_output.put_line('Sin Cuentas');
end;

/*
select * from gelec.ed_marca_cliente where cuenta='9860785498' and id_marca=7 and id_submarca=18;
select * from gelec.ed_log order by log_id desc;
select * from GELEC.ED_NOTAS where id_nota=16290;
select * from gelec.ed_marca_cliente where cuenta='9860785498';
select * from gelec.ed_marca_cliente order by id desc;
*/





