#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/Temp_InsertaNotaFaltante.ksh_$DATE.log
FILE_AUX=$LOG_DIR/Temp_InsertaNotaFaltante.ksh.log

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
-- RSLEIVA
-- NECOPER-189
-- Se insertaron manualmente marcas de baja potencial para probar antes de acoplarlo al circuito 145, pero no se insertaron las notas. 
----------------------------
/* Formatted on 20/10/2022 10:18:00 (QP5 v5.294) */
SET SERVEROUTPUT ON
DECLARE
  
    CURSOR C_DATOS IS (
        SELECT DISTINCT LPAD(MC.CUENTA,10,0) CUENTA
        FROM 
          GELEC.ED_MARCA_CLIENTE MC,
          GELEC.ED_LOG L
        WHERE
          MC.LOG_DESDE=L.LOG_ID
          AND MC.ID_MARCA=1
          AND MC.ID_SUBMARCA=5
          AND TRUNC(FECHA)=TRUNC(SYSDATE)-1
    );
    P_RESULTADO NUMBER;
    P_ID_NOTA VARCHAR2 (30);
    P_LOG_DESDE VARCHAR2 (30);
BEGIN

    FOR F_DATOS IN C_DATOS LOOP
        DBMS_OUTPUT.PUT_LINE('Se insertara nota en: '||f_datos.cuenta);
        --INSERTA EN ED_NOTAS
        PKG_NOTAS.INSERTAR_NOTA (  
            'Aplicacion',
            'Marca Baja Potencial Automatica',
            NULL,
            NULL,
            1,
            NULL,
            NULL,
            'Baja Automatica por circuito 145',
            NULL,
            P_ID_NOTA,
            P_LOG_DESDE) ;  

        -- INSERTA EN ED_CLIENTE_NOTA
        BEGIN
            PKG_NOTAS.ASOCIAR_NOTA (  
                NULL,
                F_DATOS.CUENTA,
                'Aplicacion',
                P_ID_NOTA,
                P_RESULTADO) ;  
        EXCEPTION
            WHEN OTHERS THEN
                --DBMS_OUTPUT.PUT_LINE('Error al Asociar Nota: '||P_ID_NOTA||' con resultado: '||P_RESULTADO);
                NULL;
        END;
    END LOOP;
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