CREATE OR REPLACE PACKAGE BODY NEXUS_GIS.INTERFAZ_CLIENTES IS
--------------------------------------------------
-- CONSTANTES
--------------------------------------------------
-- flag para habilitar la escritura de mensajes de debug
   p_debug_mode                 BOOLEAN       := FALSE;
   -- No se puede procesar novedades sin antes ejecutar el clientinterface.exe
   k_error_falta_ejecutar_exe   NUMBER        := -1;
   -- Literal que indica que un campo no se ha modificado.
   -- Configurar sprgSysvars 1197 para que el EXE lo interprete como tal
   k_no_cambio                  VARCHAR2 (10) := '[N/C]';
--------------------------------------------------
-- VARIABLES GLOBALES
--------------------------------------------------
   v_clientinterfaceid          NUMBER (10);
   -- proximo ID para tabla sprClientInterface
--------------------------------------------------
-- SUBRUTINAS AUXILIARES
--------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   -- Imprime en el DBMB_OUTPUT los mensajes de logs asociados
   -- a un numero de proceso en particular
   PROCEDURE imprime_logs_en_dbms_output (v_proc NUMBER)  IS
      CURSOR cur_logs IS
           SELECT paso, mensaje
             FROM nexus_gis.fdl_dblog
            WHERE nroproceso = v_proc
         ORDER BY nrosecu;
   BEGIN
      FOR c_log IN cur_logs LOOP
         DBMS_OUTPUT.put_line (c_log.paso || ' -- ' || c_log.mensaje);
      END LOOP;
   END;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   -- imprime en el dbms_output el mensaje acompa?ado de la fecha/hora actual
   -- Se habilita o deshabilita mediante la variable v_debug_mode
   PROCEDURE printdebug (msg VARCHAR2) IS
   BEGIN
      IF p_debug_mode THEN
         DBMS_OUTPUT.put_line ( SUBSTR (CURRENT_TIMESTAMP, 11, 15) || ' -> '|| msg);
      END IF;
   END;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- verifica si un cliente es medido o no a partir de su grupo tarifario
   FUNCTION es_medido (p_cod VARCHAR2)  RETURN VARCHAR2 IS
      v_return_val   VARCHAR2 (2);
   BEGIN
      printdebug ('cliente medido');
      v_return_val := 'S';

      IF TRIM (p_cod) IN ('ENMT','ENMAP') THEN
        v_return_val := 'N';
      END IF;

      RETURN v_return_val;
   END es_medido;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   -- obtiene el nivel de sensibilidad (alto, medio, bajo, S/D) a partir del dato CLIENTE_SENSIBLE
   FUNCTION nivel_sensibilidad (p_sensibilidad VARCHAR2)  RETURN NUMBER IS
      v_aux_fscode   VARCHAR (20);
      v_aux_code     NUMBER (10);
   BEGIN
      printdebug ('nivel de sensibilidad');
      -- solo se admiten tres niveles de sensibilidad, caso contrario se maneja como sin dato
      IF (SUBSTR (p_sensibilidad, 1, 1) IN ('1', '2', '3')) THEN
         v_aux_fscode := SUBSTR (p_sensibilidad, 1, 1);
      ELSE
         v_aux_fscode := 'S/D';
      END IF;

      SELECT codeid
        INTO v_aux_code
        FROM nexus_gis.sprgcodes
       WHERE codetypeid = 210 AND fscode = v_aux_fscode AND logidto = 0;

      RETURN v_aux_code;
   EXCEPTION
      WHEN OTHERS
      THEN
        RETURN NULL;
   END nivel_sensibilidad;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- obtiene la actividad (desde el punto de vista de la sensibilidad) a partir del dato CLIENTE_SENSIBLE
   FUNCTION actividad_sensibilidad (p_sensibilidad VARCHAR2)  RETURN NUMBER IS
      v_aux_code   NUMBER (10);
   BEGIN
      printdebug ('actividad sensibilidad');

      SELECT codeid
        INTO v_aux_code
        FROM nexus_gis.sprgcodes
       WHERE codetypeid = 211 AND fscode = TRIM (p_sensibilidad)
             AND logidto = 0;

      RETURN v_aux_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         SELECT codeid
           INTO v_aux_code
           FROM nexus_gis.sprgcodes
          WHERE codetypeid = 211 AND fscode = 'S/D' AND logidto = 0;

         RETURN v_aux_code;
   END actividad_sensibilidad;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   -- recibe como entrada un string y devuelve numero (elimina caracteres que no sean numericos)
   FUNCTION solo_numeros (p_texto IN VARCHAR2)  RETURN NUMBER IS
      v_texto      VARCHAR2 (255);
      v_textook    VARCHAR2 (255);
      v_numero     NUMBER;
      v_caracter   VARCHAR2 (1)   := ' ';
      v_largo      INTEGER;
      v_actual     INTEGER        := 0;
   BEGIN
      IF (LENGTH (TRIM (p_texto)) = 0 OR LENGTH (TRIM (p_texto)) IS NULL) THEN
         RETURN 0;
      ELSE
         v_texto := TRIM (p_texto);
         v_largo := LENGTH (v_texto);
         FOR v_actual IN 1 .. (v_largo)  LOOP
            v_caracter := SUBSTR (v_texto, v_actual, 1);
            IF v_caracter IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') THEN
               v_textook := v_textook || v_caracter;
            END IF;
         END LOOP;
         v_numero := NVL (TO_NUMBER (v_textook), 0);
         RETURN v_numero;
      END IF;
   END solo_numeros;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- determina si un cliente tiene o no medidor prepago
   FUNCTION es_prepago (p_cod VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      printdebug ('cliente prepago');
      IF ( upper(p_cod) = 'PREPAGO' )  THEN
         RETURN '1';
      ELSE
         RETURN '0';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'ERROR';
   END es_prepago;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   FUNCTION verificar_tarifa_valida (
      p_objectid   nexus_gis.sprobjects.objectid%TYPE,
      p_linkid     nexus_gis.links.linkid%TYPE,
      p_client     nexus_gis.sprclients.fsclientid%TYPE
   ) RETURN VARCHAR2 IS
      v_ret      VARCHAR2 (255);
      v_error    VARCHAR2 (255);
      v_tarifa   VARCHAR2 (255);
      v_sprid    VARCHAR2 (255);
   BEGIN
      printdebug ('verificar tarifa');

      SELECT tar.fscode, b.sprid
        INTO v_tarifa, v_sprid
        FROM nexus_gis.sprobjects b, nexus_gis.sprlinks a, nexus_gis.sprclients c, nexus_gis.sprgcodes tar
       WHERE c.fsclientid = p_client
         AND c.logidto = 0
         AND c.faretypecodeid = tar.codeid
         AND tar.codetypeid = 23
         AND a.linkvalue = RPAD (p_client, 30)
         AND a.logidto = 0
         AND a.linkid = 407
         AND b.objectid = a.objectid
         AND b.logidto = 0;

      SELECT DECODE (COUNT (cis.sprid),
                     1, 'ok',
                     0, 'Error: el tipo de red del suministro no corresponde con la tarifa de la cuenta'
                    )
        INTO v_ret
        FROM nexus_gis.cis_tarifa_suministro cis
       WHERE cis.sprid = v_sprid AND cis.tarifa = v_tarifa;

      RETURN v_ret;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 'Cliente Inexistente (' || p_client || ')';
      WHEN TOO_MANY_ROWS
      THEN
         RETURN 'Cliente Duplicado (' || p_client || ')';
      WHEN OTHERS
      THEN
         v_error := 'SQL:' || SUBSTR (SQLERRM, 0, 200);
         RETURN 'Error Generico:' || v_error;
   END verificar_tarifa_valida;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- Inserta registro en sprClientInterface. Retorna True si la insercion fue exitosa
   PROCEDURE insertar_sprclientinterface ( p_cli   IN OUT   sprclientinterface%ROWTYPE ) IS
   BEGIN
      printdebug ('inserta registro en sprClientInterface');
      -- obtiene el siguiente secuencial disponible
      IF (v_clientinterfaceid IS NULL)  THEN
         SELECT NVL (MAX (clientinterfaceid) + 1, 0)
           INTO v_clientinterfaceid
           FROM nexus_gis.sprclientinterface;
      ELSE
         v_clientinterfaceid := v_clientinterfaceid + 1;
      END IF;
      p_cli.clientinterfaceid := v_clientinterfaceid;

      INSERT INTO nexus_gis.sprclientinterface VALUES p_cli;
      COMMIT;

   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END insertar_sprclientinterface;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    --obtener informacion referente al area del cliente
   PROCEDURE obtener_info_area (
      p_streetid         IN       NUMBER,
      p_fsareatypecode   OUT      VARCHAR2,
      p_fsareacode       OUT      VARCHAR2
   ) IS
   BEGIN
      printdebug ('info de area del cliente');
      IF (p_streetid IS NOT NULL) THEN
         BEGIN
            SELECT aa.fsareacode, aat.fsareatypecode
              INTO p_fsareacode, p_fsareatypecode
              FROM nexus_gis.amareas aa, nexus_gis.amareatypes aat
             WHERE aa.areatypeid = aat.areatypeid
               AND aa.areaid =(SELECT regionid
                                 FROM nexus_gis.smstreets
                                WHERE streetid = p_streetid AND streetantiq = 0);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_fsareatypecode := NULL;
               p_fsareacode := NULL;
         END;
      END IF;
   END obtener_info_area;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- completa los campos FS (foreign System) del maestro de areas
   -- para que sean compatibles con la interfase de clientes
   PROCEDURE actualiza_codigos_fs_areas IS
   BEGIN
      printdebug ('actualiza campos fsareacode y fsareatypecode');

      UPDATE nexus_gis.amareas
         SET fsareacode = TO_CHAR (areaid)
       WHERE areatypeid = 10                  -- localidades
         AND (fsareacode IS NULL OR fsareacode <> TO_CHAR (areaid));

      UPDATE nexus_gis.amareatypes
         SET fsareatypecode = TO_CHAR (areatypeid)
       WHERE fsareatypecode IS NULL OR fsareatypecode <> TO_CHAR (areatypeid);

      COMMIT;
   END;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   -- agrega registros en sprgCodes a partir de los valores existentes en sprClientInterface
   -- parametros
   -- p_campo: campo de la tabla sprClientInterface a analizar
   -- p_codetypeid: codeTypeId asociado (tabla sprgCodes)
   PROCEDURE sprgcodes_clientinterface (
      p_campo        IN   VARCHAR2,
      p_codetypeid   IN   NUMBER
   ) IS
      TYPE t_cursor IS REF CURSOR;

      v_cursor      t_cursor;
      v_sql         VARCHAR2 (1000);
      v_maxcodeid   NUMBER;
      v_fscode      nexus_gis.sprgcodes.fscode%TYPE;
   BEGIN
      -- se tienen en cuenta solamente las novedades pendientes de procesar
      v_sql :='SELECT '
         || p_campo
         || ' FROM sprclientinterface WHERE processlogid = 0 '
         || ' MINUS SELECT fscode FROM sprgcodes WHERE codetypeid = '
         || p_codetypeid;

      OPEN v_cursor FOR v_sql;

      LOOP
         FETCH v_cursor
          INTO v_fscode;

         EXIT WHEN v_cursor%NOTFOUND;

         IF TRIM (v_fscode) IS NOT NULL
         THEN
            SELECT MAX (codeid) + 1
              INTO v_maxcodeid
              FROM nexus_gis.sprgcodes;

            INSERT INTO nexus_gis.sprgcodes
                        (codeid, codetypeid, codeshortname, codename,
                         fscode, logidfrom, logidto
                        )
                 VALUES (v_maxcodeid, p_codetypeid, 'AC', 'A Completar',
                        v_fscode, 1, 0
                        );

            COMMIT;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END sprgcodes_clientinterface;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- completa la tabla sprgCodes con los codigos necesarios para
   -- procesar la tabla sprClientInterface
   PROCEDURE completar_sprgcodes
   IS
   BEGIN
      sprgcodes_clientinterface ('fsUrbanDensityCode', 18);
      sprgcodes_clientinterface ('fsActivityCode', 19);
      sprgcodes_clientinterface ('fsClientTypeCode', 20);
      sprgcodes_clientinterface ('fsClientStateCode', 21);
      sprgcodes_clientinterface ('fsAgencyCode', 22);
      sprgcodes_clientinterface ('fsFareTypeCode', 23);
      sprgcodes_clientinterface ('fsIdCardNTypeCode', 24);
      sprgcodes_clientinterface ('fsTechAreaCode', 25);
      sprgcodes_clientinterface ('fsCntrctStateCode', 26);
      sprgcodes_clientinterface ('fsMeterBrandCode', 31);
   END completar_sprgcodes;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- Cambios de potencia que implican un nuevo numero de cuenta:
   -- Si la novedad es tipo Alta y ya existe una cuenta Activa y Vinculada con
   -- el mismo IDServicio, se Vincula la cuenta nueva al suministro existente
   FUNCTION verificar_cambio_potencia (
      p_clientid     VARCHAR2,
      p_idservicio   VARCHAR2,
      p_fecha_alta   DATE,
      p_userid       NUMBER
   ) RETURN BOOLEAN IS
      v_clientid_actual       nexus_gis.sprclients.fsclientid%TYPE;
      v_objectid              nexus_gis.sprobjects.objectid%TYPE;
      v_fecha_alta_atributo   nexus_gis.sprlinks.datefrom%TYPE;
      v_logid                 nexus_gis.sprlog.logid%TYPE;
      v_out                   boolean := FALSE;
   BEGIN
      -- verifica si ya existe una cuenta activa con el mismo IDServicio
      SELECT fsclientid
        INTO v_clientid_actual
        FROM nexus_gis.sprclients
       WHERE custatt1 = p_idservicio AND logidto = 0;                -- Activo

      -- verifica si la cuenta esta vinculada a un suministro
      SELECT objectid
        INTO v_objectid
        FROM nexus_gis.sprlinks
       WHERE linkid = 407
         AND logidto = 0
         AND linkvalue = RPAD (v_clientid_actual, 30);

      -- fecha de alta del objeto suministro
      SELECT datefrom
        INTO v_fecha_alta_atributo
        FROM nexus_gis.sprobjects
       WHERE objectid = v_objectid AND logidto = 0;

      -- la fecha de alta del atributo no puede ser anterior a la del suministro
      IF v_fecha_alta_atributo < p_fecha_alta
      THEN
         v_fecha_alta_atributo := p_fecha_alta;
      END IF;

      -- si llego hasta aca es porque se debe vincular la nueva cuenta al suministro existente
      -- es decir hay que insertar un nuevo atributo en sprLinks

      -- registro en sprLog para identificar la modificacion al modelo
      v_logid := nexus_gis.network_updater.sequencer (nexus_gis.model_constants.sequence_name_sprlog, 1);
      nexus_gis.network_updater.revision_create
           (v_logid,
            SYSDATE,
            p_userid,
            'Interfaz Clientes: Vinculacion automatica por cambio de potencia'
           );
      COMMIT;
      nexus_gis.network_updater.add_link (v_objectid,
                                407,
                                p_clientid,
                                v_logid,
                                nexus_gis.model_constants.object_type_sprsymbol
                               );
      -- finaliza la transaccion "Larga"
      nexus_gis.network_updater.revision_close (v_logid);
      COMMIT;
      v_out := TRUE;
      return (v_out);

   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS
      THEN
         --NULL;                                    -- no vincula el suministro
         nexus_gis.network_updater.revision_cancel (v_logid);
         return (v_out);
      WHEN OTHERS
      THEN
         nexus_gis.network_updater.revision_cancel (v_logid);
         return (v_out);
         RAISE;
   END verificar_cambio_potencia;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- Recorre las novedades de UTC_Novedades y las pasa como novedades (Alta, Baja y Modificaciones)
   -- a la tabla estandar sprClientInterface
   PROCEDURE procesar_novedades_utc (
      p_cant_novedades_error   OUT      NUMBER,
      p_userid                 IN       NUMBER,
      p_nroproceso             IN       fdl_dblog.nroproceso%TYPE
   ) IS
      -- cursor principal para recorrer las novedades de clientes (UTC_Novedades)
      -- se agrupa cuenta porque una cuenta puede tener varias novedades en el dia
      CURSOR c_nov IS
           SELECT distinct(ident) ident
             FROM utc.utc_novedades
            WHERE logid = 0 AND ident IS NOT NULL
         ORDER BY ident;

      -- cursor para traer los datos de los clientes
      CURSOR c_clientes (p_ident VARCHAR2) IS
        SELECT TARI_ID,CICL_ID,RUTA_ID,CLIE_APYNOM,CLIE_POT_CONV_PTA,CLIE_POT_CONV_FPTA,
               TMED_ID,CLIE_MEDIDOR_NUM,CLIE_CALLE_NUM,ACTI_ID,CLIE_TELEFONO,CLIE_COMERCIAL_ALTA,
               CLIE_COMERCIAL_BAJA,CLIE_DOMICILIO_PISO,CLIE_DOMICILIO_DEPTO,CLIE_LOCALIDAD,
               ACU_SRV_ESTADO,CLIE_POSTAL_COD,TDOC_ID,CLIE_DOCUM_NUM,OFCO_ID,TENS_ID,CLIE_GESTOR_NOMBRE,
               CLIE_GESTOR_TELEFONO,CLIE_TRATO_ESPECIAL,CLIE_NEXUS_ID,TARIFA_ENRE,CLIE_FASES,CUENTA_BIG,
               CLIE_ENTRE_CALLE1,CLIE_ENTRE_CALLE2,TIAS_ID
           FROM UTC.CLIENTES
          WHERE CLIE_ID = P_IDENT;

      -- tabla de NNSS TCA
      CURSOR c_tca_bgns4dl (p_id_servicio NUMBER) IS
         SELECT *
           FROM nexus_gis.tca_bgns4dl
          WHERE id_servicio = p_id_servicio
            AND (cod_est IS NULL OR cod_est NOT IN ('AN', 'DE'));


      -- para almacenar el dato de UTC_CA_MEDIDORES.C_MEDIDOR
      --v_c_medidor           NUMBER (3);
      -- record para insertar el registro en sprclientinterface
      v_client              nexus_gis.sprclientinterface%ROWTYPE;
      -- record para valores de tca_bgns4dl y tca_address_exchange4dl
      v_tca_4dl             nexus_gis.tca_bgns4dl%ROWTYPE;
      v_clientid            VARCHAR2 (30);     -- numero de cuenta del cliente
      v_existe_sprcli       BOOLEAN;           -- existe el cliente en sprClients
      v_existe_tca          BOOLEAN;           -- flag existe info de la cuenta en tca_bgns4dl
      v_tipo_novedad        NUMBER (10);
      v_codigo_error        NUMBER (10);
      v_logid               NUMBER (10);
      v_actualizacion_geo   NUMBER;
      v_valida                NUMBER;   --0: no requiere, 1: alta de link, 2: baja de link
      v_calle               VARCHAR2 (50);      --??
      v_calle1              VARCHAR2 (50):= null;
      v_calle2              VARCHAR2 (50):= null;
      localidad             VARCHAR2 (150);
      v_streetid            NUMBER (10);        --??
      v_clientphases        NUMBER(5);
      v_cant_reg            NUMBER;
      v_desc_error          utc.utc_novedades.desc_error%TYPE;
      v_tabla_utc           VARCHAR2 (100);      -- nombre de la tabla UTC a la que se esta accediendo
      v_tp_de_Acuerdo_Serv  VARCHAR2 (100);
      v_dummy               VARCHAR2 (50);
      v_streetother         VARCHAR2 (7);
      p_clientid             VARCHAR2(50);
      v_valor_tens          VARCHAR2(16);
      v_codename            nexus_gis.sprgcodes.fscode%TYPE;
      v_triphasicclient     NEXUS_GIS.SPRCLIENTS.TRIPHASICCLIENT%type;
      v_voltage             NEXUS_GIS.SPRCLIENTS.VOLTAGE%type;

      -- Para validar que las entrecalles existan en el maestro
   BEGIN
      -- cantidad de novedades procesadas con error
      p_cant_novedades_error := 0;
      -- creo un registro en sprLog para identificar todo el proceso
      v_logid := nexus_gis.network_updater.sequencer (nexus_gis.model_constants.sequence_name_sprlog, 1);
      nexus_gis.network_updater.revision_create (v_logid, SYSDATE, p_userid, 'Interfaz Clientes. PL/SQL poblado sprClientInterface' );
      COMMIT;
      printdebug ('Nuevo registro de sprLog: ' || v_logid);

      -- cursor principal, recorre las novedades de UTC_novedades
      FOR v_nov IN c_nov
      LOOP
         BEGIN
            v_clientid := v_nov.ident;
            v_client := NULL;
            v_streetother := NULL;
            -- inicializa record para el insert de sprClientInterface
            v_desc_error := NULL;
            -- inicializa mensaje de error para utc_novedades.desc_error
            printdebug ('*** Cuenta: ' || v_clientid || ' ***');
            -- determina si la cuenta existe en sprClients
            SELECT COUNT (*)
              INTO v_cant_reg
              FROM nexus_gis.sprclients
             WHERE fsclientid = v_clientid;

            v_existe_sprcli := (v_cant_reg > 0);

            IF v_existe_sprcli THEN
               printdebug ('SI existe en sprClients');
            ELSE
               printdebug ('NO existe en sprClients');
            END IF;

            -- codigo de error de la novedad, 0: OK
            v_codigo_error := 0;

            FOR v_utc_clientes IN c_clientes (v_nov.ident)  LOOP
              printdebug ('Cliente CC and B');
              -- chequear si los valores obligatorios de entrada son correctos
              -- caso contrario invalidar la novedad
              IF (v_utc_clientes.clie_comercial_alta IS NULL)  THEN
                 v_codigo_error := v_codigo_error + 10;
              END IF;


              IF (TRIM (v_utc_clientes.tarifa_enre) IS NULL) THEN
                 v_codigo_error := v_codigo_error + 1000;
              END IF;

              IF (TRIM (v_utc_clientes.acu_srv_estado) IS NULL) THEN
                 v_codigo_error := v_codigo_error + 10000000;
              END IF;

              -- bloque para obtener valores de tablas UTC adicionales
              BEGIN
                -- obtener informacion de UTC  ciclos
                v_tabla_utc := 'CICLOS';
                SELECT cicl_cod
                  INTO v_client.custatt6
                  FROM utc.ciclos
                 WHERE ID = v_utc_clientes.cicl_id;

                -- obtener numero de Ruta
                v_tabla_utc := 'RUTAS';
                SELECT ruta_cod
                  INTO v_client.custatt7
                  FROM utc.rutas
                 WHERE ID = v_utc_clientes.ruta_id;

                -- obtener informacion de grupos tarifarios
                v_tabla_utc := 'ESTRUC_TARIFARIA';
                SELECT tari_cod
                  INTO v_client.custatt18
                  FROM utc.estruc_tarifaria
                 WHERE ID = v_utc_clientes.tari_id;

                --obtener informacion de marca y modelo de medidor
                IF (v_utc_clientes.tmed_id IS NULL) THEN
                    v_client.fsmeterbrandcode := 'S/D';
                    v_client.custatt25 := 'S/D';
                ELSE
                    v_tabla_utc := 'TIPOS_MEDIDOR';
                    SELECT fabricante,
                           modelo--,tipo_medidor
                      INTO v_client.fsmeterbrandcode,
                           v_client.custatt25--, v_c_medidor
                      FROM utc.tipos_medidor
                     WHERE ID = v_utc_clientes.tmed_id;

					if v_client.fsmeterbrandcode is null then
						v_client.fsmeterbrandcode:= 'S/D';
					end if;
                END IF;

                --obtener el tipo de documento cliente
                IF (v_utc_clientes.tdoc_id IS NULL) THEN
                    v_client.fsidcardntypecode := 'S/D';
                ELSE
                    v_tabla_utc := 'TIPOS_DOCUM';
                    SELECT NVL (trim(TDOC_COD), 'DNI')
                      INTO v_client.fsidcardntypecode
                      FROM utc.tipos_docum
                     WHERE ID = v_utc_clientes.tdoc_id;
                END IF;

                --obtener la actividad
                v_tabla_utc := 'ACTIVIDADES';
                SELECT NVL (trim(ACTI_COD), 'S/D')
                  INTO v_client.fsactivitycode
                  FROM utc.actividades
                 WHERE ID = v_utc_clientes.acti_id;

                --obtenerla oficina comercial
                IF (v_utc_clientes.ofco_id IS NULL) THEN
                    v_client.fsagencycode := 'S/D';
                ELSE
                    v_tabla_utc := 'OFICINAS_COM';
                    SELECT NVL (trim(OFCO_COD), 'S/D')
                      INTO v_client.fsagencycode
                      FROM utc.oficinas_com
                     WHERE ID = v_utc_clientes.ofco_id;
                END IF;

                --obtener el tipo de documento cliente
                IF (v_utc_clientes.tens_id IS NULL) THEN
                    v_client.voltage := 0;
                ELSE
                    v_tabla_utc := 'TENSIONES';
                    SELECT NVL(trim(TENS_COD), '0')
                      INTO v_valor_tens  --v_client.voltage
                      FROM utc.tensiones
                     WHERE ID = v_utc_clientes.tens_id;

                     IF v_valor_tens = 'S/C' OR  v_valor_tens = 'SC' THEN
                        v_client.voltage:=0;
                     ELSE
                        v_client.voltage:= TO_NUMBER(v_valor_tens);
                     END IF;

                END IF;

                --obtener el tipo de Acuerdo de servicio (prepago no medido, etc)
                IF (v_utc_clientes.tias_id IS NULL) THEN
                    v_tp_de_Acuerdo_Serv := 'S/D';
                ELSE
                    v_tabla_utc := 'TIPO_AS';
                    SELECT NVL(trim(TIPO_AS), 'S/D')
                      INTO v_tp_de_Acuerdo_Serv
                      FROM utc.tipo_as
                     WHERE ID = v_utc_clientes.tias_id;
                END IF;

                printdebug ('datos tablas auxiliares UTC OK');
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    v_codigo_error := v_codigo_error + 20;
                    v_desc_error := 'Error al acceder a tabla: ' || v_tabla_utc;
                    printdebug ('Error en UTC: ' || SQLERRM);
              END;

              -- si no hay errores de entrada entonces continuar
              IF v_codigo_error = 0 THEN
                 -- determina el tipo de novedad (Alta, Modificacion, Baja, Alta+Baja)
                 IF (v_utc_clientes.clie_comercial_baja IS NULL) THEN
                    IF v_existe_sprcli THEN
                       v_tipo_novedad := 2;               -- modificacion
                    ELSE
                       v_tipo_novedad := 1;               -- alta
                    END IF;
                 ELSE
                    IF v_existe_sprcli THEN
                       v_tipo_novedad := 3;                -- baja
                    ELSE
                       v_tipo_novedad := 4;                -- alta+baja
                    END IF;
                 END IF;
                 printdebug ('Tipo de Novedad: ' || v_tipo_novedad);
                 -- inicializa
                 v_existe_tca := FALSE;
                 -- flag existe info de la cuenta en tca_bgns4dl o tca_address_exchange4dl
                 v_tca_4dl := NULL;
                 v_actualizacion_geo := 5;
                 -- info de tca_bgns4dl para el id_sevicio del cliente
                 FOR v_bgns4dl IN c_tca_bgns4dl (v_utc_clientes.clie_nexus_id) LOOP
                     v_existe_tca := TRUE;
                     v_tca_4dl := v_bgns4dl;
                 END LOOP;
                 v_streetid := v_tca_4dl.calle_id;
                 -- se utiliza para actualizar utc_novedades
                 v_client.clientid := v_clientid;
                 v_client.surname1 := SUBSTR (v_utc_clientes.clie_apynom, 1, 20);
                 v_client.surname2 := NULL;
                 v_client.name := NULL;
                 v_client.fullname := v_utc_clientes.clie_apynom;
				 BEGIN
					--NECOPER-364
					--RSLEIVA 20/09/2023
					--Se agrega en estructura begin para capturar error y que no rompa el circuito
					v_client.telephonenumber := v_utc_clientes.clie_telefono;
				 EXCEPTION	
					WHEN OTHERS THEN
						DBMS_OUTPUT.PUT_LINE('Error en telefono: '|| v_utc_clientes.clie_telefono);
						v_client.telephonenumber:= SUBSTR(trim(v_client.telephonenumber),20);
				 END;
                 -- completa informacion de calles
                 v_client.streetid := NVL (v_tca_4dl.calle_id, 0);
                 v_client.streetid1 := NVL (v_tca_4dl.entre_calle_1, 0);
                 v_client.streetid2 := NVL (v_tca_4dl.entre_calle_2, 0);
                 -- obtener informacion referente al area del cliente, siempre y cuando la novedad
                 -- sea del tipo "Alta" o "Cambio de domicilio"
                 IF v_existe_tca THEN
                    obtener_info_area (v_client.streetid,
                                       v_client.fsareatypecode,
                                       v_client.fsareacode);
                 ELSE
                    -- evita novedades de alta que no fueron procesados por TCA
                    IF (v_tipo_novedad IN (1, 4)) THEN
                       v_codigo_error := 5;
                    END IF;
                 END IF;
                 v_client.fsstreetcode := NULL;
                 v_client.fsstreetcode1 := NULL;
                 v_client.fsstreetcode2 := NULL;
                 v_client.streetnumber := solo_numeros(v_tca_4dl.nro_cons);

                 --Construye el streetother manteniendo el len del piso_con y Dpto_cons
                BEGIN
                    SELECT DECODE(LENGTH(bg.piso_cons),NULL,bg.piso_cons||'   ',1,bg.piso_cons||'  ',2, bg.piso_cons||' ', 3, bg.piso_cons)||
                           DECODE(LENGTH(bg.dpto_cons),NULL,bg.dpto_cons||'    ',1,bg.dpto_cons||'   ',2, bg.dpto_cons||'  ', 3,bg.dpto_cons||' ', bg.dpto_cons)
                      INTO v_streetother
                      FROM nexus_gis.tca_bgns4dl bg
                     WHERE bg.id_servicio = v_tca_4dl.id_servicio;

                    printdebug ('Concatenacion streetoher OK');
                EXCEPTION
                 WHEN OTHERS
                 THEN
                    v_codigo_error :=  v_codigo_error + 100;
                    --printdebug ('Error Concatenacion streetoher: ' || SQLERRM);
                    v_desc_error := 'Error Streetoher -> Id_Servicio marcado como Borrado o Anulado';
                END;
                 v_client.streetother := v_streetother;
                 v_client.zipcode := v_utc_clientes.clie_postal_cod;
                 v_client.duplicateaddress := NULL;
                 -- armar fulladdress, solo en novedades Alta y Cambio de Domicilio
                 IF v_existe_tca THEN
                    BEGIN
                       SELECT streetname
                         INTO v_calle
                         FROM nexus_gis.smstreets
                        WHERE streetid = v_client.streetid
                          AND streetantiq = 0;
                    EXCEPTION
                       WHEN OTHERS THEN
                          v_codigo_error :=  v_codigo_error + k_error_calleinvalida;
                    END;
                    v_client.fulladdress :=  v_calle
                       || ' ' || v_client.streetnumber
                       || ' ' || v_client.streetother;
                 ELSE
                    v_client.fulladdress := k_no_cambio;   -- sin cambios
                 END IF;
                v_client.fstechareacode := 'S/D';
                 v_client.fsurbandensitycode := 'S/D';
                 v_client.fsclienttypecode := 'S/D';
                 v_client.fsclientstatecode := v_utc_clientes.acu_srv_estado;

                --obtengo el ultimo estado del  campo, para identificar si tiene corte por morosidad
                 BEGIN
                    select sprc.fscode
                      into v_codename
                      from NEXUS_GIS.SPRCLIENTS spr,
                           NEXUS_GIS.SPRGCODES sprc
                     where sprc.codeid= spr.cntrctstatecodeid
                       and spr.fsclientid = v_clientid;

                 EXCEPTION
                       WHEN OTHERS THEN
                          v_codename :=  'N    ';
                    END;

                 --v_client.fscntrctstatecode := 'S/D';
                 v_client.fscntrctstatecode := v_codename;
                 v_client.fsfaretypecode := NVL (v_utc_clientes.tarifa_enre, 'S/D');
                 v_client.installedpower := v_utc_clientes.clie_pot_conv_pta;
                 v_client.triphasicclient := NVL (solo_numeros(v_utc_clientes.clie_fases), 1);


                 --proceso que trae el valor de voltage y cantidad de fasses
                 BEGIN
                    SELECT triphasicclient,voltage, CLIENTPHASES
                      INTO v_triphasicclient, v_voltage, v_clientphases
                      FROM NEXUS_GIS.SPRCLIENTS SPR
                     WHERE SPR.fsclientid = v_clientid;

                 EXCEPTION
                 WHEN OTHERS
                 THEN
                    v_triphasicclient:= 1;
                    v_voltage :=220;
                    v_clientphases:= 0;

                END;

                --valido si ha cambiado el voltage o la cantidad de fases para asignar valor al campo CLIENTPHASES
                --Proceso para actualizar de la tabla sprclients el valor de la fase para la novedad a procesar
                if ((v_triphasicclient != v_client.triphasicclient) or (v_voltage != v_client.voltage)) then
                    v_clientphases:= 0;
                end if;

                 v_client.clientphases := v_clientphases;
                 v_client.meterid := v_utc_clientes.clie_medidor_num;
                 v_client.meterscalefactor := 1;
                 v_client.clientid1 := NULL;
                 v_client.clientid2 := NULL;
                 v_client.custatt1 := v_utc_clientes.clie_nexus_id;
                 v_client.custatt2 := v_tca_4dl.id_suministro;
                 v_client.datefrom := v_utc_clientes.clie_comercial_alta;
                 v_client.dateto := v_utc_clientes.clie_comercial_baja;
                 v_client.processtype := v_tipo_novedad;
                 v_client.processstatus := 0;
                 v_client.processlogid := 0;
                 v_client.custatt3 := v_tca_4dl.pedido_cliente;
                 v_client.custatt4 := v_utc_clientes.clie_pot_conv_fpta;
                 v_client.custatt5 := v_client.custatt7;
                 v_client.custatt8 := NULL;
                 v_client.custatt9 := NULL;
                 v_client.custatt10 := NULL;
                 v_client.custatt11 := NULL;
                 v_client.custatt11 :=    es_prepago (v_tp_de_Acuerdo_Serv);
                 IF (v_client.custatt11 = 'ERROR') THEN
                     v_codigo_error := v_codigo_error + 200;
                 END IF;
                 v_client.custatt12 := v_utc_clientes.clie_gestor_nombre;
                 v_client.custatt13 := v_utc_clientes.clie_gestor_telefono;
                 v_client.custatt14 := NVL (v_tca_4dl.a_revisar, 'N');
                 v_client.custatt15 := NVL (v_tca_4dl.revisado, 'N');
                 v_client.custatt16 := v_utc_clientes.clie_trato_especial;
                 v_client.custatt17 := NULL;                    -- vacante
                 v_client.custatt19 := v_tca_4dl.tipo_conex;
                 v_client.custatt20 := TO_CHAR (nivel_sensibilidad (v_client.custatt16));
                 v_client.custatt21 := TO_CHAR (actividad_sensibilidad (v_client.custatt16));
                 v_client.custatt22 := es_medido (v_tp_de_Acuerdo_Serv);
                 v_client.custatt23 := NULL;
                 -- armo el campo de direccion no normalizada, segun UTC
                 -- armar custatt24, solo en novedades Alta y Cambio de Domicilio
                 IF v_existe_tca THEN
                    BEGIN
                      IF v_client.streetid1 <> 0 THEN
                           SELECT streetname
                             INTO v_calle1
                             FROM nexus_gis.smstreets
                            WHERE streetid = v_client.streetid1
                              AND streetantiq = 0;
                      END IF;
                      IF v_client.streetid2 <> 0 THEN
                           SELECT streetname
                             INTO v_calle2
                             FROM nexus_gis.smstreets
                            WHERE streetid = v_client.streetid2
                              AND streetantiq = 0;
                      END IF;

                      SELECT areaname
                        INTO localidad
                        FROM nexus_gis.amareas
                       WHERE areaid = v_client.fsareacode;

                    EXCEPTION
                       WHEN OTHERS THEN
                          v_codigo_error :=  v_codigo_error + k_error_calleinvalida;
                    END;
                    v_client.custatt24 := v_tca_4dl.nro_cons || '|'
                                       || v_calle1 || '|'
                                       || v_calle2 || '|'
                                       || localidad;
                 ELSE
                    v_client.custatt24 := k_no_cambio;   -- sin cambios
                 END IF;

                 v_client.custatt26 := NULL;
                 v_client.custatt27 := NULL;
                 v_client.custatt28 := NULL;
                 v_client.custatt29 := NULL;
                 v_client.custatt30 :=  v_utc_clientes.CUENTA_BIG;

                 IF ((v_tca_4dl.pedido_cliente = 'N') AND (v_tipo_novedad = 1)) THEN
                    v_actualizacion_geo := 1;
                 -- marca los clientes "No a Pedido"
                 ELSE
                    IF (v_tipo_novedad = 3 OR v_tipo_novedad = 4) THEN
                       -- baja
                       v_actualizacion_geo := 2;
                       v_desc_error := 'Desvincula Cliente -> por Fecha de Baja';

                    ELSE
                       v_actualizacion_geo := 0;
                    END IF;
                 END IF;
              END IF;


            END LOOP;

            --ahora intento insertar novedad en sprClientInterface
            BEGIN
               IF (v_codigo_error = 0) THEN
                  printdebug (   'Novedad sin Error, Tipo Novedad: ' || v_tipo_novedad );
                  -- tratamiento de acuerdo al tipo de novedad
                  CASE v_tipo_novedad
                  WHEN 1 THEN -- Alta simple
                        insertar_sprclientinterface (v_client);
                  WHEN 2 THEN -- Modificacion
                        insertar_sprclientinterface (v_client);
                  WHEN 4 THEN -- Alta + Baja
                        v_client.processtype := 1;                    -- alta
                        insertar_sprclientinterface (v_client);
                        v_client.processtype := 3;                    -- baja
                        insertar_sprclientinterface (v_client);
                  WHEN 3 THEN -- Baja: Ademas de la baja se requiere actualizar los ultimos datos del cliente
                        v_client.processtype := 2;                    -- modificacion
                        insertar_sprclientinterface (v_client);
                        v_client.processtype := 3;                    -- baja
                        insertar_sprclientinterface (v_client);
                  END CASE;

                  printdebug ('Actualizando utc_novedades');
                  -- marca la novedad como "procesada"
                  UPDATE UTC.utc_novedades
                     SET logid = v_logid,
                         statusid = v_actualizacion_geo,
                         streetid = v_streetid,
                         desc_error = v_desc_error
                   WHERE ident = v_clientid AND logid = 0;
                  COMMIT;
               -- novedad con error
               ELSE
                  printdebug (   'Novedad con error, codigo de error: ' || v_codigo_error );
                  p_cant_novedades_error := p_cant_novedades_error + 1;
                  UPDATE utc.utc_novedades
                     SET logid = v_logid,
                         statusid = v_codigo_error,
                         streetid = 0,
                         desc_error = v_desc_error
                   WHERE ident = v_clientid AND logid = 0;
                  COMMIT;
               END IF;
            EXCEPTION
               WHEN case_not_found
               THEN
                  v_codigo_error := v_codigo_error + 2000000;
                  UPDATE utc.utc_novedades
                     SET logid = v_logid,
                         statusid = v_codigo_error,
                         streetid = 0,
                        desc_error = v_desc_error
                   WHERE ident = v_clientid AND logid = 0;
                  COMMIT;
               WHEN DUP_VAL_ON_INDEX
               THEN
                  v_codigo_error := v_codigo_error + 2000;
                  UPDATE utc.utc_novedades
                     SET logid = v_logid,
                         statusid = v_codigo_error,
                         streetid = 0,
                         desc_error = v_desc_error
                   WHERE ident = v_clientid AND logid = 0;
                  COMMIT;
               WHEN OTHERS
               THEN
                  v_codigo_error := v_codigo_error + 20000;
                  v_desc_error := SUBSTR ((v_desc_error || ' SQL ERROR: ' || SQLERRM), 1, 500);
                  UPDATE utc.utc_novedades
                     SET logid = v_logid,
                         statusid = v_codigo_error,
                         streetid = 0,
                         desc_error = v_desc_error
                   WHERE ident = v_clientid AND logid = 0;
                  COMMIT;
            END;
         EXCEPTION
            WHEN OTHERS
           THEN
               RAISE;
         END;
      END LOOP;                          -- loop principal sobre utc_novedades
       nexus_gis.network_updater.revision_close (v_logid);
   EXCEPTION
      WHEN OTHERS
      THEN
         nexus_gis.network_updater.revision_cancel (v_logid);
         RAISE;
   END procesar_novedades_utc;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    -- poblado de sprClientInterface a partir de la tabla de novedades UTC_Novedades
   PROCEDURE poblar_clientinterface (
      p_nroproceso   IN       NUMBER,
      p_userid       IN       NUMBER,
      p_retval       IN OUT   NUMBER
   ) IS
      v_cant_sinprocesar   NUMBER (20);
   BEGIN
      printdebug ('Comienzo...');
      -- Condiciona la ejecucion a que no haya registros en sprClientInterface aun sin procesar
      -- Esto es necesario para evitar novedades duplicadas.
      SELECT COUNT (*)
        INTO v_cant_sinprocesar
        FROM nexus_gis.sprclientinterface
       WHERE processlogid = 0;

      IF (v_cant_sinprocesar = 0) THEN
         -- completa los campos FS (foreign System) del maestro de areas
         -- para que sean compatibles con la interfase de clientes
         actualiza_codigos_fs_areas;
         procesar_novedades_utc (p_retval, p_userid, p_nroproceso);
         -- verifica e inserta (si es necesario) registros en sprgCodes
         -- relacionados con los campos mapeados de sprClientInterface
         completar_sprgcodes;
         printdebug ('Verificacion de sprgCodes...');
      ELSE
         -- ERROR: Existen novedades pendientes en sprClientInterface.
         -- Ejecutar la interfaz standard (CLIENTINTERFACE.EXE) y luego reintentar.
         p_retval := k_error_falta_ejecutar_exe;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
       RAISE;                         -- pasa el error a la rutina llamante
   END poblar_clientinterface;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-------------------------------------------------------------------------------------
-- proceso de actualizaciones varias en el GIS.
-- Ver detalles en la declaracion del package
-- Por aquÃ?Â? entran los casos cuando el WS DoEliminarCliente no realizo el proceso online
-- Tener presente que para estos casos no llega mensaje de respuesta a PowerCenter IPC, del proceso desarrollado.

   PROCEDURE actualizacion_grafica ( p_nroproceso   IN NUMBER,
                                     p_userid       IN NUMBER,
                                     p_retval       OUT NUMBER
                                    )
   IS
      v_logid              nexus_gis.sprlog.logid%TYPE;
      v_logid2             nexus_gis.sprlog.logid%TYPE;
      v_idservicio         nexus_gis.sprclients.custatt1%TYPE;
      v_objectid           nexus_gis.sprobjects.objectid%TYPE;
      v_seqorder           nexus_gis.sprlinks.seqorder%TYPE;
      v_cant_sinprocesar   NUMBER (20);
      V_EVENTDATE_LIMIT    DATE;
      v_f_cliente          DATE;
      v_f_suministro       DATE;
      v_f_cuenta           DATE;
      v_f_servicio         DATE;
      v_cant_log           NUMBER (10);
      v_cant_altas         NUMBER (10);
      v_cant_bajas         NUMBER (10);
      v_err_msg            VARCHAR (2000);
      p_clientid           nexus_gis.sprclients.fsclientid%type;
      v_valida               NUMBER (10);

      -- recorre las novedades pendientes de actualizacion geografica con statusid 2(baja)
      CURSOR c_nov
      IS
         SELECT ident, statusid
           FROM utc.utc_novedades
          WHERE statusid = 2 AND logid > 0
       GROUP BY ident, statusid
       ORDER BY ident, statusid;

   BEGIN
      fdl_grabarlog (p_nroproceso,
                     'Interfaz Clientes -> Actualizacion Grafica',
                     'Inicio',
                     TRUE
                    );

      -- Condiciona la ejecucion a que no haya registros en sprClientInterface aun sin procesar
      SELECT COUNT (*)
        INTO v_cant_sinprocesar
        FROM nexus_gis.sprclientinterface
       WHERE processlogid = 0;

      IF (v_cant_sinprocesar > 0) THEN
        fdl_grabarlog(p_nroproceso,
                     'Interfaz Clientes -> Actualizacion Grafica',
                     'No se pudo ejecutar porque existen novedades pendientes en sprClientInterface',
                      TRUE
                      );
        p_retval := -1;
        RETURN; -- sale del proceso sin hacer nada....
      ELSE
        p_retval := 0;
      END IF;

      --defino la cantidad de logid que voy a necesitar
      v_cant_log := 0;
     -- v_cant_altas := 0;
      v_cant_bajas := 0;

      SELECT COUNT (*) AS cantidad
        INTO v_cant_bajas
        FROM (SELECT ident, statusid
                FROM utc.utc_novedades
              WHERE statusid = 2 AND logid > 0
            GROUP BY ident, statusid
            ORDER BY ident, statusid)
        WHERE statusid = 2;

      --Suma la cantidad de Revisiones a utilizar
      v_err_msg := '';
      --v_cant_log := v_cant_altas + v_cant_bajas;
      v_cant_log := v_cant_bajas;
      fdl_grabarlog (p_nroproceso,
                     'Interfaz Clientes -> Actualizacion Grafica',
                        'Revisiones: cantidad('
                     || TO_CHAR (v_cant_log)
                     || ') - rango ('
                     || TO_CHAR (v_logid)
                     || '-'
                     || TO_CHAR (v_logid + v_cant_log)
                     || ')'
                     || '- Cuentas inactivas ('
                     || TO_CHAR (v_cant_bajas)
                     || ')',
                     TRUE
                    );

-----------------------------------------------------------------------------------
-- TASK 1: VINCULACION AUTOMATICA DE CLIENTES "NO A PEDIDO DEL CLIENTE - RECUPERO DE ENERGIA"
-- BAJA LOGICA EN LA VINCULACION DE CUENTAS DADAS DE BAJA EN EL SISTEMA COMERCIAL
----------------------------------------------------------------------------------
      IF v_cant_log > 0 THEN
         v_logid := nexus_gis.network_updater.sequencer (nexus_gis.model_constants.sequence_name_sprlog,
                                               v_cant_log
                                               );
         COMMIT;

         FOR v_nov IN c_nov LOOP

               BEGIN
                  -- obtiene fecha de baja del cliente (informada por el sistema comercial)
                  SELECT logs.eventdate
                    INTO v_f_cliente
                    FROM nexus_gis.sprclients cli, nexus_gis.sprlog logs
                   WHERE cli.logidto = logs.logid
                     AND cli.fsclientid = v_nov.ident;

                  BEGIN
                     -- datos del link nro_cuenta
                     SELECT objectid, seqorder, datefrom
                       INTO v_objectid, v_seqorder, v_f_cuenta
                       FROM nexus_gis.sprlinks
                      WHERE linkid = 407
                        AND linkvalue = RPAD (v_nov.ident, 30)
                        AND logidto = 0;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        -- Busco si hay una cuenta dada de baja...
                        -- Si no la hay, salta por error y la toma la proxima rutina
                        -- Si eixste dada de baja, tengo que hacer el update, pero no dar de baja ningun atributo
                        SELECT -1, seqorder, datefrom
                          INTO v_objectid, v_seqorder, v_f_cuenta
                          FROM nexus_gis.sprlinks
                         WHERE linkid = 407
                           AND linkvalue = RPAD (v_nov.ident, 30)
                           AND ROWNUM < 2;
                  END;

                  -- Si encontre una cuenta dada de baja, no hago nada
                  -- Caso contrario, doy de baja el atributo
                  IF v_objectid <> -1 THEN
                     -- evita inconsistencias con la fecha de alta del atributo nro_cuenta
                    IF (v_f_cliente < v_f_cuenta) THEN
                        v_f_cliente := v_f_cuenta;
                    END IF;

                    BEGIN

                        SELECT TRUNC(MAX(PROCDATETO)+1)
                          INTO V_EVENTDATE_LIMIT
                          FROM NEXUS_GIS.SPRGINTPROCESSES
                         WHERE DELETELOGID = 0
                           AND PROVISIONAL_ANALYSIS = 0 ;

                         IF (V_EVENTDATE_LIMIT > v_f_cliente ) THEN
                            v_f_cliente := V_EVENTDATE_LIMIT;
                         END IF;

                     EXCEPTION WHEN OTHERS
                      THEN
                         fdl_grabarlog
                            (p_nroproceso,
                             'Interfaz Clientes -> Actualizacion Grafica -> Fecha C-Int',
                                'Error: '
                             || SUBSTR (SQLERRM, 0, 200)
                             || ' INFO: logid('
                             || TO_CHAR (v_logid)
                             || ') - ident('
                             || TO_CHAR (v_nov.ident)
                             || ')',
                             TRUE
                            );
                         p_retval := p_retval + 1;          -- contador de errores
                    END;
                     -- ingreso log
                     nexus_gis.network_updater.revision_create
                        (v_logid,
                         v_f_cliente,
                        p_userid,
                         'Interfaz Clientes: Actualizacion Grafica (baja de cuenta)'
                        );
                     v_err_msg :=
                           ' al al dar de baja logica el atributo cuenta: '
                        || TO_CHAR (v_nov.ident)
                        || ' .No existe el objeto o esta bloqueado';
                     -- baja logica de la cuenta
                     nexus_gis.network_updater.delete_link (v_objectid,
                                                  v_seqorder,
                                                  v_logid
                                                 );
                     nexus_gis.network_updater.revision_close (v_logid);
                  END IF;

                  -- marca la novedad como ya procesada
                  UPDATE utc.utc_novedades
                     SET statusid = 0,
                         desc_error = ''
                   WHERE ident = v_nov.ident AND statusid = v_nov.statusid;

                  COMMIT;
               EXCEPTION
                  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS
                  THEN
                     fdl_grabarlog
                        (p_nroproceso,
                         'Interfaz Clientes -> Actualizacion Grafica -> Baja de cuentas Inactivas',
                         'Error ' || v_err_msg,
                         TRUE
                        );
                     p_retval := p_retval + 1;          -- contador de errores
                  WHEN OTHERS
                  THEN
                     fdl_grabarlog
                        (p_nroproceso,
                         'Interfaz Clientes -> Actualizacion Grafica -> Baja de cuentas Inactiva',
                            'Error: '
                         || SUBSTR (SQLERRM, 0, 200)
                         || ' INFO: logid('
                         || TO_CHAR (v_logid)
                         || ') - ident('
                         || TO_CHAR (v_nov.ident)
                         || ')',
                         TRUE
                        );
               END;

            --Incremento el contador de Logs
            v_logid := v_logid + 1;
         END LOOP;
      END IF;

      COMMIT;

      --llama procedimiento
      NEXUS_GIS.PKG_PROCEDURES_INTERFAZ.MAIN_PROCEDURE;
      fdl_grabarlog (p_nroproceso,
                     'Interfaz Clientes -> Actualizacion Grafica',
                     'Fin',
                     TRUE
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         fdl_grabarlog
                      (p_nroproceso,
                       'Interfaz Clientes -> Actualizacion Grafica -> ERROR',
                       v_err_msg || ' SQL Error: ' || SUBSTR (SQLERRM, 0, 200),
                       TRUE
                      );
         RAISE;                          -- pasa el error a la rutina llamante
   END actualizacion_grafica;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    PROCEDURE depuracion_suministros (
      p_nroproceso   IN       NUMBER,
      p_userid       IN       NUMBER,
      p_retval       OUT      NUMBER
   )
   IS
      v_logid              nexus_gis.sprlog.logid%TYPE;
      v_objectid           nexus_gis.sprobjects.objectid%TYPE;
      v_seqorder           nexus_gis.sprlinks.seqorder%TYPE;
      v_sprid              nexus_gis.sprobjects.sprid%TYPE;
      v_cant_sinprocesar   NUMBER (20);
      v_cant_id_servicio   NUMBER (4);

      CURSOR c_anu
      IS
         SELECT id_servicio, ROWID
           FROM nexus_gis.tca_bgns4dl
          WHERE cod_est = 'AN';   -- anulados
   BEGIN
      -- Condiciona la ejecucion a que no haya registros en sprClientInterface aun sin procesar
      SELECT COUNT (*)
        INTO v_cant_sinprocesar
        FROM nexus_gis.sprclientinterface
       WHERE processlogid = 0;

      IF (v_cant_sinprocesar > 0)
      THEN
         fdl_grabarlog
            (p_nroproceso,
             'Interfaz Clientes -> Depuracion Suministros Anulados',
             'No se pudo ejecutar porque existen novedades pendientes en sprClientInterface',
             TRUE
            );
         p_retval := -1;
         RETURN;             -- sale del proceso sin hacer nada....
      ELSE
         p_retval := 0;
      END IF;

      -- registro en sprLog para identificar el proceso
      -- dado que este proceso realiza modificaciones en el modelo se debe manejar
      -- como una transaccion larga. De esta menera el AppServer se entera de los cambios
      v_logid :=
           nexus_gis.network_updater.sequencer (nexus_gis.model_constants.sequence_name_sprlog, 1);
      nexus_gis.network_updater.revision_create
                         (v_logid,
                          SYSDATE,
                          p_userid,
                          'Interfaz Clientes: Depuracion Suministros Anulados'
                         );
      COMMIT;

-----------------------------------------------------------------------------------
-- TASK 2: DEPURACION DE NNSS Y SUMINISTROS POTENCIALES ANULADOS
-----------------------------------------------------------------------------------

      -- actualiza el campo cod_est de los servicios anulados en BGND (DB2)
      -- solamente se tienen en cuenta los desenergizados (ya que son los unicos que
      -- se pueden anular en el sistema comercial)
      UPDATE nexus_gis.tca_bgns4dl
         SET cod_est = 'AN'
       WHERE servicio_energizad = 'N'
         AND cod_est IS NULL
         AND EXISTS (SELECT 1
                       FROM nexus_gis.serv_anul_bgns_tmp
                      WHERE id_servicio = nexus_gis.tca_bgns4dl.id_servicio)
         AND NOT EXISTS (SELECT 1
                           FROM nexus_gis.sprclients
                          WHERE custatt1 = TO_CHAR (nexus_gis.tca_bgns4dl.id_servicio));

      -- una vez actualizada TCA_BGNS4DL, se recorren los registros
      -- que quedaron con cod_est = 'AN'
      FOR v_anu IN c_anu
      LOOP
         BEGIN
            -- obtiene datos del suministro y del atributo IDServicio
            SELECT li.objectid, li.seqorder, ob.sprid
              INTO v_objectid, v_seqorder, v_sprid
              FROM nexus_gis.sprlinks li, nexus_gis.sprobjects ob
             WHERE li.objectid = ob.objectid -- gracias Giselle !!! 14/05/2007
               AND li.linkid = 1205                              -- IDServicio
               AND li.linkvalue = RPAD (v_anu.id_servicio, 30)
               AND li.logidto = 0
               AND ob.logidto = 0;

            -- baja logica del link IDServicio
            nexus_gis.network_updater.delete_link (v_objectid, v_seqorder, v_logid);

            -- verifica la existencia de otro atributo ID de servicio
            SELECT COUNT (*) AS cantidad
              INTO v_cant_id_servicio
              FROM nexus_gis.sprlinks
             WHERE objectid = v_objectid AND linkid = 1205 AND logidto = 0;

            -- si es un NNSS sobre suministro potencial y no tiene ID's de servicio vivos damos de baja el objeto
            IF v_sprid IN (1373, 1411) AND v_cant_id_servicio = 0
            THEN
               nexus_gis.network_updater.delete_symbol (v_objectid, v_logid);
            END IF;


         EXCEPTION
            WHEN NO_DATA_FOUND OR TOO_MANY_ROWS
            THEN
               fdl_grabarlog
                   (p_nroproceso,
                    'Interfaz Clientes -> Actualizacion Grafica -> Anulados',
                    'Error al anular el servicio: ' || v_anu.id_servicio,
                    TRUE
                   );
               p_retval := p_retval + 1;    -- contador de errores
         END;
      END LOOP;

      -- finaliza la transaccion "Larga"
      nexus_gis.network_updater.revision_close (v_logid);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         nexus_gis.network_updater.revision_cancel (v_logid);
         RAISE;                -- pasa el error a la rutina llamante
   END depuracion_suministros;

END INTERFAZ_CLIENTES;
/