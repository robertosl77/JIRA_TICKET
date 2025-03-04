#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/SOT_9689_PRUEBA.ksh.ksh_$DATE.log
FILE_AUX=$LOG_DIR/SOT_9689_PRUEBA.ksh.ksh.log

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
--SOT-9689: 
--Se busca ver que aplique la actualizacion de fecha de fin en clientes con baja de doc logico pero que en campo fecha fin corte sea nulo
----------------------------
/* Formatted on 04/08/2022 14:31 (QP5 v5.294) */
DECLARE

P_ID_DOCUMENT   GELEC.ED_DOCUMENTOS.ID_DOCUMENTO%TYPE:=9085316;
P_USER_ID       GELEC.ED_LOG.USUARIO%TYPE:='Aplicación';
--P_RESULTADO     VARCHAR2;

      --AUTOR: DARIO.JAHNEL@ATOS.NET
      --PARAMETROS:
      --    P_ID_DOCUMENT: NOMBRE DEL DOCUMENTO (POR EJ. D-08-09-21676)
      --    P_USER_ID: CUENTA DEL USUARIO
      --    P_RESULTADO: RESULTADO DEL PROCEDURE

      CURSOR CUR_LISTA_CLIENTES (V_ID_DOCUMENTO VARCHAR2)
      IS
         SELECT CUENTA, ESTADO_CLIE
           FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES
          WHERE ID_DOCUMENTO = P_ID_DOCUMENT AND LOG_HASTA IS NULL;


      V_LOGID                     NUMBER;
      V_RESULTADO                 VARCHAR2 (124);
      V_DOCUMENTO_ABIERTO         NUMBER;
      V_DOCUMENTO_ABIERTO_NEXUS   NUMBER;
      V_ESTADO                    VARCHAR2 (24);
      V_FECHA_FIN                 GELEC.ED_DOCUMENTOS.FECHA_FIN_DOC%TYPE;
   BEGIN
      --INSERTA RESULTADO POR DEFECTO
      V_RESULTADO := 'NO OK';
      --INSERTA EN GELEC.ED_LOG
      V_LOGID :=
         GELEC.INSERT_LOG ('BAJA LOGICA DOCUMENTO: ' || P_ID_DOCUMENT,P_USER_ID);
      -- VERIFICO QUE EL DOCUMENTO NO SE ENCUENTRE CERRADO EN GELEC
	  DBMS_OUTPUT.PUT_LINE(sysdate||'>> V_LOGID: '||V_LOGID);
      SELECT COUNT (*)
        INTO V_DOCUMENTO_ABIERTO
        FROM GELEC.ED_DOCUMENTOS
       WHERE ID_DOCUMENTO = P_ID_DOCUMENT AND LOG_HASTA IS NULL;

		DBMS_OUTPUT.PUT_LINE(sysdate||'>> V_DOCUMENTO_ABIERTO: '||V_DOCUMENTO_ABIERTO);
      IF V_DOCUMENTO_ABIERTO = 1
      THEN
         -- VERIFICO QUE EL DOCUMENTO ESTE CERRADO EN NEXUS
        SELECT COUNT (*)
        INTO V_DOCUMENTO_ABIERTO_NEXUS
        FROM NEXUS_GIS.OMS_DOCUMENT
        WHERE ID = P_ID_DOCUMENT AND LAST_STATE_ID < 5;

		DBMS_OUTPUT.PUT_LINE(sysdate||'>> V_DOCUMENTO_ABIERTO_NEXUS: '||V_DOCUMENTO_ABIERTO_NEXUS);
         IF V_DOCUMENTO_ABIERTO_NEXUS = 0
         THEN
            -- SETEO LOS CLIENTES ASOCIADOS A NORMALIZADOSS Y SETEO LOG_HASTA
            -- (LOS CANCELADOS LOS DEJO CANCELADOS)
            FOR CUR_CLIENTE IN CUR_LISTA_CLIENTES (P_ID_DOCUMENT)
            LOOP
				DBMS_OUTPUT.PUT_LINE(sysdate||'>> CUR_CLIENTE.ESTADO_CLIE: '||CUR_CLIENTE.ESTADO_CLIE);
               IF CUR_CLIENTE.ESTADO_CLIE = 'Cancelado'
               THEN
                  V_ESTADO := 'Cancelado';
               ELSE
                  V_ESTADO := 'Normalizado';
               END IF;
              
              --CAMBIA ESTADO, CARGA LOG_HASTA, OPERACION, USUARIO Y ULTIMA MODIFICACION
               UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES
                  SET ESTADO_CLIE = V_ESTADO,
                      LOG_HASTA = V_LOGID,
                      OPERACION = 'B',
                      USUARIO = P_USER_ID,
                      ultima_modificacion = SYSDATE
                WHERE     ID_DOCUMENTO = P_ID_DOCUMENT
                      AND CUENTA = CUR_CLIENTE.CUENTA
                      AND LOG_HASTA IS NULL;
            END LOOP;
            -- CARGO LA GELEC.ED_DOC.FECHA_FIN_DOC EN GELEC.ED_DET_DOCUMENTOS_CLIENTE.FECHA_FIN_CORTE PARA LOS QUE POSEEN VALORES NULOS
            SELECT FECHA_FIN_DOC INTO V_FECHA_FIN FROM GELEC.ED_DOCUMENTOS WHERE ID_DOCUMENTO=9085316;
			DBMS_OUTPUT.PUT_LINE(sysdate||'>> V_FECHA_FIN: '||V_FECHA_FIN);
            IF V_FECHA_FIN IS NULL THEN
                V_RESULTADO := 'EL DOCUMENTO NO POSEE FECHA DE FIN';
            ELSE
                --RSLEIVA NUEVO ACTUALIZA FECHA DE FIN EN CLIENTES
                UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES SET FECHA_FIN_CORTE=V_FECHA_FIN WHERE ID_DOCUMENTO=P_ID_DOCUMENT AND FECHA_FIN_CORTE IS NULL;
    
                -- CIERRO EL DOCUMENTO SETEANDOLE LOG_HASTA
                UPDATE GELEC.ED_DOCUMENTOS
                   SET LOG_HASTA = V_LOGID
                 WHERE ID_DOCUMENTO = P_ID_DOCUMENT;
    
    
                COMMIT;
                V_RESULTADO := 'SE HA COMPLETADO LA BAJA LOGICA';
                --P_RESULTADO := V_RESULTADO;
            END IF;    
         ELSE
            v_resultado := 'EL DOCUMENTO SE ENCUENTRA ACTIVO EN NEXUS';
            --P_RESULTADO := V_RESULTADO;
         END IF;
      ELSE
         v_resultado := 'EL DOCUMENTO YA SE ENCUENTRA DADO DE BAJA EN GELEC';
         --P_RESULTADO := V_RESULTADO;
      END IF;
	  DBMS_OUTPUT.PUT_LINE(sysdate||'>> V_RESULTADO: '||V_RESULTADO);
   end;
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