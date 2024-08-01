#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/RegistraBPACuentasNoEDP.ksh_$DATE.log
FILE_AUX=$LOG_DIR/RegistraBPACuentasNoEDP.ksh.log

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
-- Se buscan las cuentas que ya no cuenten con la sensibilidad EDP o EDP en Tramite, y que tampoco cuenten con una marca de baja potencial.
-- Se activara la marca de Baja Potencial, No EDP, para las cuentas que coincidan. 
----------------------------
/* Formatted on 04/10/2022 10:49:00 (QP5 v5.294) */
DECLARE

	/*******************************************************************
	* NOMBRE CIRCUITO: BAJA POTENCIAL                                 *
	* FECHA: 04/10/2022 RSLEIVA                                       *
	*                                                                 *
	* DESCRIPCION: INSERTA MARCA DE BAJA POTENCIAL "NO EDP"           *
	*     A CUENTAS QUE YA NO CUENTAN CON LA SENSIBILIDAD.            *
	*                                                                 *
	* PARAMETROS DE ENTRADA:                                          *
	* PARAMETRO DE SALIDA: P_RESULTADO                                *
	*   VALORES DE SALIDA                                             *
	*      % >1 SI HUBO CAMBIO                                        *
	*      % 0 SI NO HUBO CAMBIO                                      *
	*                                                                 *
	*******************************************************************/

    CURSOR C_BP IS (
        SELECT 
            C.CUENTA, 
            C.RAZON_SOCIAL, 
            C.LOG_DESDE, 
            C.LOG_HASTA, 
            (SELECT FECHA FROM GELEC.ED_LOG WHERE LOG_ID= C.LOG_HASTA) BAJA            
        FROM 
            GELEC.ED_CLIENTES C
        WHERE
            NVL(C.LOG_HASTA,0)>0
            AND NOT EXISTS (SELECT 1 FROM GELEC.ED_MARCA_CLIENTE WHERE ID_MARCA=1 AND NVL(LOG_HASTA,0)=0 AND CUENTA=C.CUENTA)
            AND NOT EXISTS (SELECT 1 FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=C.CUENTA AND CUSTATT21=12521)
            --AND ROWNUM=1
    );
    
    P_RESULTADO NUMBER;
    P_ID_NOTA VARCHAR2 (30);
    P_LOG_DESDE VARCHAR2 (30);
BEGIN

    FOR F_DATOS IN C_BP LOOP
        BEGIN
            PKG_OTROS.INSERTAR_MARCA (  
                'Aplicacion',
                1,
                5,
                F_DATOS.CUENTA,
                'No EDP desde: '||F_DATOS.BAJA,
                P_RESULTADO) ;  
            --
            IF P_RESULTADO=0 THEN
                DBMS_OUTPUT.PUT_LINE('Marca No Insertada para la cuenta: '||F_DATOS.CUENTA);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Marca Insertada para la cuenta: '||F_DATOS.CUENTA);
				
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
            END IF;                
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Marca No Insertada para la cuenta por error: '||F_DATOS.CUENTA);
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