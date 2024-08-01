DROP PACKAGE NEXUS_GIS.EDENOR_CARTOGRAFIA;

CREATE OR REPLACE PACKAGE NEXUS_GIS.edenor_cartografia
AS
-----------------------------------------------------------------------------------------------------
-- VERSION 1.2
-- Version Cartografia: 4_5.35
-- Autor: Pablo Dobrila
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Registro de Moficaciones. Fecha/Autor/Descripcion.
-- 05092007 - pdobrila - Version Inicial
-- 14112007 - pdobrila - Incorporacion de las Funciones "get_objectid_localizacion" y "getdatosgeouni_localizacion"
-- 07042008- pdobrila - Incorporacion de funcion para formatear el codigo de los elementos de maniobra
-----------------------------------------------------------------------------------------------------
--Funcion que obtiene los datos geograficos de un elemento del Unifilar
   FUNCTION getdatosgeouni (p_objeto NUMBER)
      RETURN VARCHAR2;

--Funcion que obtiene los datos geograficos de un elemento del Unifilar a partir de la localizacion
   FUNCTION getdatosgeouni_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN VARCHAR2;

--Funcion que obtiene a partir de un elemento del unifilar, el objectid de la localizacion.
--No existe: 0
--Duplicado: -2
--Error generico: -1
   FUNCTION get_objectid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER;

--Funcion que obtiene los datos geograficos de un elemento del Geografico
   FUNCTION getdatosgeograficos (p_objeto NUMBER)
      RETURN VARCHAR2;

--Funcion que obtiene el areaid de su elemento de potencia correspondiente
   FUNCTION get_areaid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER;

--Funcion que obtiene la cantidad de clientes de un suministro
   FUNCTION getcantidadclientessuministro (p_objeto NUMBER)
      RETURN NUMBER;

--Funcion que obtiene la potencia instalad de un suministro
   FUNCTION getpotenciasuministro (p_objeto NUMBER)
      RETURN FLOAT;

--Funcion que recibe el codigo de un elemento de maniobra y lo formatea si es valido, sino devuelve nulo
   FUNCTION em_valid_code (p_code VARCHAR2)
      RETURN VARCHAR2;

--Funcion que recibe el codigo de CT y devuelve la fecha de alta del ultimo trafo
   FUNCTION get_date_trafo (p_ct VARCHAR2)
      RETURN VARCHAR2;
END edenor_cartografia;
/


CREATE OR REPLACE SYNONYM NEX_GIS01.EDENOR_CARTOGRAFIA FOR NEXUS_GIS.EDENOR_CARTOGRAFIA;


CREATE OR REPLACE SYNONYM SVC_IDMS_NEXGIS.EDENOR_CARTOGRAFIA FOR NEXUS_GIS.EDENOR_CARTOGRAFIA;


GRANT EXECUTE ON NEXUS_GIS.EDENOR_CARTOGRAFIA TO IDMS_ROLE;

GRANT EXECUTE ON NEXUS_GIS.EDENOR_CARTOGRAFIA TO NEX_GIS01;


