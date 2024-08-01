#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/SOT-18050_Inserta_Log_Faltante.ksh_$DATE.log
FILE_AUX=$LOG_DIR/SOT-18050_Inserta_Log_Faltante.ksh.log

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
--Se insertara el log faltante de la cuenta que se inserto x ksh
----------------------------
/* Formatted on 16/11/2022 16:11 (QP5 v5.294) */
DECLARE

    V_LOGID        NUMBER;
    V_CUENTA       GELEC.ED_CLIENTES.CUENTA%TYPE:='7492815047';
    
BEGIN
    V_LOGID := GELEC.INSERT_LOG ('Inserta Cliente Manual', 'root');
    
    IF NVL(V_LOGID,0) =0 THEN
        NULL;
        DBMS_OUTPUT.PUT_LINE('No se genero un id log correcto');
    ELSE
        --select * from gelec.ed_clientes where cuenta='7492815047';
        UPDATE GELEC.ED_CLIENTES SET LOG_DESDE=V_LOGID WHERE CUENTA=V_CUENTA;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Se inserto en la cuenta '||V_CUENTA||' el log id '||V_LOGID);
    END IF;
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