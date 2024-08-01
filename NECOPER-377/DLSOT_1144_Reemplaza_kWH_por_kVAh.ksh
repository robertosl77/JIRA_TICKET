#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/DLSOT_1144_Reemplaza_kWH_por_kVAh.ksh_$DATE.log
FILE_AUX=$LOG_DIR/DLSOT_1144_Reemplaza_kWH_por_kVAh.ksh.log

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
--DLSOT-1144: 
--Busca en GELEC.ED_NOTAS.OBSERVACIONES las notas que posean los valores kWH
--Reemplaza kWH por kVAh
--Muestra el antes y el despues
----------------------------
/* Formatted on 13/12/2017 13:48:10 (QP5 v5.294) */
DECLARE
    V_NOTA GELEC.ED_NOTAS.OBSERVACIONES%TYPE;
BEGIN

    FOR NOTA IN (
              SELECT ID_NOTA, OBSERVACIONES, REPLACE(OBSERVACIONES,'kWH','kVAh') CORREGIDO, INSTR(OBSERVACIONES,'kWH') POSICION FROM  GELEC.ED_NOTAS 
              WHERE 
                ID_TIPO_NOTA=2
                AND OBSERVACIONES LIKE '%kWH%'
                --AND ROWNUM<4
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------');
        -- MUESTRO ANTES
        DBMS_OUTPUT.PUT_LINE(NOTA.ID_NOTA||','||NOTA.POSICION||','||NOTA.OBSERVACIONES||','||NOTA.CORREGIDO);      
        -- APLICO UPDATE
        UPDATE GELEC.ED_NOTAS SET OBSERVACIONES=REPLACE(OBSERVACIONES,'kWH','kVAh') WHERE ID_NOTA=NOTA.ID_NOTA;
        COMMIT;
        SELECT OBSERVACIONES INTO V_NOTA FROM GELEC.ED_NOTAS WHERE ID_NOTA=NOTA.ID_NOTA;
        DBMS_OUTPUT.PUT_LINE('CORREGIDO>>>'||V_NOTA);
        
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Se detecto un error...');
        
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