CREATE OR REPLACE PACKAGE BODY NEXUS_GIS.edenor_cartografia
IS
   FUNCTION getdatosgeouni (p_objeto NUMBER)
      RETURN VARCHAR2
   IS
          /*
          Datos geograficos de una instalacion del unifilar (CT, Elemento de maniobra, etc.)
          Retorna de manera formateada los siguientes atributos:

      Calle 1194
      N�mero de calle 1199
      Entre calle 1 1195
      Entre calle 2 1196
          */
      v_datosgeo   VARCHAR2 (400) := '';
      v_valor      VARCHAR2 (200);
   BEGIN
      -- Nombre de la calle principal
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 1194
                           AND logidto = 0);

         v_datosgeo := v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Altura
      BEGIN
         SELECT TRIM (linkvalue)
           INTO v_valor
           FROM sprlinks
          WHERE objectid = p_objeto AND linkid = 1199 AND logidto = 0;

         v_datosgeo := v_datosgeo || ' ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Primera entrecalle (entrecalle1)
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 1195
                           AND logidto = 0);

         v_datosgeo := v_datosgeo || ', EntreCalle: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Segunda entrecalle (entrecalle2)
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 1196
                           AND logidto = 0);

         v_datosgeo := v_datosgeo || ', EntreCalle: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      v_datosgeo := v_datosgeo;

      IF v_datosgeo IS NULL
      THEN
         v_datosgeo := 'Sin Datos del unifilar';
      END IF;

      RETURN v_datosgeo;
   END;

   FUNCTION getdatosgeograficos (p_objeto NUMBER)
      RETURN VARCHAR2
   AS
      /*
      Datos geograficos de una instalacion (CT, Elemento de maniobra, Suministro, etc.)
      Retorna de manera formateada los siguientes atributos:

      513 Domicilio: Calle
      511 Domicilio: Altura
      527 Domicilio: Entre calle 1
      528 Domicilio: Entre calle 2
      586 Domicilio: Piso
      585 Domicilio: Departamento

      Version 1.0 - 02/01/2005 - Alfredo Hantsch, version inicial
      */
      v_datosgeo   VARCHAR2 (400) := '';
      v_valor      VARCHAR2 (200);
   BEGIN
      -- Nombre de la calle principal
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 513
                           AND logidto = 0);

         v_datosgeo := v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Altura
      BEGIN
         SELECT TRIM (linkvalue)
           INTO v_valor
           FROM sprlinks
          WHERE objectid = p_objeto AND linkid = 511 AND logidto = 0;

         v_datosgeo := v_datosgeo || ' ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Primera entrecalle (entrecalle1)
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 527
                           AND logidto = 0);

         v_datosgeo := v_datosgeo || ', EntreCalle: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Segunda entrecalle (entrecalle2)
      BEGIN
         SELECT streetname
           INTO v_valor
           FROM smstreets
          WHERE streetid =
                   (SELECT linkvalue
                      FROM sprlinks
                     WHERE objectid = p_objeto AND linkid = 528
                           AND logidto = 0);

         v_datosgeo := v_datosgeo || ', EntreCalle: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Piso
      BEGIN
         SELECT TRIM (linkvalue)
           INTO v_valor
           FROM sprlinks
          WHERE objectid = p_objeto AND linkid = 586 AND logidto = 0;

         v_datosgeo := v_datosgeo || ', Piso: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      -- Departamento
      BEGIN
         SELECT TRIM (linkvalue)
           INTO v_valor
           FROM sprlinks
          WHERE objectid = p_objeto AND linkid = 585 AND logidto = 0;

         v_datosgeo := v_datosgeo || ', Dpto: ' || v_valor;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;                                             -- no hace nada
      END;

      IF v_datosgeo IS NULL
      THEN
         v_datosgeo := 'Sin Datos';
      END IF;

      RETURN v_datosgeo;
   END;

   FUNCTION get_areaid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER
   IS
      v_return         amareas.areaid%TYPE;
      v_objectid_lcz   sprobjects.objectid%TYPE;
   BEGIN
      v_objectid_lcz := get_objectid_localizacion (p_objectid);

      IF v_objectid_lcz > 0
      THEN
         SELECT TO_CHAR (TRIM (a.linkvalue))
           INTO v_return
           FROM sprlinks a
          WHERE a.objectid = v_objectid_lcz
            AND a.logidto = 0
            AND a.linkid = 1197;
      END IF;

      RETURN v_return;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      WHEN OTHERS
      THEN
         RETURN -1;
   END;

   FUNCTION getcantidadclientessuministro (p_objeto NUMBER)
      RETURN NUMBER
   AS
      /* CALCULA CANTIDAD DE CLIENTES POR OBJETO SUMINISTRO */
      v_count   NUMBER;
   BEGIN
      BEGIN
         SELECT COUNT (*)
           INTO v_count
           FROM sprlinks l
          WHERE l.linkid = 407 AND l.logidto = 0 AND l.objectid = p_objeto;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_count := 0;
      END;

      RETURN v_count;
   END;

   FUNCTION getpotenciasuministro (p_objeto NUMBER)
      RETURN FLOAT
   IS
      -- Determina la potencia de un suministro como sumatoria de potencias de las cuentas asociadas
      --
      -- La potencia de un cliente se obtiene de acuerdo al siguiente criterio:
      -- a) buscar en la tabla edenor_potencia_clientes (aqu� se registran las potencias de los clientes T1,
      --    de acuerdo al algoritmo "Pallero")
      -- b) si no se encuentra el valor en el punto a) hay que buscar en el campo sprClients.installedPower
      -- c) Si no se encuentra el valor en el punto b) hay que asumir una potencia de 1.5 kW
      --
      -- Alfredo Hantsch, 05/05/2007
      k_pot_default   CONSTANT FLOAT := 1.5;
      -- potencia default de un cliente, seg�n Edenor 1.5 kW
      v_pot_suministro         FLOAT := 0;

      -- recorre las cuentas de un suministro
      CURSOR cur_cuenta_sumi (p_objectid NUMBER)
      IS
         SELECT TRIM (linkvalue) cuenta
           FROM sprlinks
          WHERE objectid = p_objectid AND linkid = 407 AND logidto = 0;

      -- retorna la potencia de 1 cliente
      FUNCTION potencia_cliente (cuenta VARCHAR2)
         RETURN FLOAT
      IS
         v_pot1   FLOAT;
      BEGIN
         SELECT potencia
           INTO v_pot1
           FROM edenor_potencia_clientes
          WHERE codcliente = RPAD (cuenta, 30);

         RETURN v_pot1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT NVL (installedpower, k_pot_default)
                 INTO v_pot1
                 FROM sprclients
                WHERE fsclientid = cuenta;

               IF (v_pot1 = 0)
               THEN
                  v_pot1 := k_pot_default;
               END IF;

               RETURN v_pot1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  RETURN k_pot_default;
            END;
      END;
   BEGIN
      -- recorre las cuentas del suministro
      FOR c_cli IN cur_cuenta_sumi (p_objeto)
      LOOP
         v_pot_suministro :=
                           v_pot_suministro + potencia_cliente (c_cli.cuenta);
      END LOOP;

      RETURN v_pot_suministro;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;

   FUNCTION getdatosgeouni_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN VARCHAR2
   IS
      v_objectid_lcz   sprobjects.objectid%TYPE;
      v_return         VARCHAR (400);
   BEGIN
      v_objectid_lcz := get_objectid_localizacion (p_objectid);

      IF v_objectid_lcz > 0
      THEN
         v_return := getdatosgeouni (v_objectid_lcz);
      ELSIF v_objectid_lcz = 0
      THEN
         v_return := 'Error: no existe el elemento localizacion';
      ELSIF v_objectid_lcz = -1
      THEN
         v_return :=
               'Error: generico al obtener datos de el elemento localizacion';
      ELSIF v_objectid_lcz = -2
      THEN
         v_return := 'Error: codigo de localizacion duplicado';
      END IF;

      RETURN v_return;
   END;

   FUNCTION get_objectid_localizacion (p_objectid sprobjects.objectid%TYPE)
      RETURN NUMBER
   IS
      v_linkvalue         CHAR (30);
      v_codigo_elemento   VARCHAR (30);
      v_tipo_elemento     VARCHAR (10);
      v_objectid_lcz      sprobjects.objectid%TYPE;
   BEGIN
      SELECT linkvalue
        INTO v_linkvalue
        FROM sprlinks
       WHERE objectid = p_objectid AND linkid = 1198 AND logidto = 0;

      v_codigo_elemento :=
                  RPAD (SUBSTR (v_linkvalue, INSTR (v_linkvalue, '-') + 1),
                        30);
      v_tipo_elemento :=
                   SUBSTR (TRIM (v_linkvalue), 0, INSTR (v_linkvalue, '-') - 1);

      IF v_tipo_elemento = 'DE'
      THEN
         SELECT b.objectid
           INTO v_objectid_lcz
           FROM sprlinks a, sprobjects b
          WHERE a.linkid = 1187
            AND a.linkvalue = v_codigo_elemento
            AND a.logidto = 0
            AND b.objectid = a.objectid
            AND b.logidto = 0
            AND b.sprid = 1448;
      ELSIF v_tipo_elemento = 'SE'
      THEN
         SELECT b.objectid
           INTO v_objectid_lcz
           FROM sprlinks a, sprobjects b, sprentities c
          WHERE a.linkid = 1187
            AND a.linkvalue = v_codigo_elemento
            AND a.logidto = 0
            AND b.objectid = a.objectid
            AND b.logidto = 0
            AND c.sprid = b.sprid
            AND c.categid = 135;                           --categoria de SSEE
      ELSIF v_tipo_elemento = 'CT'
      THEN
         SELECT b.objectid
           INTO v_objectid_lcz
           FROM sprlinks a, sprobjects b, sprentities c
          WHERE a.linkid = 1187
            AND a.linkvalue = v_codigo_elemento
            AND a.logidto = 0
            AND b.objectid = a.objectid
            AND b.logidto = 0
            AND c.sprid = b.sprid
            AND c.categid = 132;                             --categoria de CT
      END IF;

      RETURN v_objectid_lcz;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      WHEN TOO_MANY_ROWS
      THEN
         RETURN -2;
      WHEN OTHERS
      THEN
         RETURN -1;
   END;

