#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/GELEC_AsociaCuentaManual_3.ksh_$DATE.log
FILE_AUX=$LOG_DIR/GELEC_AsociaCuentaManual_3.ksh.log

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
   P_NRO_CLIENTE   VARCHAR2(20):='7492815047';
   P_USER_ID       VARCHAR2(20):='rsleiva';
   P_RESULTADO     VARCHAR2(50);
   
   CURSOR cur_cli (
      pnro_cliente    VARCHAR2)
   IS
      SELECT cli.fsclientid      cuenta,
             cli.fullname        nombre,
             cli.telephonenumber telefono,
             (SELECT lo.eventdate
                FROM nexus_gis.sprlog lo
               WHERE lo.logid = cli.logidfrom)
                fecha_alta,
             sms.streetname      calle,
             cli.streetnumber    altura,
             cli.streetother     otros,
             sms1.streetname     calle1,
             sms2.streetname     calle2,
             (SELECT loc.areaname
                FROM nexus_gis.amareas loc
               WHERE loc.areaid = cli.leveloneareaid)
                localidad,
             (SELECT par.areaname
                FROM nexus_gis.amareas par
               WHERE par.areaid = cli.leveltwoareaid)
                partido,
             DECODE (pz.zona,
                     'CABA', 1,
                     'La Matanza', 2,
                     'Merlo', 2,
                     'Moreno', 3,
                     'Morón', 2,
                     'Olivos', 1,
                     'Pilar', 3,
                     'San Martín', 1,
                     'San Miguel', 3,
                     'Tigre', 3,
                     0)
                region,
             cc.x,
             cc.y,
             cli.meterid         medidor,
             cc.ct,
             cc.alimentador,
             cc.ssee
        FROM nexus_gis.sprclients cli
             INNER JOIN NEXUS_CCYB.clientes_ccyb cc
                ON cc.cuenta = cli.FSCLIENTID
             LEFT JOIN nexus_gis.smstreets sms ON sms.STREETID = cli.STREETID
             LEFT JOIN nexus_gis.smstreets sms1
                ON sms1.streetid = cli.STREETID1
             LEFT JOIN nexus_gis.smstreets sms2
                ON sms2.streetid = cli.STREETID2
             LEFT JOIN nexus_gis.partido_zona pz
                ON pz.areaid = cli.LEVELTWOAREAID
       WHERE     cli.fsclientid = pnro_cliente
             AND cli.logidto = 0
             AND sms.dateto > SYSDATE;



   v_existe_cli   NUMBER;
   v_logid        NUMBER;
   v_resultado    VARCHAR2 (124);
BEGIN
  DBMS_OUTPUT.PUT_LINE('v_Resultado con estado inicial: '||v_Resultado);
   v_Resultado := 'NOK';
   --v_logid := GELEC.INSERT_LOG ('Inserta Cliente Manual', 'root');
   v_logid :=0;

   -- Verificar que el cliente no existe en GELEC
   SELECT COUNT (*)
     INTO v_existe_cli
     FROM GELEC.ED_CLIENTES Ec
    WHERE Ec.CUENTA = P_nro_Cliente;

   IF v_existe_cli != 0   THEN
      V_RESULTADO := 'Cliente Existe En GELEC';
      DBMS_OUTPUT.PUT_LINE('v_Resultado: '||v_Resultado);
   ELSE
      DBMS_OUTPUT.PUT_LINE('recorre cursor para insertar cliente');
      FOR c_cli IN cur_cli (P_nro_Cliente)       LOOP
         INSERT INTO gelec.ed_clientes (CUENTA,
                                        RAZON_SOCIAL,
                                        F_ALTA,
                                        CALLE,
                                        NRO,
                                        PISO_DPTO,
                                        ENTE_CALLE_1,
                                        ENTE_CALLE_2,
                                        LOCALIDAD,
                                        PARTIDO,
                                        REGION,
                                        X,
                                        Y,
                                        MEDIDOR,
                                        CT,
                                        ALIMENTADOR,
                                        SSEE,
                                        EN_TRAMITE,
                                        LOG_DESDE)
              VALUES (c_cli.cuenta,
                      c_cli.nombre,
                      c_cli.fecha_alta,
                      c_cli.calle,
                      c_cli.altura,
                      c_cli.otros,
                      c_cli.calle1,
                      c_cli.calle2,
                      c_cli.localidad,
                      c_cli.partido,
                      c_cli.region,
                      c_cli.x,
                      c_cli.y,
                      c_cli.medidor,
                      c_cli.ct,
                      c_cli.alimentador,
                      c_cli.ssee,
                      'S',
                      v_logid);

         COMMIT;
         V_RESULTADO := 'OK';
         DBMS_OUTPUT.PUT_LINE('v_Resultado: '||v_Resultado);
      END LOOP;

      DBMS_OUTPUT.PUT_LINE('pregunta si v-resultado es Ok');
      IF v_Resultado != 'OK'
      THEN
         V_RESULTADO := 'No Se Encontro Cliente en NEXUS';
         DBMS_OUTPUT.PUT_LINE('v_Resultado: '||v_Resultado);
      END IF;
   END IF;

   P_RESULTADO := V_RESULTADO;
   DBMS_OUTPUT.PUT_LINE('v_Resultado: '||v_Resultado);
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