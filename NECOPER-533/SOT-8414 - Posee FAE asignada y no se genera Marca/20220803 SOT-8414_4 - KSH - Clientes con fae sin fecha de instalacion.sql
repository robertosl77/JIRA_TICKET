set serveroutput on
DECLARE
	--autor: rsleiva@edenor.com
	--fecha: 02/08/2022
	V_INSTALACION GELEC.ED_FAE_CLIENTE.INSTALACION%TYPE;
	--
	CURSOR CUENTAS IS (
		SELECT * 
		FROM GELEC.ED_FAE_CLIENTE FC 
		WHERE 
			FC.ID_FAE IS NOT NULL 
			AND FC.INSTALACION IS NULL 
			--and rownum=1
	);
	--
BEGIN
	DBMS_OUTPUT.PUT_LINE('CLIENTES CON FAE SIN FECHA DE INSTALACION');
	DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------------');
	FOR CUENTA IN CUENTAS LOOP
		--falta la fecha de instalacion
		IF CUENTA.INSTALACION IS NULL THEN
			BEGIN
				SELECT FIN INTO V_INSTALACION FROM GELEC.ED_ORDENES WHERE CUENTA=CUENTA.CUENTA AND ID_FAE_CLIENTE=CUENTA.ID AND ID_TIPO=1 AND ID_ESTADO=2 AND FIN IS NOT NULL;
				--select fin from gelec.ed_ordenes where cuenta='6851537738' and id_fae_cliente=16 and id_tipo=1 and id_estado=2 and fin is not null;
				IF V_INSTALACION IS NOT NULL THEN
					DBMS_OUTPUT.PUT_LINE(CUENTA.CUENTA||'>>> fecha de fin: '||V_INSTALACION);
					--muestro los datos antes de actualizar
					FOR CTA IN (SELECT * FROM GELEC.ED_FAE_CLIENTE WHERE CUENTA=CUENTA.CUENTA AND ID=CUENTA.ID) LOOP
						DBMS_OUTPUT.PUT_LINE('GELEC.ED_FAE_CLIENTE BEF>>> '||CTA.ID||','||CTA.ID_FAE||','||CTA.CUENTA||','||CTA.INSTALACION||','||CTA.RETIRO||','||CTA.ID_ESTADO||','||CTA.LOG_DESDE||','||CTA.LOG_HASTA||','||CTA.FECHA);
					END LOOP;
				  
					--actualizo insertando la fecha de instalacion
          DBMS_OUTPUT.PUT_LINE('FECHA A INSERTAR: '||V_INSTALACION);
					UPDATE GELEC.ED_FAE_CLIENTE SET INSTALACION=V_INSTALACION WHERE ID=CUENTA.ID;

					--muestro los datos despues de actualizar
					FOR CTA IN (SELECT * FROM GELEC.ED_FAE_CLIENTE WHERE CUENTA=CUENTA.CUENTA AND ID=CUENTA.ID) LOOP
						DBMS_OUTPUT.PUT_LINE('GELEC.ED_FAE_CLIENTE AFT>>> '||CTA.ID||','||CTA.ID_FAE||','||CTA.CUENTA||','||CTA.INSTALACION||','||CTA.RETIRO||','||CTA.ID_ESTADO||','||CTA.LOG_DESDE||','||CTA.LOG_HASTA||','||CTA.FECHA);
					END LOOP;
				ELSE
					DBMS_OUTPUT.PUT_LINE(CUENTA.CUENTA||'>>> La fecha de fin es nula');
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					DBMS_OUTPUT.PUT_LINE(CUENTA.CUENTA||'>>> No posee fecha de fin, se debe desasociar la fae manualmente en GELEC');
			END;        
		END IF;
	DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------------');
	END LOOP;
  
  COMMIT;

EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('Sin Cuentas');
END;

/*
select * from gelec.ed_fae_cliente fc where fc.id_fae is not null and fc.instalacion is null
select * from gelec.ed_fae_cliente where cuenta='7683871565';
update gelec.ed_fae_cliente set instalacion=null where id=27;
commit;
select * from gelec.ed_ordenes where cuenta='9822879043' order by id;
select * from GELEC.ed_equipo_fae order by id;

tipo
1=instalada
2
3=preventivo
4=retiro


estado
2=finalizada
4=cancelada

*/





