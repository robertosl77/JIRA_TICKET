CREATE OR REPLACE PACKAGE GELEC.PKG_OTROS
AS
   PROCEDURE A_CONTACTO_INTERNO (P_NOMBRE      IN     VARCHAR2,
                                 P_CARGO       IN     VARCHAR2,
                                 P_REGION      IN     VARCHAR2,
                                 P_TELEFONO    IN     VARCHAR2,
                                 P_EMAIL       IN     VARCHAR2,
                                 P_LOCALIDAD   IN     VARCHAR2,
                                 P_PARTIDO     IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2);

   PROCEDURE B_CONTACTO_INTERNO (P_ID          IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2);

   PROCEDURE MIGRAR_CLIENTE (P_CUENTA      IN     VARCHAR2,
                             P_ORIGEN      IN     VARCHAR2,
                             P_DESTINO     IN     VARCHAR2,
                             P_LOG         IN     VARCHAR2,
                             P_ACCION      IN     VARCHAR2,
                             P_USUARIO     IN     VARCHAR2,
                             P_RESULTADO      OUT VARCHAR2);

   PROCEDURE MIGRAR_CUENTA (P_ORIGEN      IN     VARCHAR2,
                            P_DESTINO     IN     VARCHAR2,
                            P_USUARIO     IN     VARCHAR2,
                            P_RESULTADO      OUT VARCHAR2);

   PROCEDURE A_TELEFONO_CENSO (P_CUENTA     IN VARCHAR2,
                               P_TELEFONO   IN VARCHAR2,
                               P_LOG_ID     IN VARCHAR2);

   PROCEDURE INSERTAR_MARCA (P_USER_ID       IN     VARCHAR2,
                             P_ID_MARCA      IN     VARCHAR2,
                             P_ID_SUBMARCA   IN     VARCHAR2,
                             P_CUENTA        IN     VARCHAR2,
                             P_NOTA          IN     VARCHAR2,
                             P_RESULTADO        OUT VARCHAR2);

   PROCEDURE DELETE_LOGICO_DOCUMENTO (P_ID_DOCUMENT   IN     VARCHAR2,
                                      P_USER_ID       IN     VARCHAR2,
                                      P_RESULTADO        OUT VARCHAR2);

   PROCEDURE ASOCIARDOC_CLIENTE_NUEVO (P_NRO_DOCUMENT   IN     NUMBER,
                                       P_NRO_CLIENTE    IN     VARCHAR2,
                                       P_USER_ID        IN     VARCHAR2,
                                       P_RESULTADO         OUT VARCHAR2);

   PROCEDURE INSERT_DOC_MANUAL (P_NRO_DOCUMENT   IN     VARCHAR2,
                                P_USER_ID        IN     VARCHAR2,
                                P_RESULTADO         OUT VARCHAR2);

   PROCEDURE ACTUALIZA_CONTACTO_CLIENTE (P_ACCION          IN     VARCHAR2,
                                         P_CUENTA          IN     VARCHAR2,
                                         P_NOMBRE          IN     VARCHAR2,
                                         P_TELEFONO        IN     VARCHAR2,
                                         P_TIPO_CONTACTO   IN     VARCHAR2,
                                         P_USUARIO         IN     VARCHAR2,
                                         P_ID_TEL          IN     VARCHAR2,
                                         P_RESULTADO          OUT VARCHAR2);

   PROCEDURE ACTUALIZA_CLIENTE_DOC (P_ID_DOCUMENTO          IN     NUMBER,
                                    P_CUENTA                IN     VARCHAR2,
                                    P_ESTADO_CLIE           IN     VARCHAR2,
                                    P_SOLUCION_PROVISORIA   IN     VARCHAR2,
                                    P_USUARIO               IN     VARCHAR2,
                                    P_FECHA_FIN_EDITABLE    IN     DATE,
                                    P_RESULTADO                OUT NUMBER);

   PROCEDURE ACTUALIZA_DOCUMENTO (P_ID_DOCUMENTO   IN     NUMBER,
                                  P_ZONA           IN     VARCHAR2,
                                  P_REGION         IN     NUMBER,
                                  P_USUARIO        IN     VARCHAR2,
                                  P_RESULTADO         OUT NUMBER);

    PROCEDURE INSERTA_TELEFONO (P_DETALLE       IN  VARCHAR2,
                                P_USUARIO       IN  VARCHAR2,
                                P_CUENTA        IN  VARCHAR2,
                                P_NOMBRE        IN  VARCHAR2,
                                P_TELEFONO      IN  VARCHAR2,
                                P_TIPO_CONTACTO IN  VARCHAR2,
                                P_RESULTADO     OUT NUMBER);

END PKG_OTROS;
/


