#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/SOT-8414_4_ConFaeSinFechaInstalacion.ksh_$DATE.log
FILE_AUX=$LOG_DIR/SOT-8414_4_ConFaeSinFechaInstalacion.ksh.log

USER=GELEC
PASSWORD=`sh ~/get_password.sh $USER`

echo "\n
   ______________________________________________________________________________________________________________

                     EJECUCION DE PROCESO - DATE: $(date '+%d/%m/%y %H:%M:%S') - DATABASE: ${ORACLE_SID}
                                               SCRIPT EJECUTADO: ${0}

   ______________________________________________________________________________________________________________

    * $(date '+%d/%m/%y %H:%M:%S') - Iniciando ejecucion ............... \n" >>$FILE_LOG


sqlplus -s /nolog << ENDSQL > $FILE_AUX
connect $USER/$PASSWORD
set serveroutput on
set pagesize 0
set linesize 120
set verify off
set feed off
----------------------------
-- Start your script here --
--SOT-8414: 
--Se busca nivelar las marcas FAE
--Aquellos clientes que poseen FAE pero por algun error no detectado no posee fecha de instalacion en tabla ed_fae_clientes
----------------------------
/* Formatted on 09/08/2022 09:49 (QP5 v5.294) */
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
/
 

ENDSQL

echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Detalle Ejecucion proceso ............... \n" >>$FILE_LOG

cat $FILE_AUX >>$FILE_LOG

echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Fin Ejecucion proceso ............... \n" >>$FILE_LOG

rm $FILE_AUX


exit_error=`cat $FILE_LOG | grep 'ORA-' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 9
fi

exit_error=`cat $FILE_LOG | grep 'ERRORES' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 10
fi