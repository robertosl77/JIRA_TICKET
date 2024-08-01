SET SERVEROUTPUT ON

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
--            AND ROWNUM=1
    );
    
    P_RESULTADO NUMBER;
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
            IF P_RESULTADO>0 THEN
                DBMS_OUTPUT.PUT_LINE('Marca Insertada: '||F_DATOS.CUENTA);
            END IF;                
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Marca No Insertada: '||F_DATOS.CUENTA);
        END;
    END LOOP;
END;