CREATE OR REPLACE PACKAGE BODY GELEC.PKG_OTROS
AS
   PROCEDURE A_CONTACTO_INTERNO (P_NOMBRE      IN     VARCHAR2,
                                 P_CARGO       IN     VARCHAR2,
                                 P_REGION      IN     VARCHAR2,
                                 P_TELEFONO    IN     VARCHAR2,
                                 P_EMAIL       IN     VARCHAR2,
                                 P_LOCALIDAD   IN     VARCHAR2,
                                 P_PARTIDO     IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      V_ID   NUMBER;
   BEGIN
      V_ID := GELEC.SEQ_AGENDA.NEXTVAL ();

      INSERT INTO GELEC.ED_AGENDA A (A.CARGO,
                                     A.EMAIL,
                                     A.ID_AGENDA,
                                     A.LOCALIDAD,
                                     A.LOG_DESDE,
                                     A.NOMBRE,
                                     A.PARTIDO,
                                     A.REGION,
                                     A.TELEFONO)
           VALUES (P_CARGO,
                   P_EMAIL,
                   V_ID,
                   P_LOCALIDAD,
                   P_LOG_ID,
                   P_NOMBRE,
                   P_PARTIDO,
                   P_REGION,
                   P_TELEFONO);

      COMMIT;
      P_RESULTADO := 'Se dio de alta el contacto interno';
   END;

   PROCEDURE B_CONTACTO_INTERNO (P_ID          IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE GELEC.ED_AGENDA A
         SET A.LOG_HASTA = P_LOG_ID
       WHERE A.ID_AGENDA = P_ID;

      COMMIT;
      P_RESULTADO := 'Se dio de baja el contacto interno';
   END;

   PROCEDURE MIGRAR_CLIENTE (P_CUENTA      IN     VARCHAR2,
                             P_ORIGEN      IN     VARCHAR2,
                             P_DESTINO     IN     VARCHAR2,
                             P_LOG         IN     VARCHAR2,
                             P_ACCION      IN     VARCHAR2,
                             P_USUARIO     IN     VARCHAR2,
                             P_RESULTADO      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR C_NOTAS
      IS
         SELECT CN.ID_CLI_NOTA, N.ID_NOTA
           FROM GELEC.ED_NOTAS N, GELEC.ED_CLIENTE_NOTA CN
          WHERE     N.ID_NOTA = CN.ID_NOTA
                AND CN.CUENTA = P_CUENTA
                AND CN.ID_DOCUMENTO = P_ORIGEN
                AND CN.LOG_HASTA IS NULL;

      CURSOR C_DOC_CLIENTE
      IS
         SELECT *
           FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
          WHERE     DC.CUENTA = P_CUENTA
                AND DC.ID_DOCUMENTO = P_ORIGEN
                AND DC.LOG_HASTA IS NULL;

      V_ID_CLIENTE_NOTA       NUMBER;
      V_CLIENTE_NOTA_EXISTE   NUMBER;
      V_DOC_CLIENTE_EXISTE    NUMBER;
      V_ID_DOC_CLIENTE        NUMBER;
   BEGIN
      -- SI NO ESTA VIVO EL DOC CLIENTE NO MIGRO NADA
      FOR DOC_CLIENTE IN C_DOC_CLIENTE
      LOOP
         -- NOTAS
         -----------------------------------------------------------------------------------------------
         FOR NOTA IN C_NOTAS
         LOOP
            -- Doy de baja la relacion si esta moviendo
            IF P_ACCION = 'mover'
            THEN
               UPDATE GELEC.ED_CLIENTE_NOTA CN
                  SET CN.LOG_HASTA = P_LOG
                WHERE     CN.ID_NOTA = NOTA.ID_NOTA
                      AND CN.CUENTA = P_CUENTA
                      AND CN.LOG_HASTA IS NULL;
            END IF;

            SELECT COUNT (*)
              INTO V_CLIENTE_NOTA_EXISTE
              FROM GELEC.ED_CLIENTE_NOTA CN
             WHERE     CN.CUENTA = P_CUENTA
                   AND CN.ID_NOTA = NOTA.ID_NOTA
                   AND CN.ID_DOCUMENTO = P_DESTINO
                   AND CN.LOG_HASTA IS NULL;

            IF V_CLIENTE_NOTA_EXISTE = 0
            THEN
               -- Si la relacion no existe en el documento destino, la inserto
               V_ID_CLIENTE_NOTA := GELEC.SEQ_CLI_NOTA.NEXTVAL ();

               INSERT INTO GELEC.ED_CLIENTE_NOTA CN (CN.CUENTA,
                                                     CN.ID_CLI_NOTA,
                                                     CN.ID_DOCUMENTO,
                                                     CN.ID_NOTA,
                                                     CN.LOG_DESDE)
                    VALUES (P_CUENTA,
                            V_ID_CLIENTE_NOTA,
                            P_DESTINO,
                            NOTA.ID_NOTA,
                            P_LOG);
            END IF;
         END LOOP;

         -----------------------------------------------------------------------------------------------
         -- DOC CLIENTE

         IF P_ACCION = 'mover'
         THEN
            UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
               SET DC.LOG_HASTA = P_LOG,
                   dc.operacion = 'B',
                   dc.usuario = P_USUARIO,
                   dc.ultima_modificacion = SYSDATE
             WHERE     DC.CUENTA = P_CUENTA
                   AND DC.ID_DOCUMENTO = P_ORIGEN
                   AND DC.LOG_HASTA IS NULL;
         END IF;

         SELECT COUNT (*)
           INTO V_DOC_CLIENTE_EXISTE
           FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
          WHERE     DC.CUENTA = P_CUENTA
                AND DC.ID_DOCUMENTO = P_DESTINO
                AND DC.LOG_HASTA IS NULL;

         IF V_DOC_CLIENTE_EXISTE = 0
         THEN
            V_ID_DOC_CLIENTE := GELEC.SEQ_DET_DOC_CLIENTE.NEXTVAL ();

            INSERT
              INTO GELEC.ED_DET_DOCUMENTOS_CLIENTES DC (DC.CT_CLIE,
                                                        DC.CUENTA,
                                                        DC.ESTADO_CLIE,
                                                        DC.FECHA_INICIO_CORTE,
                                                        DC.ID_DOC_CLIENTE,
                                                        DC.ID_DOCUMENTO,
                                                        DC.LOG_DESDE,
                                                        DC.SOLUCION_PROVISORIA,
                                                        DC.ORIGEN,
                                                        DC.OPERACION,
                                                        DC.USUARIO,
                                                        DC.ultima_modificacion)
            VALUES (DOC_CLIENTE.CT_CLIE,
                    P_CUENTA,
                    DOC_CLIENTE.ESTADO_CLIE,
                    DOC_CLIENTE.FECHA_INICIO_CORTE,
                    V_ID_DOC_CLIENTE,
                    P_DESTINO,
                    P_LOG,
                    DOC_CLIENTE.SOLUCION_PROVISORIA,
                    DOC_CLIENTE.ORIGEN,
                    'A',
                    P_USUARIO,
                    SYSDATE);
         END IF;
      END LOOP;

      COMMIT;
      P_RESULTADO := 'Finalizada la migracion';
   END;

   PROCEDURE MIGRAR_CUENTA (P_ORIGEN      IN     VARCHAR2,
                            P_DESTINO     IN     VARCHAR2,
                            P_USUARIO     IN     VARCHAR2,
                            P_RESULTADO      OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      V_LOG   NUMBER;
      V_CANT NUMBER;
   BEGIN
      --Inserta en GELEC.ED_LOG para obtener el ID_LOG
      V_LOG :=
         GELEC.INSERT_LOG (
               'Muda cuenta origen: '
            || P_ORIGEN
            || ' a cuenta destino: '
            || P_DESTINO,
            P_USUARIO);

      -- Migro los numeros de telefono que tengan llamadas efectivas o menos de 3 llamadas no efectivas
      -- 01/09/2022 rsleiva: se cambio este punto, ahora solo migra nros celulares efectivos (al menos 1) y que no se duplique en destino
          BEGIN
              FOR TEL IN (
                          SELECT DISTINCT UPPER(NVL(CC.NOMBRE,'MIGRADO')) NOMBRE, CC.TELEFONO, CC.TIPO_CONTACTO
                          FROM GELEC.ED_CONTACTOS_CLIENTES CC
                          WHERE
                              CUENTA=P_ORIGEN
                              AND NVL(CC.LOG_HASTA,0)=0
                              AND CC.TIPO_CONTACTO='Celular'
                              AND (SELECT COUNT(1) FROM GELEC.ED_NOTAS WHERE CUENTA=CC.CUENTA AND IDDESTINO=CC.ID_TEL AND EFECTIVO>0)>0                             --Filtra los que no tengan efectividad
                              AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA='4823070190' AND TELEFONO=CC.TELEFONO AND NVL(LOG_HASTA,0)=0)=0    --Filtra los que ya esten cargados en destino
              ) LOOP

                    GELEC.PKG_OTROS.INSERTA_TELEFONO (
                                                  'DA DE ALTA EL CONTACTO DE UNA CUENTA',
                                                  'Migracion',
                                                  P_DESTINO,
                                                  TEL.NOMBRE,
                                                  TEL.TELEFONO,
                                                  TEL.TIPO_CONTACTO,
                                                  P_RESULTADO);
              END LOOP;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:= 'Sin Telefono para migrar';
          END;

      -- Migro las notas de hace 6 meses
      -- 01/09/2022 rsleiva: se agrega a las notas migradas, en el campo observaciones, la leyenda [MIGRADO]
          BEGIN
              FOR NOTA IN (
                      SELECT
                          CN.ID_NOTA,
                          (SELECT OBSERVACIONES FROM GELEC.ED_NOTAS WHERE ID_NOTA=CN.ID_NOTA) OBSERVACIONES
                      FROM
                          GELEC.ED_CLIENTE_NOTA CN
                      WHERE
                          CN.CUENTA = P_ORIGEN
                          AND (SELECT ADD_MONTHS (L.FECHA, 6) FROM GELEC.ED_LOG L WHERE L.LOG_ID = CN.LOG_DESDE) >= SYSDATE
						  AND CN.ID_NOTA IN (SELECT ID_NOTA FROM GELEC.ED_NOTAS WHERE ID_TIPO_NOTA IN (3,4) AND OBSERVACIONES LIKE '%CLIENTE MULTIPLE%')

              ) LOOP
                    -- QUITO LEYENDA DE OTRA POSIBLE MIGRACION ANTERIOR PARA NO INCREMENTAR EL LARGO DEL CAMPO
                    NOTA.OBSERVACIONES:= REPLACE(NOTA.OBSERVACIONES,'[MIGRADO] ',NULL);
                    -- SI EL LARGO DE LA NOTA Y LO QUE SE ESTIMA QUE SE VA A AGREGAR SUPERA EL LIMITE NO INGRESA LEYENDA
                    IF 500-LENGTH(NOTA.OBSERVACIONES)>=35 THEN
                        NOTA.OBSERVACIONES:= '[MIGRADO] '||NOTA.OBSERVACIONES;
                    END IF;
                    --ACTUALIZO CAMPO OBSERVACIONES EN GELEC.ED_NOTAS
                    UPDATE GELEC.ED_NOTAS SET OBSERVACIONES=NOTA.OBSERVACIONES WHERE ID_NOTA=NOTA.ID_NOTA;
                    UPDATE GELEC.ED_CLIENTE_NOTA SET CUENTA=P_DESTINO WHERE ID_NOTA=NOTA.ID_NOTA;

              END LOOP;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:='Error al migrar notas';
          END;

      -- Migro marcas / verifico para no duplicar
      -- 26/05/2021 : Ahora me fijo solamente ID marca, para no tener 2 submarcas activas en una misma marca
      -- 01/09/2022 rsleiva: se corrige la baja potencial en origen, y se agrega la migracion unicamente del cliente multiple
          BEGIN
              --BAJA POTENCIAL
              SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE
              WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=1;
              --
              IF V_CANT=0 THEN
                  GELEC.PKG_OTROS.INSERTAR_MARCA (
                      P_USUARIO, 1, 4,
                      P_ORIGEN,
                      '[Marca: Baja Potencial | Submarca: MIGRACION]',
                      P_RESULTADO);
              END IF;
              --CLIENTE MULTIPLE EN ORIGEN
              SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE
              WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;
              --
              IF V_CANT=1 THEN
                  --CLIENTE MULTIPLE EN DESTINO
                  SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE
                  WHERE CUENTA=P_DESTINO AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;
                  --
                  IF V_CANT=0 THEN
                      GELEC.PKG_OTROS.INSERTAR_MARCA (
                          P_USUARIO, 9, 21,
                          P_DESTINO,
                          '[Marca: Baja Potencial | Submarca: MIGRACION]',
                          P_RESULTADO);
                  END IF;
              END IF;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  P_RESULTADO:='Error al migrar Marcas';
          END;

      -- Migro aparatologia / verifico cuenta destino para no duplicar registros
      UPDATE GELEC.ED_CLIENTE_ARTEFACTO a
         SET a.CUENTA = P_DESTINO
       WHERE     a.cuenta = P_ORIGEN
             AND (SELECT COUNT (*)
                    FROM GELEC.ED_CLIENTE_ARTEFACTO aa
                   WHERE     aa.CUENTA = P_DESTINO
                         AND aa.ID_APARATO = a.ID_APARATO
                         AND aa.log_hasta IS NULL) = 0
             AND a.LOG_HASTA IS NULL;

      -- Migro paciente / verifico que no este el paciente ya ingresado en la cuenta destino
      BEGIN
          FOR P IN (
                  SELECT DISTINCT DNI FROM GELEC.ED_PACIENTE_CLIENTE
                  WHERE
                      CUENTA= P_ORIGEN
                      AND LOG_HASTA IS NULL
          ) LOOP

              GELEC.PKG_PACIENTES.B_PACIENTE (
                                      P_ORIGEN,
                                      P.DNI,
                                      V_LOG,
                                      P_RESULTADO) ;
          END LOOP;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              P_RESULTADO:='Sin Telefono para migrar';
      END;


      COMMIT;

      P_RESULTADO := 'Migracion finalizada';
   END;

   PROCEDURE INSERTAR_MARCA (P_USER_ID       IN     VARCHAR2,
                             P_ID_MARCA      IN     VARCHAR2,
                             P_ID_SUBMARCA   IN     VARCHAR2,
                             P_CUENTA        IN     VARCHAR2,
                             P_NOTA          IN     VARCHAR2,
                             P_RESULTADO        OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      CURSOR C_MARCAS
      IS
         SELECT MC.ID, MC.ID_MARCA, MC.ID_SUBMARCA
           FROM GELEC.ED_MARCA_CLIENTE MC
          WHERE     MC.CUENTA = P_CUENTA
                AND MC.ID_MARCA = P_ID_MARCA
                AND MC.LOG_HASTA IS NULL;

      V_FLAG               NUMBER;
      V_LOG_ID             NUMBER;
      V_ID_MARCA_CLIENTE   NUMBER;
      V_ID_NOTA            NUMBER;
   BEGIN
      V_FLAG := 0;
      V_LOG_ID :=
         GELEC.INSERT_LOG (
               'Modifica marca: '
            || P_ID_MARCA
            || ' | Submarca: '
            || P_ID_SUBMARCA
            || ' | en cuenta nro: '
            || P_CUENTA,
            P_USER_ID);

      V_ID_NOTA := GELEC.SEQ_NOTAS.NEXTVAL ();

      -- INSERTO LA NOTA
      INSERT INTO GELEC.ED_NOTAS (ID_NOTA,
                                  USUARIO,
                                  IDDESTINO,
                                  FECHAHORA,
                                  OBSERVACIONES,
                                  EFECTIVO,
                                  LOG_DESDE,
                                  LOG_HASTA,
                                  ID_TIPO_NOTA)
           VALUES (V_ID_NOTA,
                   P_USER_ID,
                   NULL,
                   SYSDATE,
                   P_NOTA,
                   NULL,
                   V_LOG_ID,
                   NULL,
                   '3');


      FOR MARCA IN C_MARCAS
      LOOP
         -- CASO 1:
         -- MARCA Y SUBMARCA COINCIDEN, TIPO REVISION DE RED
         -- CASO 2:
         -- MARCA COINCIDE, DIFERENTE A REVISION DE RED
         IF P_ID_MARCA = 5 OR P_ID_MARCA = 4
         THEN
            IF P_ID_SUBMARCA = MARCA.ID_SUBMARCA
            THEN
               UPDATE GELEC.ED_MARCA_CLIENTE MC
                  SET MC.LOG_HASTA = V_LOG_ID
                WHERE MC.ID = MARCA.ID;

               V_FLAG := 1;
            END IF;
         ELSE
            IF P_ID_SUBMARCA = MARCA.ID_SUBMARCA
            THEN
               V_FLAG := 1;
            END IF;

            UPDATE GELEC.ED_MARCA_CLIENTE MC
               SET MC.LOG_HASTA = V_LOG_ID
             WHERE MC.ID = MARCA.ID;
         END IF;
      END LOOP;

      -- GENERO NUEVO REGISTRO SI NO ES EL MISMO TIPO DE SUBMARCA (EN ESE CASO SOLO LA REMUEVO)
      IF V_FLAG = 0
      THEN
         V_ID_MARCA_CLIENTE := GELEC.SEQ_MARCA_CLIENTE.NEXTVAL ();

         INSERT INTO GELEC.ED_MARCA_CLIENTE MC (ID,
                                                CUENTA,
                                                ID_MARCA,
                                                ID_SUBMARCA,
                                                LOG_DESDE,
                                                LOG_HASTA)
              VALUES (V_ID_MARCA_CLIENTE,
                      P_CUENTA,
                      P_ID_MARCA,
                      P_ID_SUBMARCA,
                      V_LOG_ID,
                      NULL);
      END IF;

      COMMIT;
      P_RESULTADO := V_ID_NOTA;
   END;

   PROCEDURE A_TELEFONO_CENSO (P_CUENTA     IN VARCHAR2,
                               P_TELEFONO   IN VARCHAR2,
                               P_LOG_ID     IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      V_ID_TELEFONO       NUMBER;
      V_EXISTE_TELEFONO   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO V_EXISTE_TELEFONO
        FROM GELEC.ED_CONTACTOS_CLIENTES CC
       WHERE CC.CUENTA = P_CUENTA AND CC.TELEFONO = P_TELEFONO;

      IF V_EXISTE_TELEFONO = 0
      THEN
         V_ID_TELEFONO := GELEC.SEQ_CONTACTO_CLIENTE.NEXTVAL ();

         INSERT INTO GELEC.ED_CONTACTOS_CLIENTES CC (CC.CUENTA,
                                                     CC.LOG_DESDE,
                                                     CC.TELEFONO,
                                                     CC.TIPO_CONTACTO,
                                                     CC.ID_TEL)
              VALUES (P_CUENTA,
                      P_LOG_ID,
                      P_TELEFONO,
                      'Censo',
                      V_ID_TELEFONO);

         COMMIT;
      END IF;
   END;

   PROCEDURE DELETE_LOGICO_DOCUMENTO (P_ID_DOCUMENT   IN     VARCHAR2,
                                      P_USER_ID       IN     VARCHAR2,
                                      P_RESULTADO        OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

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
         GELEC.INSERT_LOG ('BAJA LOGICA DOCUMENTO: ' || P_ID_DOCUMENT,
                           P_USER_ID);
      -- VERIFICO QUE EL DOCUMENTO NO SE ENCUENTRE CERRADO EN GELEC
      SELECT COUNT (*)
        INTO V_DOCUMENTO_ABIERTO
        FROM GELEC.ED_DOCUMENTOS
       WHERE ID_DOCUMENTO = P_ID_DOCUMENT AND LOG_HASTA IS NULL;

      IF V_DOCUMENTO_ABIERTO = 1
      THEN
         -- VERIFICO QUE EL DOCUMENTO ESTE CERRADO EN NEXUS
         SELECT COUNT (*)
           INTO V_DOCUMENTO_ABIERTO_NEXUS
           FROM NEXUS_GIS.OMS_DOCUMENT
          WHERE ID = P_ID_DOCUMENT AND LAST_STATE_ID < 5;


         IF V_DOCUMENTO_ABIERTO_NEXUS = 0
         THEN
            -- SETEO LOS CLIENTES ASOCIADOS A NORMALIZADOSS Y SETEO LOG_HASTA
            -- (LOS CANCELADOS LOS DEJO CANCELADOS)
            FOR CUR_CLIENTE IN CUR_LISTA_CLIENTES (P_ID_DOCUMENT)
            LOOP
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
            SELECT FECHA_FIN_DOC INTO V_FECHA_FIN FROM GELEC.ED_DOCUMENTOS WHERE ID_DOCUMENTO=P_ID_DOCUMENT;
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
				P_RESULTADO := V_RESULTADO;
			END IF;
         ELSE
            V_RESULTADO := 'EL DOCUMENTO SE ENCUENTRA ACTIVO EN NEXUS';
            P_RESULTADO := V_RESULTADO;
         END IF;
      ELSE
         V_RESULTADO := 'EL DOCUMENTO YA SE ENCUENTRA DADO DE BAJA EN GELEC';
         P_RESULTADO := V_RESULTADO;
      END IF;
   END;

   PROCEDURE INSERT_DOC_MANUAL (P_NRO_DOCUMENT   IN     VARCHAR2,
                                P_USER_ID        IN     VARCHAR2,
                                P_RESULTADO         OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      /*******************************************************************/
      /* NOMBRE FUNCION: INSERT_DOC_MANUAL                               */
      /* FECHA: 8/04/2019 PCORRAL                                        */
      /*                                                                 */
      /* DESCRIPCION: INSERTA UN DOCUMENTO CARGADO EN FORMA MANUAL       */
      /*              DESDE LA APLICACION                                */
      /*                                                                 */
      /* PARAMETROS DE ENTRADA:                                          */
      /*          P_NRO_DOCUMENT (NUMERO DEL DOCUMENTO A INSERTAR)       */
      /*            P_USER_ID (USUARIO QUE REALIZA EL INSERT)            */
      /* PARAMETRO DE SALIDA: P_RESULTADO                                */
      /*   VALORES DE SALIDA                                             */
      /*      % OK                                                       */
      /*      % DOCUMENTO EXISTE EN GELEC                                */
      /*      % DOCUMENTO NO EXISTE EN NEXUS                             */
      /*      % ERROR AL BUSCAR DOCUMENTO EN NEXUS                       */
      /*      % DOCUMENTO CERRADO O CANCELADO EN NEXUS                   */
      /*                                                                 */
      /*******************************************************************/


      CURSOR CUR_DOC (
         PID_DOC    NUMBER)
      IS
         SELECT DISTINCT
                D.ID,
                D.NAME,
                DT.DESCRIPTION  TIPO,
                DS.DESCRIPTION  ESTADO,
                D.CREATION_TIME FECHA_CREACION,
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
                   AS REGION,
                PZ.ZONA,
                PZ.PARTIDO,
                AM.AREANAME     LOCALIDAD,
                d.last_state_id id_estado,
                d.notes         notas
           FROM NEXUS_GIS.OMS_DOCUMENT       D,
                NEXUS_GIS.OMS_DOCUMENT_TYPE  DT,
                NEXUS_GIS.OMS_DOCUMENT_STATE DS,
                NEXUS_GIS.OMS_ADDRESS        AD,
                NEXUS_GIS.PARTIDO_ZONA       PZ,
                NEXUS_GIS.AMAREAS            AM
          WHERE     D.ID = PID_DOC
                AND DT.ID = D.TYPE_ID
                AND DS.ID = D.LAST_STATE_ID
                AND D.ADDRESS_ID = AD.ID
                AND AD.MEDIUM_AREA_ID = PZ.AREAID
                AND AD.SMALL_AREA_ID = AM.AREAID;

      CURSOR c_anomalias (id_documento NUMBER)
      IS
         SELECT a.id id, a.notes notas
           FROM nexus_gis.oms_anomaly a
          WHERE id_documento = a.document_id;

      V_EXISTE_DOC        NUMBER;
      V_LOGID             NUMBER;
      V_ID_DOC            NUMBER;
      V_STATE             NUMBER;
      V_RESULTADO         VARCHAR2 (124);
      v_existe_anomalia   NUMBER;
   BEGIN
      V_RESULTADO := 'OK';

      V_LOGID := GELEC.INSERT_LOG ('INSERTA DOCUMENTO MANUAL', P_USER_ID);

      -- VERIFICAR QUE EL DOCUMENTO NO EXISTE EN GELEC
      SELECT COUNT (*)
        INTO V_EXISTE_DOC
        FROM GELEC.ED_DOCUMENTOS ED
       WHERE ED.NRO_DOCUMENTO = P_NRO_DOCUMENT;


      IF V_EXISTE_DOC != 0
      THEN
         V_RESULTADO := 'DOCUMENTO EXISTE EN GELEC';
      ELSE
         BEGIN
            SELECT OD.ID, OD.LAST_STATE_ID
              INTO V_ID_DOC, V_STATE
              FROM NEXUS_GIS.OMS_DOCUMENT OD
             WHERE OD.NAME = P_NRO_DOCUMENT;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               V_RESULTADO := 'DOCUMENTO NO EXISTE EN NEXUS';
            WHEN OTHERS
            THEN
               V_RESULTADO := 'ERROR AL BUSCAR DOCUMENTO EN NEXUS';
         END;

         IF V_RESULTADO = 'OK'
         THEN
            FOR C_DOC IN CUR_DOC (V_ID_DOC)
            LOOP
               INSERT INTO GELEC.ED_DOCUMENTOS (ID_DOCUMENTO,
                                                NRO_DOCUMENTO,
                                                TIPO_CORTE,
                                                ESTADO_DOC,
                                                FECHA_INICIO_DOC,
                                                REGION,
                                                ZONA,
                                                PARTIDO,
                                                LOCALIDAD,
                                                LOG_DESDE,
                                                NOTAS,
                                                ID_ESTADO)
                    VALUES (C_DOC.ID,
                            C_DOC.NAME,
                            C_DOC.TIPO,
                            C_DOC.ESTADO,
                            C_DOC.FECHA_CREACION,
                            C_DOC.REGION,
                            C_DOC.ZONA,
                            C_DOC.PARTIDO,
                            C_DOC.LOCALIDAD,
                            V_LOGID,
                            C_DOC.NOTAS,
                            C_DOC.ID_ESTADO);

               COMMIT;
            END LOOP;

            FOR anomalia IN c_anomalias (V_ID_DOC)
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
                  VALUES (anomalia.id, V_ID_DOC, anomalia.notas);
               END IF;
            END LOOP;
         END IF;
      END IF;

      P_RESULTADO := V_RESULTADO;
   END;

   PROCEDURE ACTUALIZA_CONTACTO_CLIENTE (P_ACCION          IN     VARCHAR2,
                                         P_CUENTA          IN     VARCHAR2,
                                         P_NOMBRE          IN     VARCHAR2,
                                         P_TELEFONO        IN     VARCHAR2,
                                         P_TIPO_CONTACTO   IN     VARCHAR2,
                                         P_USUARIO         IN     VARCHAR2,
                                         P_ID_TEL          IN     VARCHAR2,
                                         P_RESULTADO          OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      V_DETALLE       VARCHAR2 (100);
      V_LOGID         NUMBER;
      V_RESULTADO     VARCHAR2 (32676);
      V_EXIST         NUMBER;
      V_ID_CONTACTO   NUMBER;
   BEGIN
      V_EXIST := 0;

      SELECT COUNT (*)
        INTO V_EXIST
        FROM GELEC.ED_CONTACTOS_CLIENTES
       WHERE     TRIM (CUENTA) = P_CUENTA
             AND TRIM (TELEFONO) = TRIM (P_TELEFONO)
             AND LOG_HASTA IS NULL;

      CASE
         WHEN P_ACCION = 'BAJA'
         THEN
            IF V_EXIST = 0
            THEN
               V_RESULTADO :=
                     'NO EXISTE EL TELEFONO '
                  || P_TELEFONO
                  || ' DE LA CUENTA '
                  || P_CUENTA
                  || ' A DAR DE BAJA';
            ELSE
               V_DETALLE := 'DA DE BAJA EL CONTACTO DE UNA CUENTA';
               V_LOGID := GELEC.INSERT_LOG (V_DETALLE, P_USUARIO);

               UPDATE GELEC.ED_CONTACTOS_CLIENTES CC
                  SET CC.LOG_HASTA = V_LOGID, CC.FECHA_BAJA = SYSDATE
                WHERE CC.ID_TEL = P_ID_TEL AND LOG_HASTA IS NULL;

               V_RESULTADO :=
                     'SE DIO DE BAJA EL TELEFONO '
                  || P_TELEFONO
                  || ' DE LA CUENTA '
                  || P_CUENTA;
            END IF;
         WHEN P_ACCION = 'ALTA'
         THEN
            IF V_EXIST > 0
            THEN
               V_RESULTADO :=
                     'YA EXISTE EL TELEFONO '
                  || P_TELEFONO
                  || ' DE LA CUENTA '
                  || P_CUENTA;
            ELSE
               BEGIN
                  V_DETALLE := 'DA DE ALTA EL CONTACTO DE UNA CUENTA';
                  V_LOGID := GELEC.INSERT_LOG (V_DETALLE, P_USUARIO);

                  V_ID_CONTACTO := GELEC.SEQ_CONTACTO_CLIENTE.NEXTVAL ();

                  INSERT INTO GELEC.ED_CONTACTOS_CLIENTES (ID_TEL,
                                                           CUENTA,
                                                           NOMBRE,
                                                           TELEFONO,
                                                           TIPO_CONTACTO,
                                                           FECHA_BAJA,
                                                           LOG_DESDE)
                       VALUES (V_ID_CONTACTO,
                               P_CUENTA,
                               P_NOMBRE,
                               P_TELEFONO,
                               P_TIPO_CONTACTO,
                               NULL,
                               V_LOGID);

                  V_RESULTADO :=
                        'Se dio de alta el telefono '
                     || P_TELEFONO
                     || ' para la cuenta '
                     || P_CUENTA;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.PUT_LINE (SQLERRM);
                     ROLLBACK;
                     V_RESULTADO :=
                           'Error al dar de alta nuevo numero: '
                        || P_TELEFONO
                        || ' para la cuenta '
                        || P_CUENTA;
               END;
            END IF;
         WHEN P_ACCION = 'MODIFICACION'
         THEN
            V_LOGID :=
               GELEC.INSERT_LOG ('Modifica contacto cliente', P_USUARIO);
            V_ID_CONTACTO := GELEC.SEQ_CONTACTO_CLIENTE.NEXTVAL ();

            UPDATE GELEC.ED_CONTACTOS_CLIENTES CC
               SET CC.NOMBRE = P_NOMBRE,
                   CC.TELEFONO = P_TELEFONO,
                   CC.TIPO_CONTACTO = P_TIPO_CONTACTO
             WHERE CC.ID_TEL = P_ID_TEL;

            V_RESULTADO := 'Modificacion completada';
         ELSE
            V_RESULTADO := 'No es una accion permitida: ' || P_ACCION;
      END CASE;

      COMMIT;
      P_RESULTADO := V_RESULTADO;
   END;

   PROCEDURE ACTUALIZA_CLIENTE_DOC (P_ID_DOCUMENTO          IN     NUMBER,
                                    P_CUENTA                IN     VARCHAR2,
                                    P_ESTADO_CLIE           IN     VARCHAR2,
                                    P_SOLUCION_PROVISORIA   IN     VARCHAR2,
                                    P_USUARIO               IN     VARCHAR2,
                                    P_FECHA_FIN_EDITABLE    IN     DATE,
                                    P_RESULTADO                OUT NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      V_ID_DOC_CLIENTE                 NUMBER (10);
      V_ESTADO_CLIE_ACT                VARCHAR2 (30);
      V_SOLUCION_PROVISORIA_ACT        VARCHAR2 (30);
      V_ID_AUDITORIA                   NUMBER;
      V_RESULTADO                      NUMBER (1);
      V_FECHA_FIN_EDITABLE_ACT         DATE;
      V_FECHA_FIN_EDITABLE_INGRESADA   DATE;
   BEGIN
      SELECT ID_DOC_CLIENTE,
             ESTADO_CLIE,
             SOLUCION_PROVISORIA,
             DC.FECHA_FIN_EDITABLE
        INTO V_ID_DOC_CLIENTE,
             V_ESTADO_CLIE_ACT,
             V_SOLUCION_PROVISORIA_ACT,
             V_FECHA_FIN_EDITABLE_ACT
        FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
       WHERE     ID_DOCUMENTO = P_ID_DOCUMENTO
             AND CUENTA = P_CUENTA
             AND LOG_HASTA IS NULL;

      V_FECHA_FIN_EDITABLE_INGRESADA := P_FECHA_FIN_EDITABLE;

      -- Si el usuario pone estado normalizado o con suministro automaticamente pongo fecha fin editable
	  -- Corregido se reemplaza UPPER por INITCAP ya que no estaba cumpliendose la condicion.
      IF     (   INITCAP (NVL (P_ESTADO_CLIE, '')) = 'Normalizado'
              OR INITCAP (NVL (P_ESTADO_CLIE, '')) = 'Con Suministro')
         AND V_FECHA_FIN_EDITABLE_ACT IS NULL
         AND P_FECHA_FIN_EDITABLE IS NULL
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := SYSDATE;
      END IF;

      -- Si el usuario pone un estado diferente a normalizado o con suministro, pongo fecha de fin en null
	  -- Corregido se reemplaza UPPER por INITCAP ya que no estaba cumpliendose la condicion.
      IF (    INITCAP (NVL (P_ESTADO_CLIE, '')) != 'Normalizado'
          AND INITCAP (NVL (P_ESTADO_CLIE, '')) != 'Con Suministro')
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := NULL;
      END IF;

      -- Cubro el caso de que cambie de normalizado a con suministro o viceversa
	  -- Corregido se reemplaza UPPER por INITCAP ya que no estaba cumpliendose la condicion.
      IF     INITCAP (NVL (P_ESTADO_CLIE, '')) IN
                ('Normalizado', 'Con Suministro')
         AND V_FECHA_FIN_EDITABLE_INGRESADA IS NULL
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := V_FECHA_FIN_EDITABLE_ACT;
      END IF;

      IF    V_ESTADO_CLIE_ACT != P_ESTADO_CLIE
         OR NVL (V_SOLUCION_PROVISORIA_ACT, ' ') !=
               NVL (P_SOLUCION_PROVISORIA, ' ')
         OR NVL (V_FECHA_FIN_EDITABLE_ACT,
                 TO_DATE ('1901-01-01', 'YYYY-MM-DD')) !=
               NVL (V_FECHA_FIN_EDITABLE_INGRESADA,
                    TO_DATE ('1901-01-01', 'YYYY-MM-DD'))
      THEN
         UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
            SET ESTADO_CLIE = NVL (P_ESTADO_CLIE, V_ESTADO_CLIE_ACT),
                SOLUCION_PROVISORIA =
                   NVL (P_SOLUCION_PROVISORIA, V_SOLUCION_PROVISORIA_ACT),
                DC.FECHA_FIN_EDITABLE = V_FECHA_FIN_EDITABLE_INGRESADA,
                OPERACION = 'M',
                USUARIO = P_USUARIO,
                ultima_modificacion = SYSDATE
          WHERE ID_DOC_CLIENTE = V_ID_DOC_CLIENTE;


         IF V_ESTADO_CLIE_ACT != P_ESTADO_CLIE
         THEN
            V_ID_AUDITORIA := GELEC.SEQ_AUDITORIA.NEXTVAL ();

            INSERT INTO GELEC.ED_AUDITORIA (AUDITORIA_LOG,
                                            ACCION,
                                            VALOR,
                                            FECHA,
                                            USUARIO,
                                            CUENTA,
                                            ID_DOCUMENTO)
                 VALUES (V_ID_AUDITORIA,
                         'Modifica estado cliente',
                         P_ESTADO_CLIE,
                         SYSDATE,
                         P_USUARIO,
                         P_CUENTA,
                         P_ID_DOCUMENTO);
         END IF;

         IF NVL (V_SOLUCION_PROVISORIA_ACT, ' ') != P_SOLUCION_PROVISORIA
         THEN
            V_ID_AUDITORIA := GELEC.SEQ_AUDITORIA.NEXTVAL ();

            INSERT INTO GELEC.ED_AUDITORIA (AUDITORIA_LOG,
                                            ACCION,
                                            VALOR,
                                            FECHA,
                                            USUARIO,
                                            CUENTA,
                                            ID_DOCUMENTO)
                 VALUES (V_ID_AUDITORIA,
                         'Modifica solucion provisoria',
                         P_SOLUCION_PROVISORIA,
                         SYSDATE,
                         P_USUARIO,
                         P_CUENTA,
                         P_ID_DOCUMENTO);
         END IF;

         IF P_FECHA_FIN_EDITABLE IS NOT NULL
         THEN
            V_ID_AUDITORIA := GELEC.SEQ_AUDITORIA.NEXTVAL ();

            INSERT INTO GELEC.ED_AUDITORIA (AUDITORIA_LOG,
                                            ACCION,
                                            VALOR,
                                            FECHA,
                                            USUARIO,
                                            CUENTA,
                                            ID_DOCUMENTO)
                 VALUES (V_ID_AUDITORIA,
                         'Modifica fecha fin editable',
                         P_FECHA_FIN_EDITABLE,
                         SYSDATE,
                         P_USUARIO,
                         P_CUENTA,
                         P_ID_DOCUMENTO);
         END IF;

         COMMIT;
         V_RESULTADO := 1;
      ELSE
         V_RESULTADO := 0;
      END IF;

      P_RESULTADO := V_RESULTADO;
   END;

   PROCEDURE ASOCIARDOC_CLIENTE_NUEVO (P_NRO_DOCUMENT   IN     NUMBER,
                                       P_NRO_CLIENTE    IN     VARCHAR2,
                                       P_USER_ID        IN     VARCHAR2,
                                       P_RESULTADO         OUT VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      /*******************************************************************/
      /* NOMBRE FUNCION: INSERT_DOC_MANUAL                               */
      /* FECHA: 8/04/2019 PCORRAL                                        */
      /*                                                                 */
      /* DESCRIPCION: INSERTA UN DOCUMENTO CARGADO EN FORMA MANUAL       */
      /*              DESDE LA APLICACION                                */
      /*                                                                 */
      /* PARAMETROS DE ENTRADA:                                          */
      /*           P_NRO_CLIENTE (NUMERO DEL CLIENTE A INSERTAR)         */
      /*          P_NRO_DOCUMENT (NUMERO DEL DOCUMENTO A INSERTAR)       */
      /*            P_USER_ID (USUARIO QUE REALIZA EL INSERT)            */
      /* PARAMETRO DE SALIDA: P_RESULTADO                                */
      /*   VALORES DE SALIDA                                             */
      /*      % OK                                                       */
      /*      % DOCUMENTO NO EXISTE EN GELEC                             */
      /*      % ERROR AL INSERTAR EN ED_DET_DOCUMENTOS_CLIENTES:         */
      /*      % NO SE ENCONTRO EL CLIENTE EN EL DOCUMENTO NEXUS          */
      /*                                                                 */
      /*******************************************************************/

      CURSOR CUR_CLIENTE_GELEC (NRO_CLIENTE VARCHAR2)
      IS
         SELECT *
           FROM GELEC.ED_CLIENTES
          WHERE CUENTA = NRO_CLIENTE;



      V_NRO_DOCUMENT       VARCHAR2 (32);
      V_NRO_CLIENTE        VARCHAR2 (32);
      V_RESULTADO          VARCHAR2 (256);
      V_LOGID              NUMBER;
      V_EXISTE_DOC         NUMBER;
      V_EXISTE_CLI_GELEC   NUMBER;
      V_EXISTE_CLI_NEXUS   NUMBER;
      V_EXISTE_RELACION    NUMBER;
      V_INSERT_MANUAL      VARCHAR2 (32);
   BEGIN
      V_RESULTADO := 'NO OK';
      V_NRO_DOCUMENT := P_NRO_DOCUMENT;
      V_NRO_CLIENTE := P_NRO_CLIENTE;

      SELECT COUNT (*)
        INTO V_EXISTE_RELACION
        FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
       WHERE     DC.CUENTA = P_NRO_CLIENTE
             AND DC.ID_DOCUMENTO = P_NRO_DOCUMENT
             AND DC.LOG_HASTA IS NULL;

      IF V_EXISTE_RELACION = 0
      THEN
         V_LOGID := GELEC.INSERT_LOG ('ASOCIAR DOCUMENTO CLIENTE', P_USER_ID);

         -- VERIFICO QUE EL DOCUMENTO EXISTE EN GELEC
         SELECT COUNT (*)
           INTO V_EXISTE_DOC
           FROM GELEC.ED_DOCUMENTOS ED
          WHERE ED.ID_DOCUMENTO = V_NRO_DOCUMENT;


         IF V_EXISTE_DOC = 0
         THEN
            V_RESULTADO := 'DOCUMENTO NO EXISTE EN GELEC';
         ELSE
            -- VERIFICO QUE EL CLIENTE EXISTE EN GELEC
            SELECT COUNT (*)
              INTO V_EXISTE_CLI_GELEC
              FROM GELEC.ED_CLIENTES
             WHERE CUENTA = V_NRO_CLIENTE;

            IF V_EXISTE_CLI_GELEC > 0
            THEN
               FOR C_CLIENTE IN CUR_CLIENTE_GELEC (P_NRO_CLIENTE)
               LOOP
                  BEGIN
                     INSERT
                       INTO GELEC.ED_DET_DOCUMENTOS_CLIENTES (
                               ID_DOC_CLIENTE,
                               ID_DOCUMENTO,
                               CUENTA,
                               CT_CLIE,
                               ESTADO_CLIE,
                               LOG_DESDE,
                               FECHA_INICIO_CORTE,
                               OPERACION,
                               USUARIO,
                               ultima_modificacion)
                     VALUES (GELEC.SEQ_DET_DOC_CLIENTE.NEXTVAL,
                             V_NRO_DOCUMENT,
                             V_NRO_CLIENTE,
                             C_CLIENTE.CT,
                             'Pendiente',
                             V_LOGID,
                             SYSDATE,
                             'A',
                             P_USER_ID,
                             SYSDATE);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_RESULTADO :=
                              'ERROR AL INSERTAR EN ED_DET_DOCUMENTOS_CLIENTES: '
                           || V_NRO_DOCUMENT;
                  END;

                  V_RESULTADO := 'OK';
               END LOOP;
            -- FIN CAMINO CLIENTE GELEC
            ELSE
               -- SI NO ENCUENTRO EL CLIENTE EN GELEC, LO BUSCO EN NEXUS Y LO INSERTO COMO PROVISORIO EN GELEC
               -- LUEGO LO INSERTO EN EL DOCUMENTO

               -- VERIFICO QUE EL CLIENTE EXISTE EN NEXUS
               SELECT COUNT (*)
                 INTO V_EXISTE_CLI_NEXUS
                 FROM NEXUS_GIS.SPRCLIENTS
                WHERE LOGIDTO = 0 AND FSCLIENTID = V_NRO_CLIENTE;

               IF V_EXISTE_CLI_NEXUS > 0
               THEN
                  -- LLAMO A PROCEDURE INSERTAR CLIENTE MANUAL
                  INSERT_CLIENTE_MANUAL (P_NRO_CLIENTE,
                                         P_USER_ID,
                                         V_INSERT_MANUAL);


                  IF V_INSERT_MANUAL = 'OK'
                  THEN
                     -- SI INSERTO EL CLIENTE PROVISORIO EN GELEC, LO ASOCIO AL DOCUMENTO
                     FOR C_CLIENTE IN CUR_CLIENTE_GELEC (P_NRO_CLIENTE)
                     LOOP
                        BEGIN
                           INSERT
                             INTO GELEC.ED_DET_DOCUMENTOS_CLIENTES (
                                     ID_DOC_CLIENTE,
                                     ID_DOCUMENTO,
                                     CUENTA,
                                     CT_CLIE,
                                     ESTADO_CLIE,
                                     LOG_DESDE,
                                     FECHA_INICIO_CORTE,
                                     OPERACION,
                                     USUARIO,
                                     ultima_modificacion)
                           VALUES (GELEC.SEQ_DET_DOC_CLIENTE.NEXTVAL,
                                   V_NRO_DOCUMENT,
                                   V_NRO_CLIENTE,
                                   C_CLIENTE.CT,
                                   'PENDIENTE',
                                   V_LOGID,
                                   SYSDATE,
                                   'A',
                                   P_USER_ID,
                                   SYSDATE);

                           V_RESULTADO := 'OK';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              V_RESULTADO :=
                                    'ERROR AL INSERTAR EN ED_DET_DOCUMENTOS_CLIENTES: '
                                 || V_NRO_DOCUMENT;
                        END;
                     END LOOP;
                  ELSE
                     V_RESULTADO :=
                           'ERROR AL INSERTAR CLIENTE PROVISORIO: '
                        || P_NRO_CLIENTE;
                  END IF;
               ELSE
                  V_RESULTADO := 'EL CLIENTE NO EXISTE EN NEXUS';
               END IF;
            END IF;
         END IF;
      ELSE
         V_RESULTADO := 'El cliente ya esta relacionado al documento';
      END IF;

      COMMIT;
      P_RESULTADO := V_RESULTADO;
   END;

   PROCEDURE ACTUALIZA_DOCUMENTO (P_ID_DOCUMENTO   IN     NUMBER,
                                  P_ZONA           IN     VARCHAR2,
                                  P_REGION         IN     NUMBER,
                                  P_USUARIO        IN     VARCHAR2,
                                  P_RESULTADO         OUT NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;

      logid   NUMBER;
   BEGIN
      UPDATE GELEC.ED_DOCUMENTOS d
         SET d.ZONA = P_ZONA, d.REGION = P_REGION
       WHERE d.ID_DOCUMENTO = P_ID_DOCUMENTO;

      logid :=
         GELEC.INSERT_LOG (
               'Modifica region-zona: '
            || P_ZONA
            || ' '
            || P_REGION
            || ' en el doc: '
            || P_ID_DOCUMENTO,
            P_USUARIO);

      COMMIT;

      P_RESULTADO := 1;
   END;

    PROCEDURE INSERTA_TELEFONO (
                              P_DETALLE       IN  VARCHAR2,
                              P_USUARIO       IN  VARCHAR2,
                              P_CUENTA        IN  VARCHAR2,
                              P_NOMBRE        IN  VARCHAR2,
                              P_TELEFONO      IN  VARCHAR2,
                              P_TIPO_CONTACTO IN  VARCHAR2,
                              P_RESULTADO     OUT NUMBER)
    IS PRAGMA AUTONOMOUS_TRANSACTION;

        V_LOGID         NUMBER;
        V_ID_CONTACTO   NUMBER;

    BEGIN
        --01/09/2022 RSLEIVA se creo este proceso para unificar las inserciones de telefonos

--        V_DETALLE := 'DA DE ALTA EL CONTACTO DE UNA CUENTA';
        V_LOGID := GELEC.INSERT_LOG (P_DETALLE, P_USUARIO);
        V_ID_CONTACTO := GELEC.SEQ_CONTACTO_CLIENTE.NEXTVAL ();

        INSERT INTO GELEC.ED_CONTACTOS_CLIENTES (ID_TEL,
                                                 CUENTA,
                                                 NOMBRE,
                                                 TELEFONO,
                                                 TIPO_CONTACTO,
                                                 FECHA_BAJA,
                                                 LOG_DESDE)
             VALUES (V_ID_CONTACTO,
                     P_CUENTA,
                     P_NOMBRE,
                     P_TELEFONO,
                     P_TIPO_CONTACTO,
                     NULL,
                     V_LOGID);

            P_RESULTADO:=1;
            COMMIT;

    END;


END PKG_OTROS;
/


