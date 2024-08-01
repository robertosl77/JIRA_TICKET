#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/GELEC_AsociaCuentaManual_2.ksh_$DATE.log
FILE_AUX=$LOG_DIR/GELEC_AsociaCuentaManual_2.ksh.log

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
--SOT-18050
--GELEC no esta permitiendo cargar un cliente manualmente
----------------------------
/* Formatted on 16/11/2022 16:11 (QP5 v5.294) */
DECLARE
  P_NRO_CLIENTE VARCHAR2(200);
  P_USER_ID     VARCHAR2(200);
  P_RESULTADO   VARCHAR2(200);
BEGIN
  P_NRO_CLIENTE := '7492815047';
  P_USER_ID     := 'rsleiva';
  INSERT_CLIENTE_MANUAL( 
      P_NRO_CLIENTE, 
      P_USER_ID, P_RESULTADO => P_RESULTADO );

  DBMS_OUTPUT.PUT_LINE('P_RESULTADO = ' || P_RESULTADO);
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