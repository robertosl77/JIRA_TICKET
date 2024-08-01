DROP PROCEDURE GELEC.INSERT_CLIENTE_MANUAL;

CREATE OR REPLACE PROCEDURE GELEC.Insert_cliente_Manual ( P_nro_Cliente   IN     VARCHAR2,
                                                          P_user_id       IN     VARCHAR2,
                                                          P_Resultado        OUT VARCHAR2 )
IS
   /*******************************************************************/
   /* Nombre Funcion: Insert_CLiente_Manual                           */
   /* Fecha: 8/04/2019 PCORRAL                                        */
   /*                                                                 */
   /* Descripcion: Inserta un cliente cargado en forma manual         */
   /*              desde la aplicacion                                */
   /*                                                                 */
   /* Parametros de Entrada:                                          */
   /*          P_nro_cliente (numero del cliente a insertar)          */
   /*            P_user_id (usuario que realiza el insert)            */
   /* Parametro de Salida: P_Resultado                                */
   /*   Valores de Salida                                             */
   /*      % OK                                                       */
   /*      % Cliente Existe En GELEC                                  */
   /*      % No Se Encontro Cliente en NEXUS                          */
   /*                                                                 */
   /*                                                                 */
   /*  22/11/2022 RSLEIVA                                             */
   /*    Hay clientes, que en sprclients, las entre calles, aparecen  */
   /*    con id=0, este id no se encuentra en smstreets, generando	  */
   /*    que se filtren las cuentas como no existentes en NEXUS       */
   /*                                                                 */
   /*                                                                 */
   /*******************************************************************/


   CURSOR cur_cli (
      pnro_cliente    VARCHAR2 )
   IS
      SELECT cli.fsclientid      cuenta,
             cli.fullname        nombre,
             cli.telephonenumber telefono,
             ( SELECT lo.eventdate FROM nexus_gis.sprlog lo WHERE lo.logid = cli.logidfrom ) fecha_alta,
             sms.streetname      calle,
             cli.streetnumber    altura,
             cli.streetother     otros,
             sms1.streetname     calle1,
             sms2.streetname     calle2,
             ( SELECT loc.areaname FROM nexus_gis.amareas loc WHERE loc.areaid = cli.leveloneareaid ) localidad,
             ( SELECT par.areaname FROM nexus_gis.amareas par WHERE par.areaid = cli.leveltwoareaid ) partido,
             DECODE ( pz.zona,
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
                      0 )
                region,
             cc.x,
             cc.y,
             cli.meterid         medidor,
             cc.ct,
             cc.alimentador,
             cc.ssee
        FROM nexus_gis.sprclients     cli,
             NEXUS_CCYB.clientes_ccyb cc,
             nexus_gis.smstreets      sms,
             nexus_gis.smstreets      sms1,
             nexus_gis.smstreets      sms2,
             nexus_gis.partido_zona   pz
       WHERE     cli.fsclientid = pnro_cliente
             AND cli.logidto = 0
             AND cli.fsclientid = cc.cuenta(+)
             AND cli.streetid = sms.streetid
             AND cli.streetid1 = sms1.streetid(+)
             AND cli.streetid2 = sms2.streetid(+)
             AND sms.dateto > SYSDATE
             AND cli.leveltwoareaid = pz.areaid
			 AND rownum=1
			 ;



   v_existe_cli   NUMBER;
   v_logid        NUMBER;
   v_resultado    VARCHAR2 ( 124 );
BEGIN
   v_Resultado := 'NOK';
   v_logid := GELEC.INSERT_LOG ( 'Inserta Cliente Manual', 'root' );

   -- Verificar que el cliente no existe en GELEC
   SELECT COUNT ( * ) INTO v_existe_cli FROM GELEC.ED_CLIENTES Ec WHERE Ec.CUENTA = P_nro_Cliente;

   IF v_existe_cli != 0 THEN
      v_Resultado := 'Cliente Existe En GELEC';
   ELSE
      FOR c_cli IN cur_cli ( P_nro_Cliente ) LOOP
         INSERT INTO gelec.ed_clientes ( CUENTA,
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
                                         LOG_DESDE )
              VALUES ( c_cli.cuenta,
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
                       v_logid );

         COMMIT;
         v_Resultado := 'OK';
      END LOOP;

      IF v_Resultado != 'OK'
      THEN
         v_Resultado := 'No Se Encontro Cliente en NEXUS';
      END IF;
   END IF;

   P_resultado := v_resultado;
END Insert_cliente_Manual;
/
