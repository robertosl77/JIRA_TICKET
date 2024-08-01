CREATE OR REPLACE PACKAGE BODY UTC.Pck_CCnB_Utc IS
/*
Version 11/01/13
-----------------------------------------
-----------------------------------------
-----------------------------------------

Tablas Auxiliares

* UTC_ACTIVIDADES
* UTC_CICLOS
* UTC_ESTADOS_AS
* UTC_ESTRUC_TARIFARIA
* UTC_OFICINAS_COM
* UTC_RUTAS
* UTC_TENSIONES
* UTC_TIPOS_DOCUM
* UTC_TIPOS_MEDIDOR
* UTC_TIPO_AS

Tabla Principales

UTC_CLIENTE_DIA
CLIENTES
/*04-10-2013 se modifico en el procedimiento Act_Tipos_Docum, en el update , para que sea del campo TDOC_DESCRIP de la tabla utc.tipos_docum  */
-----------------------------------------
-----------------------------------------
-----------------------------------------*/

/*-------------------------------------------------------------------------------------------------*/
/*---------------------------------INSERTAR_ERROR--------------------------------------*/
/*OK --------------------------------------------------------------------------------------------*/
PROCEDURE INSERTAR_ERROR (P_ID_ERROR    IN NUMBER,
                          P_PROCESO     IN VARCHAR2,
                          P_TABLA_CAMPO IN VARCHAR2,
                          P_VALOR       IN VARCHAR2,
                          P_DESCRIPCION IN VARCHAR2) IS
    ID_ERROR NUMBER;
    BEGIN

        INSERT INTO UTC.LOG_ERRORES (ID_ERROR,
                                        PROCESO,
                                     VALOR,
                                     CAMPO,
                                     DESC_ERROR,
                                     F_MODIF)
             VALUES (P_ID_ERROR,
                     SUBSTR(P_PROCESO,1,60),
                    SUBSTR(P_VALOR,1,100),
                    SUBSTR(P_TABLA_CAMPO,1,100),
                    SUBSTR(P_DESCRIPCION,1,255),
                    TRUNC(SYSDATE,'dd'));
                COMMIT;

    EXCEPTION
    WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('INSERTAR_ERROR - '||SQLERRM);
