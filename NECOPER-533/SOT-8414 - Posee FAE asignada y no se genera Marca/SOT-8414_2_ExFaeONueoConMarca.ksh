#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/SOT-8414_2_ExFaeONueoConMarca.ksh_$DATE.log
FILE_AUX=$LOG_DIR/SOT-8414_2_ExFaeONueoConMarca.ksh.log

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
--Aquellos clientes que poseian FAE (ahora no posee ninguna activa) o clientes que iniciaron el proceso pero que no tienen ninguna FAE (otra) se quitara la marca de posee FAE
----------------------------
/* Formatted on 09/08/2022 09:42 (QP5 v5.294) */
DECLARE
	--autor: rsleiva@edenor.com
	--fecha: 02/08/2022
	V_LOG_ID NUMBER;
	--
	CURSOR CUENTAS IS (
		SELECT DISTINCT CUENTA
		FROM GELEC.ED_FAE_CLIENTE 
		WHERE 
		  1=1
		  AND CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_FAE_CLIENTE WHERE ID_FAE IS NOT NULL AND INSTALACION IS NOT NULL AND RETIRO IS NULL)
		  AND CUENTA IN (SELECT CUENTA FROM GELEC.ED_MARCA_CLIENTE WHERE ID_MARCA=7 AND ID_SUBMARCA=18 AND NVL(LOG_HASTA,0)=0)
	);
	--
BEGIN
	DBMS_OUTPUT.PUT_LINE('CLIENTES EX FAE O SIN FAE ACTIVA, CON MARCA POSEE FAE');
	DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------------');
	FOR CUENTA IN CUENTAS LOOP
		--dbms_output.put_line(cuenta.cuenta);
		V_LOG_ID := GELEC.INSERT_LOG ('Modifica marca: '|| 7|| ' | Submarca: '|| 18|| ' | en cuenta nro: '|| CUENTA.CUENTA,'AplicaciÃ³n');
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