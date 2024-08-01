#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/DLSOT_1062_1_DOC_SINFECHAFIN.ksh_$DATE.log
FILE_AUX=$LOG_DIR/DLSOT_1062_1_DOC_SINFECHAFIN.ksh.log

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
--DLSOT-1062: 
--Se desea colocar GELEC.ED_DOCUMENTOS.FECHA_FIN_DOC con valores nulos, en aquellos documentos donde el LOG_HASTA no es nulo.
----------------------------
/* Formatted on 04/08/2022 16:02 (QP5 v5.294) */
DECLARE
    CURSOR C_CTAS IS (
        SELECT ID_DOCUMENTO, NRO_DOCUMENTO, FECHA_INICIO_DOC, FECHA_FIN_DOC, LOG_DESDE, LOG_HASTA 
        FROM GELEC.ED_DOCUMENTOS
        WHERE 
            LOG_HASTA IS NOT NULL
            AND FECHA_FIN_DOC IS NULL
    );
    
    V_FFIN GELEC.ED_DOCUMENTOS.FECHA_FIN_DOC%TYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------');
    FOR CC IN C_CTAS LOOP
        DBMS_OUTPUT.PUT_LINE('ANTES DE ACTUALIZAR');
        DBMS_OUTPUT.PUT_LINE(CC.ID_DOCUMENTO||','||CC.NRO_DOCUMENTO||','||CC.FECHA_INICIO_DOC||','||CC.FECHA_FIN_DOC||','||CC.LOG_DESDE||','||CC.LOG_HASTA);
        --BUSCO LA FECHA DE FIN DESDE NEXUS GIS
        BEGIN
            --BUSCO LA FECHA DE FIN
            SELECT 
            (CASE WHEN (SELECT MIN (DCP.FECHA) FROM NEXUS_GIS.DOC_CIERRE_PROVISORIO DCP WHERE DCP.DOCUMENT_ID = D.ID) IS NULL
              THEN D.LAST_STATE_CHANGE_TIME 
              ELSE (SELECT MIN (dcp.fecha) FROM nexus_gis.doc_cierre_provisorio dcp WHERE dcp.document_id = d.id) END)
            AS FECHA_CIERRE_DOCUMENTO
            INTO V_FFIN
            FROM NEXUS_GIS.OMS_DOCUMENT D, NEXUS_GIS.OMS_DOCUMENT_STATE DS
            WHERE     D.ID = CC.ID_DOCUMENTO AND D.LAST_STATE_ID > 4 AND DS.ID = D.LAST_STATE_ID;
            --MUESTRO LA FECHA QUE VOY A UTILIZAR
            --DBMS_OUTPUT.PUT_LINE('FECHA DE FIN: '||V_FFIN);            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('NO SE ENCONTRO FECHA FIN PARA EL DOCUMENTO: '||CC.NRO_DOCUMENTO);
                V_FFIN:=NULL;
        END;        
        --APLICO LA ACTUALIZACION
        IF V_FFIN IS NOT NULL THEN
            UPDATE GELEC.ED_DOCUMENTOS SET FECHA_FIN_DOC=V_FFIN WHERE ID_DOCUMENTO=CC.ID_DOCUMENTO;
            COMMIT;
        END IF;    
        --MUESTRO LO MODIFICADO
        FOR CM IN (SELECT NRO_DOCUMENTO, ID_DOCUMENTO, FECHA_INICIO_DOC, FECHA_FIN_DOC, LOG_DESDE, LOG_HASTA FROM GELEC.ED_DOCUMENTOS WHERE ID_DOCUMENTO=CC.ID_DOCUMENTO) LOOP
            DBMS_OUTPUT.PUT_LINE('DESPUES DE ACTUALIZAR');
            DBMS_OUTPUT.PUT_LINE(CM.ID_DOCUMENTO||','||CM.NRO_DOCUMENTO||','||CM.FECHA_INICIO_DOC||','||CM.FECHA_FIN_DOC||','||CM.LOG_DESDE||','||CM.LOG_HASTA);
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------');    
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