/*   FUNCTION em_valid_code (p_code VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return              VARCHAR2 (30);
      v_cont                NUMBER (5);
      v_aux                 VARCHAR2 (30);
      v_pos                 NUMBER (5);
      v_codigo_resultante   VARCHAR2 (30);
   BEGIN
      v_return := '';
      v_aux := p_code;
      v_cont := 0;
      v_pos := 1;

      WHILE v_cont <= 3 AND v_pos <> 0
      LOOP
         v_pos := INSTR (v_aux, '-');

         IF v_pos != 0
         THEN
            v_aux := SUBSTR (v_aux, v_pos + 1);
            v_cont := v_cont + 1;
         END IF;
      END LOOP;

      IF v_cont = 1
      THEN
         v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);

         IF UPPER (v_codigo_resultante) != 'NULL'
         THEN
            v_return := TRIM (v_codigo_resultante);
         END IF;
      ELSE
         IF v_cont = 3
         THEN
            v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);
            v_codigo_resultante :=
               SUBSTR (v_codigo_resultante,
                       INSTR (v_codigo_resultante, '-') + 1
                      );

            IF UPPER (v_codigo_resultante) != 'NULL'
            THEN
               v_return := TRIM (v_codigo_resultante);
            END IF;
         END IF;
      END IF;

      RETURN v_return;
   END;*/

   FUNCTION em_valid_code (p_code VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return              VARCHAR2 (30);
      v_cont                NUMBER (5);
      v_aux                 VARCHAR2 (30);
      v_pos                 NUMBER (5);
      v_codigo_resultante   VARCHAR2 (30);
   BEGIN
        --dbms_output.put_line('Prueba');
      v_return := '';
      v_aux := p_code;
      v_cont := 0;
      v_pos := 1;
      
      v_return := v_aux;

      WHILE v_cont <= 3 AND v_pos <> 0
      LOOP
         v_pos := INSTR (v_aux, '-');

         IF v_pos != 0
         THEN
            v_aux := SUBSTR (v_aux, v_pos + 1);
            --dbms_output.put_line(v_aux);
            v_cont := v_cont + 1;
         END IF;
      END LOOP;
        --dbms_output.put_line(v_codigo_resultante);
        --dbms_output.put_line(v_cont);
      IF v_cont = 1
      THEN
        --dbms_output.put_line(v_aux);
         v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);

         IF UPPER (v_codigo_resultante) != 'NULL'
         THEN
            v_return := TRIM (v_codigo_resultante);
         END IF;
      ELSE
         IF v_cont = 3
         THEN
            v_codigo_resultante := SUBSTR (p_code, INSTR (p_code, '-') + 1);
            v_codigo_resultante :=
               SUBSTR (v_codigo_resultante,
                       INSTR (v_codigo_resultante, '-') + 1
                      );

            IF UPPER (v_codigo_resultante) != 'NULL'
            THEN
               v_return := TRIM (v_codigo_resultante);
            END IF;
         END IF;
      END IF;
        --dbms_output.put_line('1 ' || v_codigo_resultante);
      RETURN v_return;
   END;

   FUNCTION get_date_trafo (p_ct VARCHAR2)
      RETURN VARCHAR2
   IS
      v_trafo_date   date;
   BEGIN
      SELECT MAX (a.datefrom)
        INTO v_trafo_date
        FROM sprlinks a
       WHERE a.linkid = 1018
         AND a.logidto = 0
         AND a.linkvalue LIKE (TRIM (p_ct) || '%');

      IF v_trafo_date IS NULL
      THEN
         RETURN 'sin trafo';
      ELSE
         RETURN to_char(v_trafo_date,'DD/MM/YYYY');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'Error';
   END;
END edenor_cartografia;
/


CREATE OR REPLACE SYNONYM NEX_GIS01.EDENOR_CARTOGRAFIA FOR NEXUS_GIS.EDENOR_CARTOGRAFIA;


CREATE OR REPLACE SYNONYM SVC_IDMS_NEXGIS.EDENOR_CARTOGRAFIA FOR NEXUS_GIS.EDENOR_CARTOGRAFIA;


GRANT EXECUTE ON NEXUS_GIS.EDENOR_CARTOGRAFIA TO IDMS_ROLE;

GRANT EXECUTE ON NEXUS_GIS.EDENOR_CARTOGRAFIA TO NEX_GIS01;
