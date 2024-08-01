DROP PACKAGE GELEC.PKG_BATCH;

CREATE OR REPLACE PACKAGE GELEC.pkg_batch AS
PROCEDURE busca_cliente_edp (p_usuario     IN     VARCHAR2,
                                p_resultado      OUT VARCHAR2);
PROCEDURE buscar_doc_edp_afectados_nuevo (p_user_id     IN     VARCHAR2,
                                             p_resultado      OUT VARCHAR2);
PROCEDURE buscar_doc_reclamos_cerrados (p_user_id     IN     VARCHAR2,
                                           p_resultado      OUT VARCHAR2);
End pkg_batch;
/
DROP PACKAGE BODY GELEC.PKG_BATCH;

CREATE OR REPLACE PACKAGE BODY GELEC.pkg_batch
AS
   PROCEDURE busca_cliente_edp (p_usuario     IN     VARCHAR2,
                                p_resultado      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      /*******************************************************************
       * NOMBRE FUNCION: BUSCA_CLIENTE_EDP                               *
       * FECHA: 8/04/2019 ABERTOTTO                                      *
       *                                                                 *
       * DESCRIPCION: BUSCA DOCUMENTOS CON CLIENTES ELECTRODEPENDIENTES  *
       *              AFECTADOS DESDE NEXUS                              *
       *                                                                 *
       * PARAMETROS DE ENTRADA: P_USUARIO                                *
       * PARAMETRO DE SALIDA: P_RESULTADO                                *
       *   VALORES DE SALIDA                                             *
       *      % OK                                                       *
       *      % CLIENTE EXISTE EN GELEC                                  *
       *      % NO SE ENCONTRO CLIENTE EN NEXUS                          *
       *                                                                 *
       *******************************************************************/
      CURSOR c_clientes_edp
      IS
         SELECT cli.fsclientid   cuenta,
                cli.fullname     nombre,
                (SELECT lo.eventdate
                   FROM nexus_gis.sprlog lo
                  WHERE lo.logid = cli.logidfrom)
                   fecha_alta,
                sms.streetname   calle,
                cli.streetnumber altura,
                cli.streetother  otros,
                (SELECT sms1.streetname
                   FROM nexus_gis.smstreets sms1
                  WHERE     sms1.streetid = cli.streetid1
                        AND (sms1.dateto > SYSDATE OR sms1.dateto IS NULL))
                   calle1,
                (SELECT sms2.streetname
                   FROM nexus_gis.smstreets sms2
                  WHERE     sms2.streetid = cli.streetid2
                        AND (sms2.dateto > SYSDATE OR sms2.dateto IS NULL))
                   calle2,
                (SELECT loc.areaname
                   FROM nexus_gis.amareas loc
                  WHERE loc.areaid = cli.leveloneareaid)
                   localidad,
                (SELECT par.areaname
                   FROM nexus_gis.amareas par
                  WHERE par.areaid = cli.leveltwoareaid)
                   partido,
                CASE
                   WHEN pz.zona = 'CABA' THEN 1
                   WHEN pz.zona = 'La Matanza' THEN 2
                   WHEN pz.zona = 'Merlo' THEN 2
                   WHEN pz.zona = 'Moreno' THEN 3
                   WHEN pz.zona LIKE ('Mor_n') THEN 2
                   WHEN pz.zona = 'Olivos' THEN 1
                   WHEN pz.zona = 'Pilar' THEN 3
                   WHEN pz.zona LIKE ('San Mart_n') THEN 1
                   WHEN pz.zona = 'San Miguel' THEN 3
                   WHEN pz.zona = 'Tigre' THEN 3
                   ELSE 0
                END
                   AS region,
                cc.x,
                cc.y,
                cli.meterid      medidor,
                cc.ct,
                cc.alimentador,
                cc.ssee
           FROM nexus_gis.sprclients     cli,
                nexus_ccyb.clientes_ccyb cc,
                nexus_gis.smstreets      sms,
                nexus_gis.partido_zona   pz
          WHERE     cli.custatt21 = 12521
                AND cli.logidto = 0
                AND cli.fsclientid = cc.cuenta(+)
                AND cli.streetid = sms.streetid
                AND (sms.dateto > SYSDATE OR sms.dateto IS NULL)
                AND cli.leveltwoareaid = pz.areaid;


      v_existe_cliente   NUMBER;
      v_en_tramite       VARCHAR2 (1 CHAR);
      v_logid            NUMBER;
      v_resultado        VARCHAR2 (128 CHAR);
      clienteGelec       GELEC.ED_CLIENTES%ROWTYPE;
   BEGIN
      v_resultado := 'NO OK';

      --REVISAR COMO NO UTILIZAR LOGID SIN DOCUMENTOS A INFORMAR
      v_logid :=
         gelec.insert_log ('INSERTA CLIENTES ELECTRODEPENDIENTES.',
                           p_usuario);

      FOR cliente IN c_clientes_edp
      LOOP
         BEGIN
              SELECT COUNT (*), en_tramite
                INTO v_existe_cliente, v_en_tramite
                FROM gelec.ed_clientes ec
               WHERE ec.cuenta = cliente.cuenta
            GROUP BY en_tramite;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_existe_cliente := 0;
               v_en_tramite := 'N';
            WHEN OTHERS
            THEN
               v_resultado :=
                  'ERROR AL INSERTAR EN ED_CLIENTES: ' || cliente.cuenta;
         END;

         IF v_existe_cliente = 0
         THEN
            BEGIN
               INSERT INTO gelec.ed_clientes (cuenta,
                                              razon_social,
                                              f_alta,
                                              calle,
                                              nro,
                                              piso_dpto,
                                              ente_calle_1,
                                              ente_calle_2,
                                              localidad,
                                              partido,
                                              region,
                                              x,
                                              y,
                                              medidor,
                                              ct,
                                              alimentador,
                                              ssee,
                                              en_tramite,
                                              log_desde)
                    VALUES (cliente.cuenta,
                            cliente.nombre,
                            cliente.fecha_alta,
                            cliente.calle,
                            cliente.altura,
                            cliente.otros,
                            cliente.calle1,
                            cliente.calle2,
                            cliente.localidad,
                            cliente.partido,
                            cliente.region,
                            cliente.x,
                            cliente.y,
                            cliente.medidor,
                            cliente.ct,
                            cliente.alimentador,
                            cliente.ssee,
                            'N',
                            v_logid);

               insert_contacto_cliente (cliente.cuenta,
                                        p_usuario,
                                        p_resultado);
               v_resultado := 'OK';
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resultado :=
                     'ERROR AL INSERTAR EN ED_CLIENTES: ' || cliente.cuenta;
            END;
         ELSIF v_existe_cliente > 0
         THEN
            IF v_en_tramite = 'S'
            THEN
               BEGIN
                  INSERT INTO gelec.ed_auditoria (auditoria_log,
                                                  accion,
                                                  valor,
                                                  fecha,
                                                  usuario)
                          VALUES (
                                    v_logid,
                                    'ACTUALIZA CLIENTE ELECTRODEPENDIENTE EN TRAMITE',
                                    (SELECT    ec.cuenta
                                            || '|'
                                            || TRIM (ec.razon_social)
                                            || '|'
                                            || ec.f_alta
                                            || '|'
                                            || ec.f_baja_provisoria
                                            || '|'
                                            || ec.f_baja
                                            || '|'
                                            || TRIM (ec.calle)
                                            || '|'
                                            || ec.nro
                                            || '|'
                                            || ec.piso_dpto
                                            || '|'
                                            || TRIM (ec.ente_calle_1)
                                            || '|'
                                            || TRIM (ec.ente_calle_2)
                                            || '|'
                                            || TRIM (ec.localidad)
                                            || '|'
                                            || TRIM (ec.partido)
                                            || '|'
                                            || ec.region
                                            || '|'
                                            || ec.x
                                            || '|'
                                            || ec.y
                                            || '|'
                                            || ec.medidor
                                            || '|'
                                            || ec.ct
                                            || '|'
                                            || ec.alimentador
                                            || '|'
                                            || ec.ssee
                                            || '|'
                                            || ec.actualizado
                                            || '|'
                                            || ec.en_tramite
                                            || '|'
                                            || ec.requiere_fae
                                            || '|'
                                            || ec.log_desde
                                            || '|'
                                            || ec.log_hasta
                                       FROM gelec.ed_clientes ec
                                      WHERE ec.cuenta = cliente.cuenta),
                                    SYSDATE,
                                    p_usuario);

                  UPDATE gelec.ed_clientes ec
                     SET ec.cuenta = cliente.cuenta,
                         ec.razon_social = cliente.nombre,
                         ec.f_alta = cliente.fecha_alta,
                         ec.calle = cliente.calle,
                         ec.nro = cliente.altura,
                         ec.piso_dpto = cliente.otros,
                         ec.ente_calle_1 = cliente.calle1,
                         ec.ente_calle_2 = cliente.calle2,
                         ec.localidad = cliente.localidad,
                         ec.partido = cliente.partido,
                         ec.region = cliente.region,
                         ec.x = cliente.x,
                         ec.y = cliente.y,
                         ec.medidor = cliente.medidor,
                         ec.ct = cliente.ct,
                         ec.alimentador = cliente.alimentador,
                         ec.ssee = cliente.ssee,
                         ec.en_tramite = 'N',
                         ec.log_desde = v_logid
                   WHERE ec.cuenta = cliente.cuenta;

                  v_resultado := 'OK';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resultado :=
                        'ERROR AL ACTUALIZAR ED_CLIENTES: ' || cliente.cuenta;
               END;
            ELSE
               -- Busco si hay novedades en el registro nexus (surgieron problemas por no actualizar el registro)

               SELECT *
                 INTO clienteGelec
                 FROM GELEC.ED_CLIENTES c
                WHERE c.CUENTA = cliente.cuenta;

               IF (   NVL (clienteGelec.ct, 'X') != NVL (cliente.ct, 'X')
                   OR NVL (clienteGelec.ssee, 'X') != NVL (cliente.ssee, 'X')
                   OR NVL (clienteGelec.alimentador, 'X') !=
                         NVL (cliente.alimentador, 'X')
                   OR NVL (clienteGelec.x, 0) != NVL (cliente.x, 0)
                   OR NVL (clienteGelec.y, 0) != NVL (cliente.y, 0)
                   OR NVL (clienteGelec.medidor, 'X') !=
                         NVL (cliente.medidor, 'X')
                   OR NVL (clienteGelec.calle, 'X') !=
                         NVL (cliente.calle, 'X')
                   OR NVL (clienteGelec.ente_calle_1, 'X') !=
                         NVL (cliente.calle1, 'X')
                   OR NVL (clienteGelec.ente_calle_2, 'X') !=
                         NVL (cliente.calle2, 'X')
                   OR NVL (clienteGelec.nro, 0) != NVL (cliente.altura, 0)
                   OR NVL (clienteGelec.piso_dpto, 'X') !=
                         NVL (cliente.otros, 'X'))
               THEN
                  -- update
                  UPDATE GELEC.ED_CLIENTES c
                     SET c.ct = cliente.ct,
                         c.SSEE = cliente.ssee,
                         c.alimentador = cliente.alimentador,
                         c.x = cliente.x,
                         c.y = cliente.y,
                         c.MEDIDOR = cliente.medidor,
                         c.calle = cliente.calle,
                         c.ente_calle_1 = cliente.calle1,
                         c.ente_calle_2 = cliente.calle2,
                         c.nro = cliente.altura,
                         c.PISO_DPTO = cliente.otros
                   WHERE c.cuenta = cliente.cuenta;
               END IF;
            END IF;
         END IF;
      END LOOP;

      -- Doy de baja los que ya no son EDP en SPRCLIENTS
      UPDATE GELEC.ED_CLIENTES c
         SET c.LOG_HASTA = v_logid
       WHERE     (c.CUENTA NOT IN (SELECT s.FSCLIENTID
                                    FROM NEXUS_GIS.SPRCLIENTS s
                                   WHERE s.CUSTATT21 = '12521'
                                   and s.FSCLIENTID = c.cuenta)
           or (select TRIM(estado) from NEXUS_CCYB.CLIENTES_CCYB where cuenta = c.cuenta) in ('TERMINADO', 'CERRADO'))
and c.log_hasta is null;

      -- Doy de alta los que estaban de baja y volvieron a aparecer como EDP en SPRCLIENTS
      UPDATE GELEC.ED_CLIENTES c
         SET c.LOG_HASTA = NULL
       WHERE     c.CUENTA IN (SELECT s.FSCLIENTID
                                FROM NEXUS_GIS.SPRCLIENTS s
                               WHERE s.CUSTATT21 = '12521'
                               and s.FSCLIENTID = c.cuenta)
             AND c.LOG_HASTA IS NOT NULL;


      COMMIT;
      v_resultado := 'OK';
      p_resultado := v_resultado;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END;

   PROCEDURE buscar_doc_edp_afectados_nuevo (p_user_id     IN     VARCHAR2,
                                             p_resultado      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR c_documentos_afectados
      IS
         SELECT Sc.Cuenta,
                E.Affect_Time  Fecha_Inicio,
                E.Restore_Time Fecha_Restauracion,
                Sc.Razon_Social,
                D.Id           Documento,
                C.Id           Reclamo,
                'AF'           AS Origen
           FROM Nexus_Gis.Nbm_Mon_Element E
                INNER JOIN Gelec.Ed_Clientes Sc ON E.Customer_Id = Sc.Cuenta
                INNER JOIN Nexus_Gis.Oms_Document D
                   ON D.Id = E.Affect_Document_Id
                LEFT JOIN Nexus_Gis.Oms_Claim C
                   ON D.Id = C.Document_Id AND Sc.Cuenta = C.Property_Value
          WHERE     Element_To_Affect_Id IN (1,
                                             3,
                                             5,
                                             6)
                AND Sc.LOG_HASTA IS NULL
         UNION
         SELECT Sc.Cuenta,
                E.Affect_Time  Fecha_Inicio,
                E.Restore_Time Fecha_Restauracion,
                Sc.Razon_Social,
                D.Id           Documento,
                C.Id           Reclamo,
                'AF'           AS Origen
           FROM Nexus_Gis.Nbm_Mon_Element E
                INNER JOIN Nexus_Gis.Oms_Document D
                   ON D.Id = E.Affect_Document_Id
                INNER JOIN Nexus_Gis.Nbm_Mon_Trafos T
                   ON     E.Object_Name_Id = T.Parent_Object_Name_Id
                      AND T.Revision_Id_To = 0
                INNER JOIN Nexus_Gis.Nbm_Relation_Values Rv
                   ON     Rv.Object_Name_Id_From = T.Object_Name_Id
                      AND Rv.Property_Id = 2
                INNER JOIN Gelec.Ed_Clientes Sc
                   ON Rv.Property_Value = Sc.Cuenta
                LEFT JOIN Nexus_Gis.Oms_Claim C
                   ON D.Id = C.Document_Id AND Sc.Cuenta = C.Property_Value
          WHERE Element_To_Affect_Id IN (2, 4) AND Sc.LOG_HASTA IS NULL
         UNION
         SELECT Cli.Cuenta      Cuenta,
                C.Creation_Time AS Fecha_Inicio,
                Cc.Closing_Time AS Fecha_Restauracion,
                Cli.Razon_Social,
                D.Id            AS Documento,
                C.Id            AS Reclamo,
                'REC'           AS Origen
           FROM Nexus_Gis.Oms_Claim       C,
                Nexus_Gis.Oms_Document    D,
                Gelec.Ed_Clientes         Cli,
                Nexus_Gis.Oms_Claim_Close Cc
          WHERE     C.Property_Value = Cli.Cuenta
                AND D.Id = C.Document_Id
                AND C.Close_Info_Id = Cc.Id(+)
                AND D.Last_State_Id < 5
                AND Cli.Log_Hasta IS NULL;

      CURSOR c_detalle_documento (
         id_documento    VARCHAR2)
      IS
         SELECT d.id,
                d.name          nro_documento,
                dt.description  tipo_corte,
                ds.description  estado_doc,
                d.creation_time fecha_inicio_doc,
                CASE
                   WHEN pz.zona = 'CABA' THEN 1
                   WHEN pz.zona = 'La Matanza' THEN 2
                   WHEN pz.zona = 'Merlo' THEN 2
                   WHEN pz.zona = 'Moreno' THEN 3
                   WHEN pz.zona LIKE ('Mor_n') THEN 2
                   WHEN pz.zona = 'Olivos' THEN 1
                   WHEN pz.zona = 'Pilar' THEN 3
                   WHEN pz.zona LIKE ('San Mart_n') THEN 1
                   WHEN pz.zona = 'San Miguel' THEN 3
                   WHEN pz.zona = 'Tigre' THEN 3
                   ELSE 0
                END
                   AS region,
                pz.zona,
                pz.partido,
                am.areaname     localidad,
                d.last_state_id id_estado,
                d.notes         notas
           FROM nexus_gis.oms_document       d,
                nexus_gis.oms_document_type  dt,
                nexus_gis.oms_document_state ds,
                nexus_gis.oms_address        ad,
                nexus_gis.partido_zona       pz,
                nexus_gis.amareas            am
          WHERE     d.id = id_documento
                AND dt.id = d.type_id
                AND ds.id = d.last_state_id
                AND d.address_id = ad.id
                AND ad.medium_area_id = pz.areaid(+)
                AND ad.small_area_id = am.areaid(+);

      CURSOR c_detalle_reclamo (id_reclamo VARCHAR2)
      IS
         SELECT c.name              reclamo,
                c.document_id       id_documento,
                c.count_reiteration reiteraciones,
                c.type_id           id_tipo_reclamo,
                c.notes             descripcion,
                c.customer_time     fecha_creacion_cliente,
                c.creation_time     fecha_procesamiento,
                c.last_state_id     id_estado,
                c.name              nombre
           FROM nexus_gis.oms_claim c
          WHERE c.id = id_reclamo;

      CURSOR c_anomalias (id_documento NUMBER)
      IS
         SELECT a.id id, a.notes notas
           FROM nexus_gis.oms_anomaly a
          WHERE id_documento = a.document_id;

      -- VARIABLES DOCUMENTO

      v_estado                       VARCHAR2 (20 BYTE);
      v_notas                        VARCHAR2 (2000 BYTE);
      v_tipo_corte                   VARCHAR2 (50 BYTE);
      v_id_estado_documento          NUMBER;
      -- VARIABLES RECLAMO
      v_id_documento                 NUMBER;
      v_descripcion                  VARCHAR (2000 BYTE);
      v_reiteraciones                NUMBER;
      v_id_estado                    NUMBER;
      -- VARIABLES PARA ANOMALIAS
      v_existe_anomalia              NUMBER;
      -- VARIABLES PARA COUNT
      v_detalle_a_modificar          NUMBER;
      v_documento_en_gelec           NUMBER;
      v_documento_cliente_en_gelec   NUMBER;
      v_reclamo_en_gelec             NUMBER;
      v_documentos_agregados         NUMBER;
      v_documentos_modificados       NUMBER;
      v_doc_cliente_agregados        NUMBER;
      v_doc_cliente_modificados      NUMBER;
      v_reclamos_agregados           NUMBER;
      v_reclamos_modificados         NUMBER;
      --
      v_logid                        NUMBER;
      v_doc_cliente_nextval          NUMBER;
      v_resultado                    VARCHAR2 (100);
      v_id_batch_log                 NUMBER;
      v_verificar_ct                 VARCHAR2 (30);
      v_auditoria_id                 NUMBER;
      rNexus                         NEXUS_GIS.OMS_CLAIM%ROWTYPE;
   BEGIN
      v_resultado := 'OK';
      v_documentos_agregados := 0;
      v_documentos_modificados := 0;
      v_doc_cliente_agregados := 0;
      v_doc_cliente_modificados := 0;
      v_reclamos_modificados := 0;
      v_reclamos_agregados := 0;
      v_logid :=
         gelec.insert_log (
            'INSERTA DOCUMENTOS CON ELECTRODEPENDIENTES AFECTADOS',
            p_user_id);

      FOR documento IN c_documentos_afectados
      LOOP
         DBMS_OUTPUT.put_line (
               'DOCUMENTID: '
            || documento.Documento
            || ' | RECLAMO: '
            || documento.Reclamo);


         -- POR CADA DOCUMENTO BUSCO SU DETALLE Y LO INSERTO EN GELEC
         FOR detalle IN c_detalle_documento (documento.Documento)
         LOOP
            SELECT COUNT (*)
              INTO v_documento_en_gelec
              FROM gelec.ed_documentos d
             WHERE d.id_documento = documento.Documento;

            IF v_documento_en_gelec > 0
            -- DOCUMENTO YA EXISTE EN GELEC

            THEN
               DBMS_OUTPUT.put_line ('DOCUMENTO EXISTE EN GELEC');

               -- COMPARO LOS VALORES ACTUALES CON LOS DE NEXUS
               SELECT d.estado_doc,
                      d.notas,
                      d.tipo_corte,
                      d.id_estado
                 INTO v_estado,
                      v_notas,
                      v_tipo_corte,
                      v_id_estado_documento
                 FROM gelec.ed_documentos d
                WHERE d.id_documento = documento.Documento;

               IF    v_estado != detalle.estado_doc
                  OR v_notas != detalle.notas
                  OR v_tipo_corte != detalle.tipo_corte
                  OR v_id_estado_documento != detalle.id_estado
               THEN
                  DBMS_OUTPUT.put_line ('HAY CAMBIOS EN EL DOCUMENTO');
                  v_documentos_modificados := v_documentos_modificados + 1;

                  BEGIN
                     UPDATE gelec.ed_documentos d
                        SET d.estado_doc = detalle.estado_doc,
                            d.notas = detalle.notas,
                            d.tipo_corte = detalle.tipo_corte,
                            d.id_estado = detalle.id_estado
                      WHERE d.id_documento = documento.Documento;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resultado :=
                              'ERROR AL UPDATEAR EN ED_DOCUMENTOS: '
                           || documento.Documento;
                  END;
               END IF;
            -- DOCUMENTO NO EXISTE EN GELEC

            ELSE
               DBMS_OUTPUT.put_line ('DOCUMENTO NO EXISTE EN GELEC');
               v_documentos_agregados := v_documentos_agregados + 1;

               BEGIN
                  INSERT INTO gelec.ed_documentos (id_documento,
                                                   nro_documento,
                                                   tipo_corte,
                                                   estado_doc,
                                                   fecha_inicio_doc,
                                                   fecha_fin_doc,
                                                   region,
                                                   zona,
                                                   partido,
                                                   localidad,
                                                   log_desde,
                                                   log_hasta,
                                                   notas,
                                                   id_estado)
                       VALUES (documento.Documento,
                               detalle.nro_documento,
                               detalle.tipo_corte,
                               detalle.estado_doc,
                               detalle.fecha_inicio_doc,
                               NULL,
                               detalle.region,
                               detalle.zona,
                               detalle.partido,
                               detalle.localidad,
                               v_logid,
                               NULL,
                               detalle.notas,
                               detalle.id_estado);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resultado :=
                           'ERROR AL INSERTAR EN ED_DOCUMENTOS: '
                        || documento.Documento;
               END;
            END IF;

            SELECT COUNT (*)
              INTO v_documento_cliente_en_gelec
              FROM gelec.ed_det_documentos_clientes dc
             WHERE     dc.cuenta = documento.cuenta
                   AND dc.id_documento = documento.Documento
                   AND dc.FECHA_INICIO_CORTE = documento.fecha_inicio;


            -- Si no existe el cliente afectado, creo el detalle y busco si hay algun detalle para cerrar
            IF v_documento_cliente_en_gelec = 0
            THEN
               DBMS_OUTPUT.put_line (
                  'Crear nueva relacion para la afectacion');
               v_doc_cliente_agregados := v_doc_cliente_agregados + 1;
               v_doc_cliente_nextval :=
                  gelec.seq_det_doc_cliente.NEXTVAL ();

               IF UPPER (detalle.tipo_corte) = 'FORZADO BT'
               THEN
                  v_verificar_ct :=
                     gelec.revisar_verificar_ct (documento.cuenta,
                                                 detalle.nro_documento);
               END IF;

               BEGIN
                  INSERT
                    INTO gelec.ed_det_documentos_clientes (id_doc_cliente,
                                                           id_documento,
                                                           cuenta,
                                                           ct_clie,
                                                           estado_clie,
                                                           solucion_provisoria,
                                                           log_desde,
                                                           log_hasta,
                                                           fecha_inicio_corte,
                                                           fecha_fin_corte,
                                                           origen,
                                                           operacion,
                                                           usuario,
                                                           ultima_modificacion)
                  VALUES (v_doc_cliente_nextval,
                          documento.Documento,
                          documento.cuenta,
                          (SELECT c.ct
                             FROM gelec.ed_clientes c
                            WHERE c.cuenta = documento.cuenta),
                          'Pendiente',
                          NULL,
                          v_logid,
                          NULL,
                          documento.fecha_inicio,
                          documento.fecha_restauracion,
                          documento.origen,
                          'A',
                          'Aplicacion',
                          SYSDATE);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resultado :=
                           'ERROR AL INSERTAR EN ED_DOCUMENTOS: '
                        || documento.Documento;
               END;

               -- Busco detalles anteriores
               SELECT COUNT (*)
                 INTO v_detalle_a_modificar
                 FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
                WHERE     dc.CUENTA = documento.cuenta
                      AND dc.ID_DOCUMENTO = documento.documento
                      AND dc.LOG_HASTA IS NULL
                      AND dc.FECHA_INICIO_CORTE < documento.fecha_inicio;

               IF v_detalle_a_modificar > 0
               THEN
                  UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
                     SET dc.LOG_HASTA = v_logid,
                         --dc.ESTADO_CLIE = 'Normalizado',
                         dc.OPERACION = 'B',
                         dc.USUARIO = 'Aplicacion',
                         dc.ULTIMA_MODIFICACION = SYSDATE
                   WHERE     dc.CUENTA = documento.cuenta
                         AND dc.ID_DOCUMENTO = documento.documento
                         AND dc.LOG_HASTA IS NULL
                         AND dc.FECHA_INICIO_CORTE < documento.fecha_inicio;

                  v_auditoria_id := GELEC.SEQ_AUDITORIA.NEXTVAL ();

                  INSERT INTO GELEC.ED_AUDITORIA a (a.AUDITORIA_LOG,
                                                    a.ACCION,
                                                    a.CUENTA,
                                                    a.FECHA,
                                                    a.ID_DOCUMENTO,
                                                    a.USUARIO,
                                                    a.VALOR)
                          VALUES (
                                    v_auditoria_id,
                                       'Cierra relacion documento cliente log id: '
                                    || v_logid
                                    || ' y cambia a estado normalizado',
                                    documento.cuenta,
                                    SYSDATE,
                                    documento.documento,
                                    'GELEC_BATCH',
                                    'Normalizado');
               END IF;

               -- Busco detalles posteriores | si existen cierro el detalle sobre el que estoy parado
               SELECT COUNT (*)
                 INTO v_detalle_a_modificar
                 FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
                WHERE     dc.CUENTA = documento.cuenta
                      AND dc.ID_DOCUMENTO = documento.documento
                      AND dc.LOG_HASTA IS NULL
                      AND dc.FECHA_INICIO_CORTE > documento.fecha_inicio;

               IF v_detalle_a_modificar > 0
               THEN
                  UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
                     SET dc.LOG_HASTA = v_logid,
                         dc.ESTADO_CLIE = 'Normalizado',
                         dc.USUARIO = 'Aplicacion',
                         dc.OPERACION = 'M',
                         dc.ULTIMA_MODIFICACION = SYSDATE
                   WHERE     dc.CUENTA = documento.cuenta
                         AND dc.ID_DOCUMENTO = documento.documento
                         AND dc.LOG_HASTA IS NULL
                         AND dc.FECHA_INICIO_CORTE = documento.fecha_inicio;

                  v_auditoria_id := GELEC.SEQ_AUDITORIA.NEXTVAL ();

                  INSERT INTO GELEC.ED_AUDITORIA a (a.AUDITORIA_LOG,
                                                    a.ACCION,
                                                    a.CUENTA,
                                                    a.FECHA,
                                                    a.ID_DOCUMENTO,
                                                    a.USUARIO,
                                                    a.VALOR)
                          VALUES (
                                    v_auditoria_id,
                                       'Cierra relacion documento cliente log id: '
                                    || v_logid
                                    || ' y cambia a estado normalizado',
                                    documento.cuenta,
                                    SYSDATE,
                                    documento.documento,
                                    'GELEC_BATCH',
                                    'Normalizado');
               END IF;
            ELSE
               -- Si existe el registro, me fijo si actualizo su fecha de restauracion
               UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
                  SET dc.FECHA_FIN_CORTE = documento.fecha_restauracion,
                      dc.USUARIO = 'Aplicacion',
                      dc.OPERACION = 'M',
                      dc.ULTIMA_MODIFICACION = SYSDATE
                WHERE     dc.CUENTA = documento.cuenta
                      AND dc.ID_DOCUMENTO = documento.documento
                      AND dc.FECHA_INICIO_CORTE = documento.fecha_inicio
                      AND dc.FECHA_FIN_CORTE IS NULL
                      AND dc.LOG_HASTA IS NULL
                      AND documento.fecha_restauracion IS NOT NULL;
            END IF;
         END LOOP;                            -- FIN LOOP DETALLE DE DOCUMENTO

         -- RECLAMOS

         FOR reclamo IN c_detalle_reclamo (documento.Reclamo)
         LOOP
            SELECT COUNT (*)
              INTO v_reclamo_en_gelec
              FROM gelec.ed_reclamos r
             WHERE r.id_reclamo = documento.Reclamo;

            IF v_reclamo_en_gelec = 0
            THEN
               -- RECLAMO NO EXISTE EN GELEC
               DBMS_OUTPUT.put_line ('EL RECLAMO NO EXISTE EN GELEC');
               v_reclamos_agregados := v_reclamos_agregados + 1;

               BEGIN
                  INSERT INTO gelec.ed_reclamos (id_reclamo,
                                                 id_tipo_reclamo,
                                                 id_documento,
                                                 cuenta,
                                                 descripcion,
                                                 fecha_creacion_cliente,
                                                 fecha_procesamiento,
                                                 reiteraciones,
                                                 id_estado,
                                                 nombre,
                                                 fecha_cierre,
                                                 ultima_reiteracion,
                                                 log_desde)
                       VALUES (documento.Reclamo,
                               reclamo.id_tipo_reclamo,
                               reclamo.id_documento,
                               documento.cuenta,
                               reclamo.descripcion,
                               reclamo.fecha_creacion_cliente,
                               reclamo.fecha_procesamiento,
                               reclamo.reiteraciones,
                               reclamo.id_estado,
                               reclamo.nombre,
                               NULL,
                               SYSDATE,
                               v_logid);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resultado :=
                           'ERROR AL INSERTAR EN ED_RECLAMOS: '
                        || documento.Reclamo;
               END;
            END IF;
         END LOOP;                              -- FIN LOOP DETALLE DE RECLAMO

         -- ANOMALIAS

         FOR anomalia IN c_anomalias (documento.Documento)
         LOOP
            SELECT COUNT (*)
              INTO v_existe_anomalia
              FROM gelec.ed_documento_anomalia da
             WHERE da.id = anomalia.id;

            IF v_existe_anomalia = 0
            THEN
               INSERT
                 INTO gelec.ed_documento_anomalia da (da.id,
                                                      da.id_documento,
                                                      da.nota)
               VALUES (anomalia.id, documento.Documento, anomalia.notas);
            END IF;
         END LOOP;                                       -- FIN LOOP ANOMALIAS
      END LOOP; -- FIN LOOP DOCUMENTOS DEL CLIENTE (ID_DOCUMENTO + ID_RECLAMO)

      COMMIT;
      GELEC.PKG_BATCH.BUSCAR_DOC_RECLAMOS_CERRADOS (p_user_id, v_resultado);

      -- Aca busco los reclamos de gelec y los updateo (sino se pueden perder reiteraciones por ejemplo)
      FOR rGelec IN (SELECT *
                       FROM GELEC.ED_RECLAMOS r
                      WHERE r.FECHA_CIERRE IS NULL)
      LOOP
         BEGIN
            SELECT *
              INTO rNexus
              FROM nexus_gis.oms_claim c
             WHERE c.id = rGelec.ID_RECLAMO;
         EXCEPTION
            WHEN OTHERS
            THEN
               CONTINUE;
         END;

         -- SI HAY DIFERENCIA, UPDATEO
         -- SI ES POR NUEVA REITERACION, ADEMAS MODIFICO LA ULTIMA MODIFICACION

         IF NVL (rNexus.count_reiteration, 0) !=
               NVL (rGelec.REITERACIONES, 0)
         THEN
            DBMS_OUTPUT.put_line ('HAY MODIFICACIONES');
            v_reclamos_modificados := v_reclamos_modificados + 1;

            BEGIN
               UPDATE gelec.ed_reclamos re
                  SET id_documento = rNexus.document_id,
                      descripcion = rNexus.notes,
                      reiteraciones = rNexus.count_reiteration,
                      id_estado = rNexus.last_state_id,
                      ULTIMA_REITERACION = SYSDATE
                WHERE re.id_reclamo = rGelec.ID_RECLAMO;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resultado :=
                        'ERROR AL UPDATEAR EN ED_RECLAMOS: '
                     || rGelec.ID_RECLAMO;
            END;

            -- A pedido de los usuarios cuando se actualiza un reclamo por nueva reiteracion el cliente pasa a estado pendiente
            UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES dc
               SET dc.ESTADO_CLIE = 'Pendiente',
                   dc.USUARIO = 'Aplicacion',
                   dc.OPERACION = 'M',
                   dc.ULTIMA_MODIFICACION = SYSDATE
             WHERE     dc.ID_DOCUMENTO = rNexus.document_id
                   AND dc.CUENTA = rNexus.property_value
                   AND dc.ESTADO_CLIE != 'Pendiente'
                   AND dc.LOG_HASTA IS NULL;

            INSERT INTO gelec.ed_auditoria (auditoria_log,
                                            accion,
                                            valor,
                                            fecha,
                                            usuario)
                    VALUES (
                              GELEC.SEQ_AUDITORIA.NEXTVAL,
                              'MODIFICA CLIENTE',
                                 'Cliente: '
                              || rNexus.property_value
                              || ' | Estado: Pendiente',
                              SYSDATE,
                              'APLICACION');
         ELSE
            IF    rGelec.id_documento != rNexus.document_id
               OR rGelec.descripcion != rNexus.notes
               OR rGelec.id_estado != rNexus.last_state_id
            THEN
               DBMS_OUTPUT.put_line ('HAY MODIFICACIONES');
               v_reclamos_modificados := v_reclamos_modificados + 1;

               BEGIN
                  UPDATE gelec.ed_reclamos re
                     SET id_documento = rNexus.document_id,
                         descripcion = rNexus.notes,
                         reiteraciones = rNexus.count_reiteration,
                         id_estado = rNexus.last_state_id
                   WHERE re.id_reclamo = rGelec.ID_RECLAMO;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resultado :=
                           'ERROR AL UPDATEAR EN ED_RECLAMOS: '
                        || rGelec.ID_RECLAMO;
               END;
            END IF;
         END IF;
      END LOOP;

      COMMIT;

      v_id_batch_log := gelec.seq_batch_log.NEXTVAL ();

      INSERT INTO gelec.ed_batch_log b (b.id, b.descripcion, b.fechaahora)
              VALUES (
                        v_id_batch_log,
                           'DOCUMENTOS AGREGADOS: '
                        || v_documentos_agregados
                        || ' | DOCUMENTOS MODIFICADOS: '
                        || v_documentos_modificados
                        || ' | DOCUMENTO-CLIENTE AGREGADOS: '
                        || v_doc_cliente_agregados
                        || ' | RECLAMOS AGREGADOS: '
                        || v_reclamos_agregados
                        || ' | RECLAMOS MODIFICADOS: '
                        || v_reclamos_modificados,
                        SYSDATE);

      COMMIT;

      -- Aca mergeo la data de enerminds en una tabla de historial, para analizar casos especificos
      MERGE INTO GELEC.ED_HISTORIAL_NOVEDADES h
           USING (SELECT Sc.Cuenta,
                         E.Affect_Time  Fecha_Inicio,
                         E.Restore_Time Fecha_Restauracion,
                         Sc.Razon_Social,
                         D.Id           Documento,
                         C.Id           Reclamo,
                         'AF'           AS Origen
                    FROM Nexus_Gis.Nbm_Mon_Element E
                         INNER JOIN Gelec.Ed_Clientes Sc
                            ON E.Customer_Id = Sc.Cuenta
                         INNER JOIN Nexus_Gis.Oms_Document D
                            ON D.Id = E.Affect_Document_Id
                         LEFT JOIN Nexus_Gis.Oms_Claim C
                            ON     D.Id = C.Document_Id
                               AND Sc.Cuenta = C.Property_Value
                   WHERE     Element_To_Affect_Id IN (1,
                                                      3,
                                                      5,
                                                      6)
                         AND Sc.LOG_HASTA IS NULL
                  UNION
                  SELECT Sc.Cuenta,
                         E.Affect_Time  Fecha_Inicio,
                         E.Restore_Time Fecha_Restauracion,
                         Sc.Razon_Social,
                         D.Id           Documento,
                         C.Id           Reclamo,
                         'AF'           AS Origen
                    FROM Nexus_Gis.Nbm_Mon_Element E
                         INNER JOIN Nexus_Gis.Oms_Document D
                            ON D.Id = E.Affect_Document_Id
                         INNER JOIN Nexus_Gis.Nbm_Mon_Trafos T
                            ON     E.Object_Name_Id = T.Parent_Object_Name_Id
                               AND T.Revision_Id_To = 0
                         INNER JOIN Nexus_Gis.Nbm_Relation_Values Rv
                            ON     Rv.Object_Name_Id_From = T.Object_Name_Id
                               AND Rv.Property_Id = 2
                         INNER JOIN Gelec.Ed_Clientes Sc
                            ON Rv.Property_Value = Sc.Cuenta
                         LEFT JOIN Nexus_Gis.Oms_Claim C
                            ON     D.Id = C.Document_Id
                               AND Sc.Cuenta = C.Property_Value
                   WHERE     Element_To_Affect_Id IN (2, 4)
                         AND Sc.LOG_HASTA IS NULL
                  UNION
                  SELECT Cli.Cuenta      Cuenta,
                         C.Creation_Time AS Fecha_Inicio,
                         Cc.Closing_Time AS Fecha_Restauracion,
                         Cli.Razon_Social,
                         D.Id            AS Documento,
                         C.Id            AS Reclamo,
                         'REC'           AS Origen
                    FROM Nexus_Gis.Oms_Claim       C,
                         Nexus_Gis.Oms_Document    D,
                         Gelec.Ed_Clientes         Cli,
                         Nexus_Gis.Oms_Claim_Close Cc
                   WHERE     C.Property_Value = Cli.Cuenta
                         AND D.Id = C.Document_Id
                         AND C.Close_Info_Id = Cc.Id(+)
                         AND D.Last_State_Id < 5
                         AND Cli.Log_Hasta IS NULL) q
              ON (    h.cuenta = q.cuenta
                  AND h.fecha_inicio = q.fecha_inicio
                  AND NVL ('x', h.fecha_restauracion) =
                         NVL ('x', q.fecha_restauracion)
                  AND h.razon_social = q.razon_social
                  AND h.documento = q.documento
                  AND NVL ('x', h.reclamo) = NVL ('x', q.reclamo)
                  AND h.origen = q.origen)
      WHEN NOT MATCHED
      THEN
         INSERT     (cuenta,
                     fecha_inicio,
                     fecha_restauracion,
                     razon_social,
                     documento,
                     reclamo,
                     origen)
             VALUES (q.cuenta,
                     q.fecha_inicio,
                     q.fecha_restauracion,
                     q.razon_social,
                     q.documento,
                     q.reclamo,
                     q.origen);

      COMMIT;


      p_resultado := v_resultado;
   END;


   PROCEDURE buscar_doc_reclamos_cerrados (p_user_id     IN     VARCHAR2,
                                           p_resultado      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR c_anomalias (id_documento NUMBER)
      IS
         SELECT a.id id, a.notes notas
           FROM nexus_gis.oms_anomaly a
          WHERE a.document_id = id_documento;

      CURSOR c_documentos_cerrados (
         id_documento    NUMBER)
      IS
         SELECT ds.description  estado_doc,
                (CASE
                    WHEN (SELECT MIN (dcp.fecha)
                            FROM nexus_gis.doc_cierre_provisorio dcp
                           WHERE dcp.document_id = d.id)
                            IS NULL
                    THEN
                       d.last_state_change_time
                    ELSE
                       (SELECT MIN (dcp.fecha)
                          FROM nexus_gis.doc_cierre_provisorio dcp
                         WHERE dcp.document_id = d.id)
                 END)
                   AS fecha_cierre_documento,
                d.LAST_STATE_ID id_estado
           FROM nexus_gis.oms_document d, nexus_gis.oms_document_state ds
          WHERE     d.id = id_documento
                AND d.last_state_id > 4
                AND ds.id = d.last_state_id;

      CURSOR c_reclamos_cerrados (
         id_reclamo    NUMBER)
      IS
         SELECT c.last_state_id id_estado, cc.closing_time fecha_cierre
           FROM nexus_gis.oms_claim c, nexus_gis.oms_claim_close cc
          WHERE     c.last_state_id > 1
                AND c.id = id_reclamo
                AND c.close_info_id = cc.id;

      v_documentos_modificados   NUMBER;
      v_reclamos_modificados     NUMBER;
      v_existe_anomalia          NUMBER;
   BEGIN
      v_documentos_modificados := 0;
      v_reclamos_modificados := 0;

      -- BUSCO CAMBIOS EN LOS DOCUMENTOS DE GELEC QUE NO ESTEN CON BAJA LOGICA
      FOR documento_gelec IN (SELECT d.id_documento
                                FROM gelec.ed_documentos d
                               WHERE d.log_hasta IS NULL)
      LOOP
         FOR documento_nexus
            IN c_documentos_cerrados (documento_gelec.id_documento)
         LOOP
            v_documentos_modificados := v_documentos_modificados + 1;

            UPDATE gelec.ed_documentos d
               SET d.estado_doc = documento_nexus.estado_doc,
                   d.fecha_fin_doc = documento_nexus.fecha_cierre_documento,
                   d.ID_ESTADO = documento_nexus.id_estado
             WHERE d.id_documento = documento_gelec.id_documento;
         END LOOP;                                      -- FIN DOCUMENTO_NEXUS

         FOR anomalia IN c_anomalias (documento_gelec.id_documento)
         LOOP
            SELECT COUNT (*)
              INTO v_existe_anomalia
              FROM gelec.ed_documento_anomalia da
             WHERE da.id = anomalia.id;

            IF v_existe_anomalia = 0
            THEN
               INSERT
                 INTO gelec.ed_documento_anomalia a (a.id,
                                                     a.id_documento,
                                                     a.nota)
                  VALUES (
                            anomalia.id,
                            documento_gelec.id_documento,
                            anomalia.notas);
            END IF;
         END LOOP;                                     -- FIN ANOMALIAS NUEVAS
      END LOOP;                                         -- FIN DOCUMENTO_GELEC

      FOR reclamo_gelec IN (SELECT r.id_reclamo
                              FROM gelec.ed_reclamos r
                             WHERE r.fecha_cierre IS NULL)
      LOOP
         FOR reclamo_nexus IN c_reclamos_cerrados (reclamo_gelec.id_reclamo)
         LOOP
            v_reclamos_modificados := v_reclamos_modificados + 1;

            UPDATE gelec.ed_reclamos r
               SET r.fecha_cierre = reclamo_nexus.fecha_cierre,
                   r.id_estado = reclamo_nexus.id_estado
             WHERE r.id_reclamo = reclamo_gelec.id_reclamo;
         END LOOP;                                        -- FIN RECLAMO NEXUS
      END LOOP;                                           -- FIN RECLAMO GELEC

      COMMIT;
      p_resultado :=
            'DOCUMENTOS MODIFICADOS: '
         || v_documentos_modificados
         || ' RECLAMOS MODIFICADOS: '
         || v_reclamos_modificados;
   END;
END pkg_batch;
/
