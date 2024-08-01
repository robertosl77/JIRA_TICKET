set serveroutput on
DECLARE
	--autor: rsleiva@edenor.com
	--fecha: 02/08/2022
	V_LOG_ID NUMBER;
	--
	CURSOR CUENTAS IS (
		SELECT DISTINCT CUENTA
		FROM GELEC.ED_CLIENTES C 
		WHERE 
			1=1
			AND CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_FAE_CLIENTE)
			AND CUENTA IN (SELECT CUENTA FROM GELEC.ED_MARCA_CLIENTE WHERE ID_MARCA=7 AND ID_SUBMARCA=18 AND NVL(LOG_HASTA,0)=0)
			--and rownum=1
	);
	--
BEGIN
	DBMS_OUTPUT.PUT_LINE('CLIENTES NUNCA FAE CON MARCA POSEE FAE');
	DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------------');
	FOR CUENTA IN CUENTAS LOOP
		--dbms_output.put_line(cuenta.cuenta);
		V_LOG_ID := GELEC.INSERT_LOG ('Modifica marca: '|| 7|| ' | Submarca: '|| 18|| ' | en cuenta nro: '|| CUENTA.CUENTA,'rsleiva');
		--dbms_output.put_line(cuenta.cuenta||','||v_log_id);
    
		IF (V_LOG_ID >0) THEN
			-- muestro lo que esta en el log_hasta
			FOR S IN (SELECT * FROM GELEC.ED_LOG WHERE LOG_ID=V_LOG_ID) LOOP
				DBMS_OUTPUT.PUT_LINE('GELEC.ED_LOG >>>'||S.LOG_ID||','||S.DETALLE||','||S.FECHA||','||S.USUARIO);
			END LOOP;
      
			-- muestro lo que esta en marcas
			FOR S IN (SELECT * FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=CUENTA.CUENTA AND ID_MARCA=7 AND ID_SUBMARCA=18) LOOP
				DBMS_OUTPUT.PUT_LINE('GELEC.ED_MARCA_CLIENTE >>>'||S.ID||','||S.CUENTA||','||S.ID_MARCA||','||S.ID_SUBMARCA||','||S.LOG_DESDE||','||NVL(S.LOG_HASTA,0));
			END LOOP;      
    
      --actualizo el log_hasta
			UPDATE GELEC.ED_MARCA_CLIENTE SET LOG_HASTA=V_LOG_ID WHERE CUENTA=CUENTA.CUENTA AND ID_MARCA=7 AND ID_SUBMARCA=18 AND LOG_HASTA IS NULL;

			-- muestro lo que esta en marcas despues de insertar
			FOR S IN (SELECT * FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=CUENTA.CUENTA AND ID_MARCA=7 AND ID_SUBMARCA=18) LOOP
				DBMS_OUTPUT.PUT_LINE('GELEC.ED_MARCA_CLIENTE >>>'||S.ID||','||S.CUENTA||','||S.ID_MARCA||','||S.ID_SUBMARCA||','||S.LOG_DESDE||','||NVL(S.LOG_HASTA,0));
			END LOOP;
      DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------------');
		END IF;
	END LOOP;

  COMMIT;
    
EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('Sin Cuentas');
END;

/*
select * from gelec.ed_marca_cliente where cuenta='8269510537' and id_marca=7 and id_submarca=18;
select * from gelec.ed_marca_cliente where id_marca=7 and id_submarca=18;
select * from gelec.ed_marca_cliente where id_marca<>1 order by id desc;
update gelec.ed_marca_cliente set id_marca=7, id_submarca=18 where id in (6847);
select * from gelec.ed_log order by log_id desc;
update gelec.ed_marca_cliente set log_hasta=null where id in (6832, 6833);
*/



