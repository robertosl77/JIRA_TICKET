#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa
# LOG_DIR=/stage/gis/imple/procesos/TMT/trans/TPR/batch/logs
DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/PoligonosAfectacionCT.ksh_$DATE.log
FILE_AUX=$LOG_DIR/PoligonosAfectacionCT.ksh.aux
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
DECLARE
  p_RetVal NUMBER;
  p_IdProceso NUMBER;
  p_Error BOOLEAN;
  p_bdt_periodo DATE;
BEGIN
  P_Error:= FALSE;

  BEGIN
	SELECT SEQ_ID_PROCESO.NEXTVAL INTO p_IdProceso FROM dual;
  EXCEPTION 
	WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE('RESULTADO: Error al obtener secuencia');
	  p_Error := TRUE;
  END;

  BEGIN
      SELECT MAX (periodo)
        INTO p_bdt_periodo
        FROM bdth_periodo
       WHERE activo = 'S'
	AND consolidado = 'S';
  EXCEPTION 
	WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE('RESULTADO: Error al obtener el periodo de BDTH');
	  p_Error := TRUE;
  END;

  IF NOT p_Error THEN
    --Reemplazar por el nombre del procedimiento a ejecutar
    DBMS_OUTPUT.PUT_LINE('ID de proceso a ejecutar: ' || p_IdProceso || '.');
    BATCH_ModulosParaCrisis.CrearModulos(p_IdProceso, 24, p_RetVal, p_bdt_periodo);
    IF p_RetVal = 0 THEN
      DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso OK.');
      DBMS_OUTPUT.PUT_LINE('ID de proceso a ejecutar: ' || p_IdProceso || '.');
      BATCH_ModulosParaCrisis.AsignarCTs(p_IdProceso, 24, p_RetVal, p_bdt_periodo);
      IF p_RetVal = 0 THEN
        DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso OK.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('***** RESULTADO: PROCESO TERMINADO CON ERRORES. Error numero ' || p_RetVal || ' ********');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('***** RESULTADO: PROCESO TERMINADO CON ERRORES. Error numero ' || p_RetVal || ' ********');
    END IF;
  END IF;
END;
/
----------------------------
-- End your script here   --
----------------------------
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
