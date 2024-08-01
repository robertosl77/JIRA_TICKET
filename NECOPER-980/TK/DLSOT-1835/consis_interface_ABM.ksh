#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa
# LOG_DIR=/stage/gis/imple/procesos/TMT/trans/TPR/batch/logs
DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/consis_interface_ABM_$DATE.log
FILE_AUX=$LOG_DIR/consis_interface_ABM.ksh.aux
USER=NEXUS_GIS

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
----------------------------
ALTER SESSION SET NLS_DATE_FORMAT='yyyy-mm-dd hh:mi:ss pm';

DECLARE
P_NROPROCESO NUMBER;
P_USERID NUMBER;
P_RETVAL NUMBER;
P_DATE DATE;
p_Error BOOLEAN;
cont number :=1;				
BEGIN
	---------------------------------
	-- GSolimano 18/02/2009
	-- GSolimano 04/08/2009 - Se modifico para que se envie por mail las inconsistencias
	-- GSolimano 02/09/2009 - Se modifico el ksh para que el formato del sysdate sea YYYYMMDD HH:MI:SS
	---------------------------------
	----------------------------------
	-- Parametros
	-- P_NROPROCESO := XX;  Nro de proceso de FDL_DBLOG
	-- P_USERID := XX;  ID de usuario que lo solicita
	-- P_RETVAL := NULL;  valor de retorno. 0 --> fin OK, 1 --> con errores.
	-- P_DATE := NULL;  fecha “hasta” en la que se realiza la verificación. Es decir, desde el nacimiento del objeto a la fecha pasada por parámetro. 
	-- 			    Por default se utiliza SYSDATE y se le asigna NULL al parametro.
	----------------------------------
	
	-- nro de proceso 
	P_Error:= FALSE;
	BEGIN
		SELECT SEQ_ID_PROCESO.NEXTVAL INTO P_NROPROCESO FROM dual;
	EXCEPTION 
		WHEN OTHERS THEN
 	        DBMS_OUTPUT.PUT_LINE('RESULTADO: Error al obtener secuencia');
         	p_Error := TRUE;
	END;

	IF NOT P_Error THEN
		-- seteo variables 
		P_USERID := 24;
		P_DATE := NULL;
		P_RETVAL := NULL;
		
		NEXUS_GIS.SCADA_ABM_CONSISTENCY.CHECK_TOPOLOGY (P_NROPROCESO, P_USERID, P_RETVAL);
	
	
		IF P_RETVAL = 0 then
			DBMS_OUTPUT.PUT_LINE('RESULTADO_OK: Proceso OK.');		
			DBMS_OUTPUT.PUT_LINE('Verificar registro de ejecucion en tabla FDL_DBLOG. NroProceso: '|| P_NROPROCESO);
			DBMS_OUTPUT.PUT_LINE('	');		
			--DBMS_OUTPUT.PUT_LINE('No se han encontrado inconsistencias topológicas en la red unifilar');				
		ELSE 
			--DBMS_OUTPUT.PUT_LINE('RESULTADO INCONSISTENCIA: PROCESO TERMINADO');
			DBMS_OUTPUT.PUT_LINE('Proceso OK.');
			DBMS_OUTPUT.PUT_LINE('Verificar registro de ejecucion en tabla FDL_DBLOG. NroProceso: '|| P_NROPROCESO);
			DBMS_OUTPUT.PUT_LINE('');
			
			-- Muestro el log del proceso
			FOR item IN (SELECT mensaje FROM fdl_dblog
						 WHERE nroproceso = P_NROPROCESO
						 AND paso = 'Scada ABM Consistency - Baja Topologias'
						 ORDER BY nrosecu
						)LOOP
						
						DBMS_OUTPUT.PUT_LINE(item.mensaje);
				cont:=cont + 1;
				if cont=3 then
					DBMS_OUTPUT.PUT_LINE('	');
					cont:=0;
				end if;
						
			END LOOP;
		END IF; 

	END IF;
	
	
END;
/
----------------------------
-- End your script here   --
----------------------------
ENDSQL

ERROR_DB=0
ERROR_DB=`grep -i NO_ENVIAR_MAIL $FILE_AUX | wc -l`

#if [ ${ERROR_DB} -eq 0 ]
#then
	mailx -s "${ORACLE_SID}: Chequeo consistencia - Interfaz ABM" ciclotec@edenor.com <$FILE_AUX	
#fi

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



