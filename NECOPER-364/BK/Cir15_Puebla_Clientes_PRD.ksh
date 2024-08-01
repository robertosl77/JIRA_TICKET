#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa
# LOG_DIR=/stage/gis/imple/procesos/TMT/trans/TPR/batch/logs
DATE=$( date +%y%m%d%H%M )
FILE_LOG=$LOG_DIR/Cir15_Puebla_Clientes.ksh_$DATE.log
FILE_AUX=$LOG_DIR/Cir15_Puebla_Clientes.ksh.aux

USER=UTC

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
BEGIN

  DBMS_OUTPUT.PUT_LINE('*********** PROCESO PUEBLA CLIENTES ***********');
  DBMS_OUTPUT.PUT_LINE('  ');
  DBMS_OUTPUT.PUT_LINE('Comienzo: '||to_char(sysdate,'dd/mm/yyyy hh:mi:ss'));
  DBMS_OUTPUT.PUT_LINE('  ');

  BEGIN

	UTC.Pck_CCnB_Utc.MAIN_VOID;
                    
        DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso OK.');

  EXCEPTION
     WHEN others THEN
	DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso Finalizado con ERROR.'||SQLERRM);

  END;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('  ');
  DBMS_OUTPUT.PUT_LINE('Fin: '||to_char(sysdate,'dd/mm/yyyy hh:mi:ss'));

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

exit_error=`cat $FILE_LOG | grep 'Finalizado con ERROR' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 8
fi
