SET SERVEROUTPUT ON 
DECLARE

      /*******************************************************************
       * NOMBRE FUNCION: CIERRA_AUTO_DOCUMENTOS                          *
       * FECHA: 26/10/2022 RSLEIVA                                       *
       *                                                                 *
       * DESCRIPCION: AQUELLOS DOCUMENTOS PMT CON DURACION <10MIN        *
       *     SE APLICARA EL CIERRE AUTOMATICAMENTE.                      *
       *                                                                 *
       * PARAMETROS DE ENTRADA: N/A                                      *
       * PARAMETRO DE SALIDA: P_RESULTADO                                *
       * VALORES DE SALIDA                                               *
       *      % 0 NO HUBO CIERRES                                        *
       *      %>0 LA CANTIDAD DE DOCUMENTOS CERRADOS                     *
       *                                                                 *
       *******************************************************************/

    CURSOR C_DATOS IS (
        SELECT 
          ID_DOCUMENTO, 
          NRO_DOCUMENTO, 
          TIPO_CORTE, 
          FECHA_INICIO_DOC INI, 
          FECHA_FIN_DOC FIN, 
          LOG_HASTA, 
          TRUNC((FECHA_FIN_DOC - FECHA_INICIO_DOC)) DIFERENCIA_DIAS,
          TRUNC(MOD((FECHA_FIN_DOC - FECHA_INICIO_DOC) * 24, 24)) DIFERENCIA_HORAS,
          TRUNC(MOD((FECHA_FIN_DOC - FECHA_INICIO_DOC) * (60 * 24), 60)) DIFERENCIA_MINUTOS,
          TRUNC(MOD((FECHA_FIN_DOC - FECHA_INICIO_DOC) * (60 * 60 * 24), 60)) DIFERENCIA_SEGUNDOS
        FROM 
          gelec.ed_documentos 
        WHERE 
          TIPO_CORTE IN ('Programado MT')
          AND FECHA_FIN_DOC IS NOT NULL 
          AND LOG_HASTA IS NULL 
          AND TRUNC((FECHA_FIN_DOC - FECHA_INICIO_DOC))=0
          AND TRUNC(MOD((FECHA_FIN_DOC - FECHA_INICIO_DOC) * 24, 24))=0
          AND TRUNC(MOD((FECHA_FIN_DOC - FECHA_INICIO_DOC) * (60 * 24), 60))<=10
    );

    V_CONT NUMBER:=0;
    V_RESULTADO VARCHAR2(100);
BEGIN
    FOR F_DATOS IN C_DATOS LOOP
        BEGIN
            PKG_OTROS.DELETE_LOGICO_DOCUMENTO (  
                F_DATOS.ID_DOCUMENTO,
                'Aplicacion',
                V_RESULTADO) ;  
            --  
            DBMS_OUTPUT.PUT_LINE(V_RESULTADO);
            V_CONT:=V_CONT+1;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('El Documento '||F_DATOS.NRO_DOCUMENTO||' no pudo cerrarse automaticamente');
        END;      
    END LOOP;
    
END; 