END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------CARGO_ACTIVIDADES----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_ACTIVIDADES (P_ID_ERROR IN NUMBER,
                          P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

        v_descripcion utc.actividades.ACTI_DESCRIP%TYPE;

        CURSOR cur_actividades_from_ccnb IS
            SELECT NVL(trim(ACTI_COD),'S/C') ACTI_COD,
                   ACTI_DESCRIP
              FROM utc.utc_actividades
             ORDER BY ACTI_COD;

        CURSOR cur_bajas IS
           (SELECT ACTI_COD
              FROM utc.actividades
             WHERE F_BAJA is null)
            MINUS
           (SELECT ACTI_COD
              FROM utc.utc_actividades);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_actividades IN cur_actividades_from_ccnb LOOP
            BEGIN
                SELECT ACTI_DESCRIP
                  INTO v_descripcion
                  FROM utc.actividades
                 WHERE F_BAJA is null
                   and ACTI_COD = reg_actividades.ACTI_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_actividades.ACTI_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.actividades
                           SET ACTI_DESCRIP = reg_actividades.ACTI_DESCRIP
                         WHERE ACTI_COD = reg_actividades.ACTI_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_ACTIVIDADES',
                                           'utc.actividades.ACTI_COD',
                                            reg_actividades.ACTI_COD,
                                           'Error modificando ACTI_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.actividades (ACTI_COD,ACTI_DESCRIP)
                             VALUES (reg_actividades.ACTI_COD,reg_actividades.ACTI_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                        INSERTAR_ERROR(P_ID_ERROR,
                                       'ACT_ACTIVIDADES',
                                       'utc.actividades.ACTI_COD',
                                        reg_actividades.ACTI_COD,
                                       'Error insertando utc.actividades - '||sqlerrm);
                        P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_ACTIVIDADES',
                                   'utc.actividades.ACTI_COD',
                                    reg_actividades.ACTI_COD,
                                    'Error buscando ACTI_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.actividades
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE ACTI_COD = reg_bajas.ACTI_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_ACTIVIDADES',
                                   'utc.actividades.ACTI_COD',
                                    reg_bajas.ACTI_COD,
                                    'Error al dar de baja ACTI_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

     EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando actividades - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*------------------------------------CARGO CICLOS---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_CICLOS (P_ID_ERROR IN NUMBER,
                     P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.ciclos.CICL_DESCRIP%TYPE;

    CURSOR cur_ciclos_from_ccnb IS
        SELECT NVL(trim(CICL_COD),'S/C') CICL_COD,
               CICL_DESCRIP
          FROM utc.utc_ciclos
         ORDER BY CICL_COD;

    CURSOR cur_bajas IS
       (SELECT CICL_COD
          FROM utc.ciclos
         WHERE F_BAJA is null)
        MINUS
       (SELECT CICL_COD
          FROM utc.utc_ciclos);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_ciclos IN cur_ciclos_from_ccnb LOOP
            BEGIN
                SELECT CICL_DESCRIP
                  INTO v_descripcion
                  FROM utc.ciclos
                 WHERE F_BAJA is null
                   and CICL_COD = reg_ciclos.CICL_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_ciclos.CICL_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.ciclos
                           SET CICL_DESCRIP = reg_ciclos.CICL_DESCRIP
                         WHERE CICL_COD = reg_ciclos.CICL_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_CICLOS',
                                          'utc.ciclos.CICL_COD',
                                           reg_ciclos.CICL_COD,
                                          'Error modificando CICL_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.ciclos (CICL_COD,CICL_DESCRIP)
                             VALUES (reg_ciclos.CICL_COD,reg_ciclos.CICL_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_CICLOS',
                                          'utc.ciclos.CICL_COD',reg_ciclos.CICL_COD,
                                          'Insertando utc.ciclos - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_CICLOS',
                                          'utc.ciclos.CICL_COD',reg_ciclos.CICL_COD,
                                          'Error buscando CICL_COD - '||sqlerrm);
                            P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.ciclos
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE CICL_COD = reg_bajas.CICL_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                  'ACT_CICLOS',
                                  'utc.ciclos.CICL_COD',reg_bajas.CICL_COD,
                                  'Error al dar de baja CICL_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

  EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error procesando ciclos - '||sqlerrm);
END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------CARGO ESTADOS_AS----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_ESTADOS_AS (P_ID_ERROR IN NUMBER,
                         P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.estados_as.DESCRIPCION%TYPE;

    CURSOR cur_estados_as_from_ccnb IS
        SELECT NVL(trim(ACU_SRV_ESTADO),'00') ACU_SRV_ESTADO,
               DESCRIPCION
          FROM utc.utc_estados_as
      ORDER BY ACU_SRV_ESTADO;

    CURSOR cur_bajas IS
       (SELECT ACU_SRV_ESTADO
          FROM utc.estados_as
         WHERE F_BAJA is null)
        MINUS
       (SELECT ACU_SRV_ESTADO
          FROM utc.utc_estados_as);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_estados_as IN cur_estados_as_from_ccnb LOOP
            BEGIN
                SELECT DESCRIPCION
                  INTO v_descripcion
                  FROM utc.estados_as
                 WHERE F_BAJA is null
                   and ACU_SRV_ESTADO = reg_estados_as.ACU_SRV_ESTADO;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_estados_as.DESCRIPCION) THEN
                    BEGIN
                        UPDATE utc.estados_as
                           SET DESCRIPCION = reg_estados_as.DESCRIPCION
                         WHERE ACU_SRV_ESTADO = reg_estados_as.ACU_SRV_ESTADO;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_ESTADOS_AS',
                                          'utc.estados_as.ACU_SRV_ESTADO',
                                           reg_estados_as.ACU_SRV_ESTADO,
                                            'Error modificando DESCRIPCION - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.estados_as (ACU_SRV_ESTADO,DESCRIPCION)
                             VALUES (reg_estados_as.ACU_SRV_ESTADO,reg_estados_as.DESCRIPCION);
                          EXCEPTION
                            WHEN OTHERS THEN
                                INSERTAR_ERROR(P_ID_ERROR,
                                               'ACT_ESTADOS_AS',
                                               'utc.estados_as.ACU_SRV_ESTADO',
                                                reg_estados_as.ACU_SRV_ESTADO,
                                                'Error insertando utc.estados_as - '||sqlerrm);
                                P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_ESTADOS_AS',
                                   'utc.estados_as.ACU_SRV_ESTADO',
                                    reg_estados_as.ACU_SRV_ESTADO,
                                    'Error buscando ACU_SRV_ESTADO - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.estados_as
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE ACU_SRV_ESTADO = reg_bajas.ACU_SRV_ESTADO;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                  'ACT_ESTADOS_AS',
                                  'utc.estados_as.ACU_SRV_ESTADO',
                                   reg_bajas.ACU_SRV_ESTADO,
                                   'Error al dar de baja ACU_SRV_ESTADO - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando Estados_As - '||sqlerrm);
END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-----------------------CARGO ESTRUC_TARIFARIA ----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_ESTRUC_TARIFARIA (P_ID_ERROR IN NUMBER,
                               P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.estruc_tarifaria.TARI_DESCRIP%TYPE;
    v_grupo utc.estruc_tarifaria.TARI_GRUPO%TYPE;
    V_TARI_FILTRO utc.estruc_tarifaria.TARI_FILTRO%TYPE;

    CURSOR cur_estruc_tarifaria_from_ccnb IS
        SELECT NVL(trim(TARI_COD),'S/C') TARI_COD,
               TARI_DESCRIP,
               TARI_GRUPO
          FROM utc.utc_estruc_tarifaria
         ORDER BY TARI_COD;

    CURSOR cur_bajas IS
       (SELECT TARI_COD
          FROM utc.estruc_tarifaria
         WHERE F_BAJA is null)
        MINUS
       (SELECT TARI_COD
          FROM utc.utc_estruc_tarifaria);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_estruc_tarifaria IN cur_estruc_tarifaria_from_ccnb LOOP
            BEGIN
                SELECT TARI_DESCRIP,TARI_GRUPO
                  INTO v_descripcion,v_grupo
                  FROM utc.estruc_tarifaria
                 WHERE F_BAJA is null
                   and TARI_COD = reg_estruc_tarifaria.TARI_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_estruc_tarifaria.TARI_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.estruc_tarifaria
                           SET TARI_DESCRIP = reg_estruc_tarifaria.TARI_DESCRIP
                         WHERE TARI_COD = reg_estruc_tarifaria.TARI_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_ESTRUC_TARIFARIA',
                                          'utc.estruc_tarifaria.TARI_COD',
                                           reg_estruc_tarifaria.TARI_COD,
                                          'Error modificando TARI_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
                IF (v_grupo != reg_estruc_tarifaria.TARI_GRUPO) THEN
                    BEGIN
                        UPDATE utc.estruc_tarifaria
                           SET TARI_GRUPO = reg_estruc_tarifaria.TARI_GRUPO
                         WHERE TARI_COD = reg_estruc_tarifaria.TARI_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_ESTRUC_TARIFARIA',
                                           'utc.estruc_tarifaria.TARI_COD',
                                            reg_estruc_tarifaria.TARI_COD,
                                            'Error modificando TARI_GRUPO - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        IF reg_estruc_tarifaria.TARI_GRUPO = 'OT' THEN
                            V_TARI_FILTRO := 'S';
                        ELSE
                            V_TARI_FILTRO := NULL;
                        END IF;
                        INSERT INTO utc.estruc_tarifaria (TARI_COD,TARI_DESCRIP,TARI_GRUPO,TARI_FILTRO)
                             VALUES (reg_estruc_tarifaria.TARI_COD,reg_estruc_tarifaria.TARI_DESCRIP,reg_estruc_tarifaria.TARI_GRUPO,V_TARI_FILTRO);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_ESTRUC_TARIFARIA',
                                          'utc.estruc_tarifaria.TARI_COD',
                                           reg_estruc_tarifaria.TARI_COD,
                                          'Error insertando utc.estruc_tarifaria - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_ESTRUC_TARIFARIA',
                                   'utc.estruc_tarifaria.TARI_COD',
                                    reg_estruc_tarifaria.TARI_COD,
                                    'Error buscando TARI_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.estruc_tarifaria
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE TARI_COD = reg_bajas.TARI_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_ESTRUC_TARIFARIA',
                                   'utc.estruc_tarifaria.TARI_COD',
                                    reg_bajas.TARI_COD,
                                    'Error al dar de baja TARI_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

   EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error procesando Estructura Tarifaria - '||sqlerrm);
END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-----------------------------CARGO OFICINAS_COM----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_OFICINAS_COM (P_ID_ERROR IN NUMBER,
                           P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.oficinas_com.OFCO_DESCRIP%TYPE;

    CURSOR cur_oficinas_com_from_ccnb IS
        SELECT NVL(trim(OFCO_COD),'S/C') OFCO_COD,
               OFCO_DESCRIP
          FROM utc.utc_oficinas_com
        ORDER BY OFCO_COD;

    CURSOR cur_bajas IS
        (SELECT OFCO_COD
           FROM utc.oficinas_com
          WHERE F_BAJA is null)
          MINUS
        (SELECT OFCO_COD
           FROM utc.utc_oficinas_com);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_oficinas_com IN cur_oficinas_com_from_ccnb LOOP
            BEGIN
                SELECT OFCO_DESCRIP
                  INTO v_descripcion
                  FROM utc.oficinas_com
                 WHERE F_BAJA is null
                   and OFCO_COD = reg_oficinas_com.OFCO_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_oficinas_com.OFCO_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.oficinas_com
                           SET OFCO_DESCRIP = reg_oficinas_com.OFCO_DESCRIP
                         WHERE OFCO_COD = reg_oficinas_com.OFCO_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_OFICINAS_COM',
                                          'utc.oficinas_com.OFCO_COD',
                                           reg_oficinas_com.OFCO_COD,
                                           'Error modificando OFCO_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.oficinas_com (OFCO_COD,OFCO_DESCRIP)
                             VALUES (reg_oficinas_com.OFCO_COD,reg_oficinas_com.OFCO_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_OFICINAS_COM',
                                           'utc.oficinas_com.OFCO_COD',
                                            reg_oficinas_com.OFCO_COD,
                                            'Error insertando utc.oficinas_com - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_OFICINAS_COM',
                                   'utc.oficinas_com.OFCO_COD',
                                    reg_oficinas_com.OFCO_COD,
                                    'Error buscando OFCO_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.oficinas_com
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE OFCO_COD = reg_bajas.OFCO_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_OFICINAS_COM',
                                   'utc.oficinas_com.OFCO_COD',
                                    reg_bajas.OFCO_COD,
                                    'Error al dar de baja OFCO_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando Oficinas Comerciales - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*----------------------------------CARGO RUTAS-------------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_RUTAS (P_ID_ERROR IN NUMBER,
                    P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.actividades.ACTI_DESCRIP%TYPE;

    CURSOR cur_rutas_from_ccnb IS
        SELECT NVL(trim(CICL_COD),'S/C') CICL_COD,
               NVL(trim(RUTA_COD),'S/C') RUTA_COD,
               RUTA_DESCRIP
          FROM utc.utc_rutas
         ORDER BY CICL_COD;

    CURSOR cur_bajas IS
       (SELECT CICL_COD,RUTA_COD
          FROM utc.rutas
         WHERE F_BAJA is null)
        MINUS
       (SELECT CICL_COD,RUTA_COD
          FROM utc.utc_rutas);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_rutas IN cur_rutas_from_ccnb LOOP
            BEGIN
                SELECT RUTA_DESCRIP
                  INTO v_descripcion
                  FROM utc.rutas
                 WHERE F_BAJA is null
                   AND RUTA_COD = reg_rutas.RUTA_COD
                   AND CICL_COD = reg_rutas.CICL_COD;

                    --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_rutas.RUTA_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.rutas
                           SET RUTA_DESCRIP = reg_rutas.RUTA_DESCRIP
                         WHERE RUTA_COD = reg_rutas.RUTA_COD
                           AND CICL_COD = reg_rutas.CICL_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_RUTAS',
                                           'utc.rutas.RUTA_COD',
                                            reg_rutas.RUTA_COD,
                                            'Error modificando RUTA_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.rutas (CICL_COD,RUTA_COD,RUTA_DESCRIP)
                             VALUES (reg_rutas.CICL_COD,reg_rutas.RUTA_COD,reg_rutas.RUTA_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_RUTAS',
                                           'utc.rutas.RUTA_COD',
                                           reg_rutas.RUTA_COD,
                                           'Error insertando utc.rutas - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                    WHEN OTHERS THEN
                        INSERTAR_ERROR(P_ID_ERROR,
                                      'ACT_RUTAS',
                                      'utc.rutas.RUTA_COD',
                                      reg_rutas.RUTA_COD,
                                      'Error buscando RUTA_COD - '||sqlerrm);
                        P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.rutas
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE CICL_COD = reg_bajas.CICL_COD
                   and RUTA_COD = reg_bajas.RUTA_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                  'ACT_RUTAS',
                                  'utc.rutas.RUTA_COD',
                                   reg_bajas.RUTA_COD,
                                   'Error al dar de baja RUTA_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando Rutas - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------  CARGO TENSIONES   ----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_TENSIONES(P_ID_ERROR IN NUMBER,
                       P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.tensiones.TENS_DESCRIP%TYPE;

    CURSOR cur_tensiones_from_ccnb IS
        SELECT NVL(trim(TENS_COD),'S/C') TENS_COD,
               TENS_DESCRIP
          FROM utc.utc_tensiones
         ORDER BY TENS_COD;

    CURSOR cur_bajas IS
       (SELECT TENS_COD
          FROM utc.tensiones
         WHERE F_BAJA is null)
        MINUS
       (SELECT TENS_COD
          FROM utc.utc_tensiones);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_tensiones IN cur_tensiones_from_ccnb LOOP
            BEGIN
                SELECT TENS_DESCRIP
                  INTO v_descripcion
                  FROM utc.tensiones
                 WHERE F_BAJA is null
                   and TENS_COD = reg_tensiones.TENS_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_tensiones.TENS_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.tensiones
                           SET TENS_DESCRIP = reg_tensiones.TENS_DESCRIP
                         WHERE TENS_COD = reg_tensiones.TENS_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_TENSIONES',
                                           'utc.tensiones.TENS_COD',
                                            reg_tensiones.TENS_COD,
                                            'Error modificando TENS_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.tensiones (TENS_COD,TENS_DESCRIP)
                             VALUES (reg_tensiones.TENS_COD,reg_tensiones.TENS_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_TENSIONES',
                                           'utc.tensiones.TENS_COD',
                                            reg_tensiones.TENS_COD,
                                            'Error insertando utc.tensiones - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TENSIONES',
                                   'utc.tensiones.TENS_COD',
                                    reg_tensiones.TENS_COD,
                                    'Error buscando TENS_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.tensiones
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE TENS_COD = reg_bajas.TENS_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                  'ACT_TENSIONES',
                                  'utc.tensiones.TENS_COD',
                                   reg_bajas.TENS_COD,
                                  'Error al dar de baja TENS_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando tensiones - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------  CARGO TIPOS_DOCUM   ----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_TIPOS_DOCUM(P_ID_ERROR IN NUMBER,
                         P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.tipos_docum.TDOC_DESCRIP%TYPE;

    CURSOR cur_tipos_docum_from_ccnb IS
        SELECT NVL(trim(TDOC_COD),'S/C') TDOC_COD,
               TDOC_DESCRIP
          FROM utc.utc_tipos_docum
         ORDER BY TDOC_COD;

    CURSOR cur_bajas IS
       (SELECT TDOC_COD
          FROM utc.tipos_docum
         WHERE F_BAJA is null)
        MINUS
       (SELECT TDOC_COD
          FROM utc.utc_tipos_docum);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_tipos_docum IN cur_tipos_docum_from_ccnb LOOP
            BEGIN
                SELECT TDOC_DESCRIP
                  INTO v_descripcion
                  FROM utc.tipos_docum
                 WHERE F_BAJA is null
                   and TDOC_COD = reg_tipos_docum.TDOC_COD;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_tipos_docum.TDOC_DESCRIP) THEN
                    BEGIN
                        UPDATE utc.tipos_docum
                           SET TDOC_DESCRIP = reg_tipos_docum.TDOC_DESCRIP
                         WHERE TDOC_COD = reg_tipos_docum.TDOC_COD;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_TIPOS_DOCUM',
                                           'utc.tipos_docum.TDOC_COD',
                                            reg_tipos_docum.TDOC_COD,
                                            'Error modificando TDOC_DESCRIP - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.tipos_docum (TDOC_COD,TDOC_DESCRIP)
                             VALUES (reg_tipos_docum.TDOC_COD,reg_tipos_docum.TDOC_DESCRIP);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_TIPOS_DOCUM',
                                           'utc.tipos_docum.TDOC_COD',
                                            reg_tipos_docum.TDOC_COD,
                                            'Error insertando utc.tipos_docum - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TIPOS_DOCUM',
                                   'utc.tipos_docum.TDOC_COD',
                                    reg_tipos_docum.TDOC_COD,
                                    'Error buscando TDOC_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.tipos_docum
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE TDOC_COD = reg_bajas.TDOC_COD;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TIPOS_DOCUM',
                                   'utc.tipos_docum.TDOC_COD',
                                    reg_bajas.TDOC_COD,
                                    'Error al dar de baja TDOC_COD - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK')           THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando tensiones - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*----------------------------  CARGO TIPOS_MEDIDOR  -------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_TIPOS_MEDIDOR(P_ID_ERROR IN NUMBER,
                           P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.tipos_medidor.DESCRIPCION%TYPE;

    CURSOR cur_tipos_medidor_from_ccnb IS
        SELECT NVL(trim(TIPO_MEDIDOR),'S/C') TIPO_MEDIDOR,
               DESCRIPCION,
               FABRICANTE,
               MODELO
         FROM utc.utc_tipos_medidor
        ORDER BY TIPO_MEDIDOR;

    CURSOR cur_bajas IS
        (SELECT TIPO_MEDIDOR
           FROM utc.tipos_medidor
          WHERE F_BAJA is null)
          MINUS
        (SELECT TIPO_MEDIDOR
           FROM utc.utc_tipos_medidor);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_tipos_medidor IN cur_tipos_medidor_from_ccnb LOOP
            BEGIN
                SELECT DESCRIPCION
                  INTO v_descripcion
                  FROM utc.tipos_medidor
                 WHERE F_BAJA is null
                   and TIPO_MEDIDOR = reg_tipos_medidor.TIPO_MEDIDOR;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion !=  reg_tipos_medidor.DESCRIPCION) THEN
                    BEGIN
                        UPDATE utc.tipos_medidor
                           SET DESCRIPCION = reg_tipos_medidor.DESCRIPCION,
                               FABRICANTE = reg_tipos_medidor.FABRICANTE,
                               MODELO = reg_tipos_medidor.MODELO
                         WHERE TIPO_MEDIDOR = reg_tipos_medidor.TIPO_MEDIDOR;
                     EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_TIPOS_MEDIDOR',
                                          'reg_tipos_medidor.TIPO_MEDIDOR',
                                           reg_tipos_medidor.TIPO_MEDIDOR,
                                           'Error modificando DESCRIPCION - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.tipos_medidor (TIPO_MEDIDOR,DESCRIPCION,FABRICANTE,MODELO)
                             VALUES (reg_tipos_medidor.TIPO_MEDIDOR,reg_tipos_medidor.DESCRIPCION,reg_tipos_medidor.FABRICANTE,reg_tipos_medidor.MODELO);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                           'ACT_TIPOS_MEDIDOR',
                                           'reg_tipos_medidor.TIPO_MEDIDOR',
                                            reg_tipos_medidor.TIPO_MEDIDOR,
                                            'Error insertando utc.tipos_medidor - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TIPOS_MEDIDOR',
                                   'reg_tipos_medidor.TIPO_MEDIDOR',
                                    reg_tipos_medidor.TIPO_MEDIDOR,
                                    'Error buscando tipo_medidor - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.tipos_medidor
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE TIPO_MEDIDOR = reg_bajas.TIPO_MEDIDOR;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                  'ACT_TIPOS_MEDIDOR',
                                  'reg_tipos_medidor.TIPO_MEDIDOR',
                                   reg_bajas.TIPO_MEDIDOR,
                                   'Error al dar de baja tipo_medidor - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK') THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando tipo de medidores - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------  CARGO TIPO_AS   ---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


FUNCTION ACT_TIPO_AS (P_ID_ERROR IN NUMBER,
                      P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_descripcion utc.tipo_as.DESCRIPCION%TYPE;

    CURSOR cur_tipo_as_from_ccnb IS
        SELECT NVL(trim(TIPO_AS),'S/C') TIPO_AS,
               DESCRIPCION
          FROM utc.utc_tipo_as
         ORDER BY TIPO_AS;

    CURSOR cur_bajas IS
        (SELECT TIPO_AS
           FROM utc.tipo_as
          WHERE F_BAJA is null)
        MINUS
        (SELECT TIPO_AS
           FROM utc.utc_tipo_as);

    -- PL/SQL Block
    BEGIN
        P_MENSAJE := 'OK';
        FOR reg_tipo_as IN cur_tipo_as_from_ccnb LOOP
            BEGIN
                SELECT DESCRIPCION
                  INTO v_descripcion
                  FROM utc.tipo_as
                 WHERE F_BAJA is null
                   and TIPO_AS = reg_tipo_as.TIPO_AS;

                --Existe el registro lo modifico si es necesario
                IF (v_descripcion != reg_tipo_as.DESCRIPCION) THEN
                    BEGIN
                        UPDATE utc.tipo_as
                           SET DESCRIPCION = reg_tipo_as.DESCRIPCION
                         WHERE TIPO_AS = reg_tipo_as.TIPO_AS;
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_TIPO_AS',
                                          'utc.tipo_as.TIPO_AS',
                                           reg_tipo_as.TIPO_AS,
                                           'Error modificando TIPO_AS - '||sqlerrm);
                            P_MENSAJE := 'Errores al Modificar';
                    END;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- No existe hay que insertar
                    BEGIN
                        INSERT INTO utc.tipo_as (TIPO_AS,DESCRIPCION)
                             VALUES (reg_tipo_as.TIPO_AS,reg_tipo_as.DESCRIPCION);
                      EXCEPTION
                        WHEN OTHERS THEN
                            INSERTAR_ERROR(P_ID_ERROR,
                                          'ACT_TIPO_AS',
                                          'utc.tipo_as.TIPO_AS',
                                           reg_tipo_as.TIPO_AS,
                                           'Error insertando utc.tipo_as - '||sqlerrm);
                            P_MENSAJE := 'Errores al Insertar';
                    END;
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TIPO_AS',
                                   'utc.tipo_as.TIPO_AS',
                                    reg_tipo_as.TIPO_AS,
                                    'Error buscando TIPO_AS - '||sqlerrm);
                    P_MENSAJE := 'Errores al buscar';
            END;
        END LOOP;
        COMMIT;
        -- Trato los bajas
        FOR  reg_bajas IN Cur_bajas LOOP
            BEGIN
                UPDATE utc.tipo_as
                   SET F_BAJA = TRUNC(SYSDATE)
                 WHERE TIPO_AS = reg_bajas.TIPO_AS;
              EXCEPTION
                WHEN OTHERS THEN
                    INSERTAR_ERROR(P_ID_ERROR,
                                   'ACT_TIPO_AS',
                                   'utc.tipo_as.TIPO_AS',
                                    reg_bajas.TIPO_AS,
                                    'Error al dar de baja TIPO_AS - '||sqlerrm);
                    P_MENSAJE := 'Errores al dar de Baja';
            END;
        END LOOP;
        COMMIT;

        IF (P_MENSAJE != 'OK')  THEN
            RETURN(FALSE);
        ELSE
            RETURN(TRUE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando TIPO_AS - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*------------------  CARGO Todas las Auxiliares   ---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

PROCEDURE ACTUALIZAR_AUXILIARES (P_ID_ERROR IN NUMBER) IS
    V_MENSAJE VARCHAR2(200);
    BEGIN
        IF NOT (ACT_ACTIVIDADES(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando ACTIVIDADES - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_CICLOS(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando CICLOS - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_ESTADOS_AS(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando ESTADOS_AS - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_ESTRUC_TARIFARIA(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando ESTRUC_TARIFARIA - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_OFICINAS_COM(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando OFICINAS_COM - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_RUTAS(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando CICLOS - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_TENSIONES(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando CTA_ESTADOS - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_TIPOS_DOCUM(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando ESTADOS_AS - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_TIPOS_MEDIDOR(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando OFICINAS_COM - '||V_MENSAJE);
        END IF;
        IF NOT (ACT_TIPO_AS(P_ID_ERROR,V_MENSAJE)) THEN
            DBMS_OUTPUT.PUT_LINE('Error procesando ESTRUC_TARIFARIA - '||V_MENSAJE);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error procesando TABLAS AUXILIARES - '||sqlerrm);
    END;


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*---------------------  Actualizo UTC.CLIENTES   ---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

PROCEDURE UPDATE_CLIENTE (P_ID_ERROR IN NUMBER,
                          P_REG      IN UTC.CLIENTES%ROWTYPE,
                          P_MENSAJE  IN OUT VARCHAR2) IS
    BEGIN
        P_MENSAJE := 'OK';
        UPDATE UTC.CLIENTES
        SET     CLIE_ID                 = P_REG.CLIE_ID,
                CLIE_APYNOM             = P_REG.CLIE_APYNOM,
                CLIE_CALLE              = P_REG.CLIE_CALLE,
                CLIE_ENTRE_CALLE1       = P_REG.CLIE_ENTRE_CALLE1,
                CLIE_ENTRE_CALLE2       = P_REG.CLIE_ENTRE_CALLE2,
                CLIE_CALLE_NUM          = P_REG.CLIE_CALLE_NUM,
                CLIE_DOMICILIO_PISO     = P_REG.CLIE_DOMICILIO_PISO,
                CLIE_DOMICILIO_DEPTO    = P_REG.CLIE_DOMICILIO_DEPTO,
                CLIE_POSTAL_COD         = P_REG.CLIE_POSTAL_COD,
                CLIE_LOCALIDAD          = P_REG.CLIE_LOCALIDAD,
                CLIE_PARTIDO            = P_REG.CLIE_PARTIDO,
                ZONA_ID                 = P_REG.ZONA_ID,
                CLIE_TELEFONO           = P_REG.CLIE_TELEFONO,
                TDOC_ID                 = P_REG.TDOC_ID,
                CLIE_DOCUM_NUM          = P_REG.CLIE_DOCUM_NUM,
                CICL_ID                 = P_REG.CICL_ID,
                RUTA_ID                 = P_REG.RUTA_ID,
                ACTI_ID                 = P_REG.ACTI_ID,
                CLIE_POT_CONV_PTA       = P_REG.CLIE_POT_CONV_PTA,
                CLIE_POT_CONV_FPTA      = P_REG.CLIE_POT_CONV_FPTA,
                CLIE_TRATO_ESPECIAL     = P_REG.CLIE_TRATO_ESPECIAL,
                TMED_ID                 = P_REG.TMED_ID,
                CLIE_MEDIDOR_NUM        = P_REG.CLIE_MEDIDOR_NUM,
                CLIE_LECT_ULT_FECHA     = P_REG.CLIE_LECT_ULT_FECHA,
                CLIE_LECT_ULT_ESTADO    = P_REG.CLIE_LECT_ULT_ESTADO,
                ACU_SRV_ESTADO          = P_REG.ACU_SRV_ESTADO,
                CLIE_FASES              = P_REG.CLIE_FASES,
                CLIE_GESTOR_NOMBRE      = P_REG.CLIE_GESTOR_NOMBRE,
                CLIE_GESTOR_TELEFONO    = P_REG.CLIE_GESTOR_TELEFONO,
                OFCO_ID                 = P_REG.OFCO_ID,
                TIAS_ID                 = P_REG.TIAS_ID,
                TENS_ID                 = P_REG.TENS_ID,
                TARI_ID                 = P_REG.TARI_ID,
                TARIFA_ENRE             = P_REG.TARIFA_ENRE,
                CLIE_NEXUS_ID           = P_REG.CLIE_NEXUS_ID,
                CLIE_COMERCIAL_ALTA     = P_REG.CLIE_COMERCIAL_ALTA,
                CLIE_COMERCIAL_BAJA     = P_REG.CLIE_COMERCIAL_BAJA,
                N3F_F_ULT_INSPEC        = P_REG.N3F_F_ULT_INSPEC,
                N3F_ULT_INSPEC          = P_REG.N3F_ULT_INSPEC,
                F_MODIF                 = TRUNC(SYSDATE),
                F_BAJA                  = P_REG.F_BAJA
        WHERE ID = P_REG.ID;
      EXCEPTION
        WHEN OTHERS THEN
            INSERTAR_ERROR(P_ID_ERROR,
                          'UPDATE_CLIENTE',
                          'utc.CLIENTES.ID',
                          P_REG.ID,
                          'Error actualizando UTC.Clientes - '||sqlerrm);
            p_mensaje := 'Error actualizando UTC.Clientes - '||SQLERRM;
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*----------------------  Ingresa UTC.CLIENTES   ---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

PROCEDURE INSERT_CLIENTE (P_ID_ERROR IN NUMBER,
                            P_REG      IN UTC.CLIENTES%ROWTYPE,
                          P_MENSAJE  IN OUT VARCHAR2) IS
    BEGIN
        P_MENSAJE := 'OK';
        INSERT INTO UTC.CLIENTES (ID,               CLIE_ID,                        CLIE_APYNOM,                    CAL_CAL_IDENTIFICADOR,
                    STREETID,                       CLIE_CALLE_NUM,                 CLIE_DOMICILIO_PISO,            CLIE_DOMICILIO_DEPTO,
                    CLIE_POSTAL_COD,                CLIE_LOCALIDAD,                 CLIE_PARTIDO,                   ZONA_ID,
                    CLIE_TELEFONO,                  TDOC_ID,                        CLIE_DOCUM_NUM,                 CICL_ID,
                    RUTA_ID,                        ACTI_ID,                        CLIE_POT_CONV_PTA,              CLIE_POT_CONV_FPTA,
                    CLIE_TRATO_ESPECIAL,            TMED_ID,                        CLIE_MEDIDOR_NUM,               CLIE_LECT_ULT_FECHA,
                    CLIE_LECT_ULT_ESTADO,           ACU_SRV_ESTADO,                 CLIE_FASES,                     CLIE_GESTOR_NOMBRE,
                    CLIE_GESTOR_TELEFONO,           OFCO_ID,                        TIAS_ID,                        TENS_ID,
                    TARI_ID,                        CLIE_NEXUS_ID,                  CLIE_COMERCIAL_ALTA,            CLIE_COMERCIAL_BAJA,
                    N3F_F_ULT_INSPEC,               N3F_ULT_INSPEC,                 F_MODIF,                        F_BAJA,
                    CUENTA_BIG,                     TARIFA_ENRE,                    CLIE_CALLE,                     CLIE_ENTRE_CALLE1,
                    CLIE_ENTRE_CALLE2,                SEGMENTO)
             VALUES (P_REG.ID,                      P_REG.CLIE_ID,                  P_REG.CLIE_APYNOM,              P_REG.CAL_CAL_IDENTIFICADOR,
                    P_REG.STREETID,                 P_REG.CLIE_CALLE_NUM,           P_REG.CLIE_DOMICILIO_PISO,      P_REG.CLIE_DOMICILIO_DEPTO,
                    P_REG.CLIE_POSTAL_COD,          P_REG.CLIE_LOCALIDAD,           P_REG.CLIE_PARTIDO,             P_REG.ZONA_ID,
                    P_REG.CLIE_TELEFONO,            P_REG.TDOC_ID,                  P_REG.CLIE_DOCUM_NUM,           P_REG.CICL_ID,
                    P_REG.RUTA_ID,                  P_REG.ACTI_ID,                  P_REG.CLIE_POT_CONV_PTA,        P_REG.CLIE_POT_CONV_FPTA,
                    P_REG.CLIE_TRATO_ESPECIAL,      P_REG.TMED_ID,                  P_REG.CLIE_MEDIDOR_NUM,         P_REG.CLIE_LECT_ULT_FECHA,
                    P_REG.CLIE_LECT_ULT_ESTADO,     P_REG.ACU_SRV_ESTADO,           P_REG.CLIE_FASES,               P_REG.CLIE_GESTOR_NOMBRE,
                    P_REG.CLIE_GESTOR_TELEFONO,     P_REG.OFCO_ID,                  P_REG.TIAS_ID,                  P_REG.TENS_ID,
                    P_REG.TARI_ID,                  P_REG.CLIE_NEXUS_ID,            P_REG.CLIE_COMERCIAL_ALTA,      P_REG.CLIE_COMERCIAL_BAJA,
                    P_REG.N3F_F_ULT_INSPEC,         P_REG.N3F_ULT_INSPEC,           P_REG.F_MODIF,                  P_REG.F_BAJA,
                    P_REG.CUENTA_BIG,               P_REG.TARIFA_ENRE,              P_REG.CLIE_CALLE,               P_REG.CLIE_ENTRE_CALLE1,
                    P_REG.CLIE_ENTRE_CALLE2,        'A') ;
      EXCEPTION
        WHEN OTHERS THEN
            INSERTAR_ERROR(P_ID_ERROR,
                          'INSERT_CLIENTE',
                          'utc.CLIENTES.CLIE_ID',
                           P_REG.CLIE_ID,
                          'Error Insertando UTC.Clientes - '||sqlerrm);
            p_mensaje := 'Error Insertando UTC.Clientes - '||SQLERRM;
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

FUNCTION BUSCA_ID (P_ID_ERROR IN NUMBER,
                   P_TABLA    IN VARCHAR2,
                   P_CAMPO    IN VARCHAR2,
                   P_VALOR    IN VARCHAR2) RETURN NUMBER IS

    TYPE type_cursor IS REF CURSOR;
         v_cursor type_cursor;
         v_sql VARCHAR2(1000);
         v_ID NUMBER(9) := 0;

    -- PL/SQL Block
    BEGIN
        v_sql := ' select ID from '||P_TABLA||' where '||P_CAMPO||'='''||P_VALOR||'''';
        OPEN v_cursor FOR v_sql;
        LOOP
            FETCH v_cursor
             INTO v_id;
             EXIT WHEN v_cursor%NOTFOUND;
        END LOOP;
        CLOSE v_cursor;

        RETURN(v_id);

      EXCEPTION
        WHEN OTHERS THEN
            INSERTAR_ERROR(P_ID_ERROR,
                           'BUSCA_ID',
                            v_sql,
                            P_VALOR,
                            'Error buscando ID - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*------------------- borra  UTC_CLIENTES_DIA   ---------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

PROCEDURE DELETE_CLIENTE_DIA (P_ID_ERROR IN NUMBER,
                              P_CLIE_ID  IN UTC.UTC_CLIENTES_DIA.CLIE_ID%TYPE,
                              P_MENSAJE  IN OUT VARCHAR2) IS
BEGIN
                P_MENSAJE := 'OK';
                DELETE UTC.UTC_CLIENTES_DIA  WHERE CLIE_ID = P_CLIE_ID;

EXCEPTION
WHEN OTHERS THEN
      INSERTAR_ERROR(P_ID_ERROR,'DELETE_CLIENTE_DIA','UTC.UTC_CLIENTES_DIA.CLIE_ID',P_CLIE_ID, 'Error Borrando UTC_CLIENTES_DIA - '||sqlerrm);
      p_mensaje := 'Error Borrando UTC_CLIENTES_DIA - '||SQLERRM;
END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*------------------------------- Prepara ID   -------------------------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

FUNCTION PREPARA_ID (P_ID_ERROR IN NUMBER,
                     P_IDENT    IN UTC.CLIENTES.CUENTA_BIG%TYPE,
                     P_MENSAJE  IN OUT VARCHAR2) RETURN NUMBER IS

    V_ID  UTC.CLIENTES.ID%TYPE := 0;

    BEGIN
                P_MENSAJE := 'OK';
                BEGIN
                    SELECT UTC.C123_SEQ.NEXTVAL INTO V_ID FROM dual ;
                EXCEPTION
                 WHEN OTHERS THEN
                      INSERTAR_ERROR(P_ID_ERROR,'PREPARA_ID','UTC.C123_SEQ', P_IDENT, 'Error Obteniendo Secuencia - '||sqlerrm);
                      p_mensaje := 'Error Obteniendo Secuencia - '||SQLERRM;
                END;

                RETURN V_ID;

      EXCEPTION
        WHEN OTHERS THEN
            INSERTAR_ERROR(P_ID_ERROR,'PREPARA_ID','UTC.CLIENTES.CUENTA_BIG',P_IDENT, 'Error Buscando ID - '||sqlerrm);
                  p_mensaje := 'Error Buscando ID - '||SQLERRM;
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/*------------------------------- FILTROS   SE PASÃ? AL  TRIGGER BI DE UTC.CLIENTES ---------------------------*/
/* OK ---------------------------------------------------------------------------------------------------------------------------------*/

FUNCTION VERIFICA_FILTROS (P_ID_ERROR IN NUMBER,
                           P_REG      IN UTC.CLIENTES%ROWTYPE,
                           P_MENSAJE  IN OUT VARCHAR2) RETURN BOOLEAN IS

    V_AUX  UTC.ESTRUC_TARIFARIA.TARI_FILTRO%TYPE := 0;
    V_OUT BOOLEAN := TRUE;

    BEGIN
                P_MENSAJE := 'OK';
                BEGIN
                   SELECT TARI_FILTRO INTO V_AUX FROM UTC.ESTRUC_TARIFARIA where ID = P_REG.TARI_ID;
                   IF (V_AUX IS NOT NULL) THEN
                      P_MENSAJE := 'NOT INSERT';
                      V_OUT := FALSE;
                   END IF;

                EXCEPTION
                 WHEN OTHERS THEN
                      INSERTAR_ERROR(P_ID_ERROR,'VERIFICA_FILTRO','UTC.ESTRUC_TARIFARIA.ID',P_REG.TARI_ID, 'Error Buscando TARI_FILTRO - '||sqlerrm);
                      p_mensaje := 'Error Buscando TARI_FILTRO - '||SQLERRM;
                END;

                RETURN V_OUT;

      EXCEPTION
        WHEN OTHERS THEN
            INSERTAR_ERROR(P_ID_ERROR,'VERIFICA_FILTRO','UTC.ESTRUC_TARIFARIA.ID',P_REG.TARI_ID, 'Error Buscando TARI_FILTRO - '||sqlerrm);
                      p_mensaje := 'Error Buscando TARI_FILTRO - '||SQLERRM;
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/*-------------------------------------------------------------------------------------------------*/
/*-------------------------  EL PROCESO DE CUENTAS  ---------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/


PROCEDURE ACT_CLIENTES (P_ID_ERROR IN NUMBER) IS

    V_MENSAJE VARCHAR2(200);
    V_REG UTC.CLIENTES%ROWTYPE;
    V_CANT NUMBER(9) := 0;

    CURSOR cur_clientes_from_ccnb IS
     SELECT ID_EJECUCION,          CLIE_ID,                ACTI_COD,               CLIE_SECUENCIA,
           CLIE_APYNOM,            CLIE_CONEXION_ALTA,     CLIE_CONEXION_BAJA,     CLIE_CALLE_NUM,
           CLIE_MEDIDOR_NUM,       TIPO_MEDIDOR,           CLIE_TELEFONO,          CLIE_LECT_ULT_ESTADO,
           CLIE_LECT_ULT_FECHA,    CLIE_CONSUMO_PROM,      CLIE_POT_CONV_PTA,      ACU_SRV_ESTADO,
           CLIE_DOMICILIO_PISO,    CLIE_DOMICILIO_DEPTO,   CLIE_LOCALIDAD,         CLIE_PARTIDO,
           CICL_COD,               RUTA_COD,               CLIE_ENTRE_CALLE1,      CLIE_ENTRE_CALLE2,
           CLIE_POSTAL_COD,        TDOC_COD,               CLIE_DOCUM_NUM,         TENS_COD,
           OFCO_COD,               TARI_COD,               CLIE_FASES,             CLIE_GABINETE,
           CLIE_NEXUS_ID,          CLIE_TRATO_ESPECIAL,    CLIE_COMERCIAL_ALTA,    CLIE_COMERCIAL_BAJA,
           CLIE_CTA_NO_MED,        CLIE_POT_CONV_FPTA,     CLIE_GESTOR_NOMBRE,     CLIE_GESTOR_TELEFONO,
           CLIE_DIFERENTE,         CUENTA_BIG,             TIPO_AS,                ZONA_COD,
           TARIFA,                 TENSION_FACT,           CLIE_CALLE,             CLIE_ENTRE_CALLE1 ce1,
           CLIE_ENTRE_CALLE2 ce2
      FROM utc.utc_clientes_dia
     WHERE ID_EJECUCION = (SELECT MAX(ID_EJECUCION) FROM utc.utc_clientes_dia)
     ORDER BY CLIE_ID;

    BEGIN

    FOR reg_cliente IN cur_clientes_from_ccnb LOOP
        BEGIN
           V_REG.CLIE_ID                 := reg_cliente.CLIE_ID;
           V_REG.CLIE_APYNOM             := substr(reg_cliente.CLIE_APYNOM,1,70);
           V_REG.CLIE_CALLE              := reg_cliente.CLIE_CALLE;
           V_REG.CLIE_ENTRE_CALLE1       := reg_cliente.ce1;
           V_REG.CLIE_ENTRE_CALLE2       := reg_cliente.ce2;
           V_REG.CLIE_CALLE_NUM          := reg_cliente.CLIE_CALLE_NUM;
           V_REG.CLIE_DOMICILIO_PISO     := reg_cliente.CLIE_DOMICILIO_PISO;
           V_REG.CLIE_DOMICILIO_DEPTO    := reg_cliente.CLIE_DOMICILIO_DEPTO;
           V_REG.CLIE_POSTAL_COD         := reg_cliente.CLIE_POSTAL_COD;
           V_REG.CLIE_LOCALIDAD          := reg_cliente.CLIE_LOCALIDAD;
           V_REG.CLIE_PARTIDO            := reg_cliente.CLIE_PARTIDO;
           V_REG.ZONA_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.zonas'           ,'ZONA_SAP',reg_cliente.ZONA_COD);
           V_REG.CLIE_TELEFONO           := reg_cliente.CLIE_TELEFONO;
           V_REG.TDOC_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.tipos_docum'     ,'TDOC_COD',reg_cliente.TDOC_COD);
           V_REG.CLIE_DOCUM_NUM          := reg_cliente.CLIE_DOCUM_NUM;
           V_REG.CICL_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.ciclos'          ,'CICL_COD',reg_cliente.CICL_COD);
           V_REG.RUTA_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.rutas'           ,'RUTA_COD',reg_cliente.RUTA_COD);
           V_REG.ACTI_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.actividades'     ,'ACTI_COD',reg_cliente.ACTI_COD);
           V_REG.CLIE_POT_CONV_PTA       := reg_cliente.CLIE_POT_CONV_PTA;
           V_REG.CLIE_POT_CONV_FPTA      := reg_cliente.CLIE_POT_CONV_FPTA;
           V_REG.CLIE_TRATO_ESPECIAL     := reg_cliente.CLIE_TRATO_ESPECIAL;
           V_REG.TMED_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.tipos_medidor'   ,'TIPO_MEDIDOR',reg_cliente.TIPO_MEDIDOR);
           V_REG.CLIE_MEDIDOR_NUM        := reg_cliente.CLIE_MEDIDOR_NUM;
           V_REG.CLIE_LECT_ULT_FECHA     := reg_cliente.CLIE_LECT_ULT_FECHA;
           V_REG.CLIE_LECT_ULT_ESTADO    := reg_cliente.CLIE_LECT_ULT_ESTADO;
           V_REG.ACU_SRV_ESTADO          := reg_cliente.ACU_SRV_ESTADO;
           V_REG.CLIE_FASES              := reg_cliente.CLIE_FASES;
           V_REG.CLIE_GESTOR_NOMBRE      := reg_cliente.CLIE_GESTOR_NOMBRE;
           V_REG.CLIE_GESTOR_TELEFONO    := reg_cliente.CLIE_GESTOR_TELEFONO;
           V_REG.OFCO_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.oficinas_com'    ,'OFCO_COD',reg_cliente.OFCO_COD);
           V_REG.TIAS_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.tipo_as'         ,'TIPO_AS' ,reg_cliente.TIPO_AS);
           V_REG.TENS_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.tensiones'       ,'TENS_COD',reg_cliente.TENS_COD);
           V_REG.TARI_ID                 := BUSCA_ID (reg_cliente.ID_EJECUCION,'utc.estruc_tarifaria','TARI_COD',reg_cliente.TARI_COD);
           V_REG.CLIE_NEXUS_ID           := reg_cliente.CLIE_NEXUS_ID;
           V_REG.CLIE_COMERCIAL_ALTA     := reg_cliente.CLIE_COMERCIAL_ALTA;
           V_REG.CLIE_COMERCIAL_BAJA     := reg_cliente.CLIE_COMERCIAL_BAJA;
           v_REG.F_MODIF                 := TRUNC(SYSDATE);
           V_REG.F_BAJA                  := reg_cliente.CLIE_COMERCIAL_BAJA;
           V_REG.CUENTA_BIG              := reg_cliente.CUENTA_BIG;

           IF (TRIM(reg_cliente.TARIFA) = '3' ) THEN
               V_REG.TARIFA_ENRE := TRIM(reg_cliente.TARIFA)||TRIM(reg_cliente.TENSION_FACT);
           ELSE
               V_REG.TARIFA_ENRE := TRIM(reg_cliente.TARIFA);
           END IF;

           BEGIN
                SELECT ID INTO V_REG.ID
                  FROM utc.clientes
                 where CLIE_ID = reg_cliente.CLIE_ID;

                UPDATE_CLIENTE (reg_cliente.ID_EJECUCION,V_REG,V_MENSAJE);
                V_CANT := V_CANT + 1;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_REG.ID := PREPARA_ID(reg_cliente.ID_EJECUCION,V_REG.CUENTA_BIG,V_MENSAJE);
                  IF V_MENSAJE= 'OK' THEN
                      IF (V_REG.ID > 0)  THEN
                         INSERT_CLIENTE (reg_cliente.ID_EJECUCION,V_REG,V_MENSAJE);
                         V_CANT := V_CANT + 1;
                      END IF;
                  END IF;
                WHEN OTHERS THEN
                   INSERTAR_ERROR(P_ID_ERROR,'ACT_CLIENTES','utc.clientes.CLIE_ID',reg_cliente.CLIE_ID, 'Error buscando ID - '||sqlerrm);
                   V_MENSAJE := 'Error buscando ID - '||sqlerrm;
           END;
           IF V_MENSAJE= 'OK' THEN
                           DELETE_CLIENTE_DIA (reg_cliente.ID_EJECUCION,reg_cliente.CLIE_ID,V_MENSAJE) ;
           END IF;
           IF (MOD(V_CANT, 2500) =  0)  THEN
                           COMMIT;
                           V_CANT := 0;
           END IF;

           EXCEPTION
            WHEN OTHERS THEN
                INSERTAR_ERROR(P_ID_ERROR,'ACT_CLIENTES','utc.clientes.CLIE_ID',reg_cliente.CLIE_ID, 'Error en CLIE_ID - '||sqlerrm);
                      V_MENSAJE := 'Error buscando ID - '||sqlerrm;
        END;
    END LOOP;
    COMMIT;

    EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         DBMS_OUTPUT.PUT_LINE('Error procesando clientes - '||sqlerrm);
    END;

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------------------------------------------------------------------*/
/*-------------------------  EL PROCESO PRINCIPAL  -----------------------------------*/
/* OK -------------------------------------------------------------------------------------------*/

PROCEDURE MAIN_VOID IS

    V_ID_ERROR UTC.LOG_ERRORES.ID_ERROR%TYPE := TO_NUMBER(TO_CHAR(SYSDATE,'YYMMDDHHMI'));

    BEGIN

        ACTUALIZAR_AUXILIARES (V_ID_ERROR);
        ACT_CLIENTES (V_ID_ERROR);

    EXCEPTION
         WHEN OTHERS THEN
             ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Error procesando MAIN_VOID - '||sqlerrm);
    END;


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

FUNCTION  DEPURA_UTC_NOV(P_MENSAJE IN OUT VARCHAR2) RETURN BOOLEAN IS

    v_cal_cal_new UTC.CALLES_GIS.cal_cal_new%type;

    BEGIN
        /* Para las novedades procesadas correctamente
                   Se  realiza  la actualizacisn del campo STREETID,
                   Si la actualizacisn es correcta, se elimina el registro de UTC_NOVEDADES */

          FOR reg IN (SELECT ident, streetid
                        FROM UTC_NOVEDADES
                       WHERE TRUNC(FECHA_ALTA) <= TRUNC(SYSDATE - 6)
                         AND NVL(LOGID,0)      <> 0  --procesado
                         AND NVL(STATUSID,0) IN (0)  --procesado sin error
                      ) LOOP

                BEGIN
                    BEGIN
                        SELECT cal_cal_new
                          INTO v_cal_cal_new
                          FROM calles_gis
                         WHERE street_id = reg.streetid;
                    EXCEPTION
                         WHEN OTHERS THEN
                          v_cal_cal_new := NULL;
                    END;

                    UPDATE clientes
                       SET streetid = reg.streetid,
                           cal_cal_identificador = v_cal_cal_new
                     WHERE clie_id = reg.ident;

                    BEGIN
                        DELETE utc_novedades
                         WHERE ident = reg.ident;
                        EXCEPTION
                          WHEN OTHERS THEN
                             p_mensaje := 'Error al BORRAR UTC_NOVEDADES: '||SQLERRM;
                                  RETURN(FALSE);
                    END;

                EXCEPTION
                      WHEN OTHERS THEN
                          p_mensaje := 'Error al ACTUALIZAR STREETID EN CLIENTES: '||SQLERRM;
                              RETURN(FALSE);
                END;

          END LOOP;
          COMMIT;
        RETURN(TRUE);
    END;
END  Pck_CCnB_Utc;

/