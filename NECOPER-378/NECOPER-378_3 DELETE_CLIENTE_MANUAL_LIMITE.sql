create or replace 
PROCEDURE       DELETE_CLIENTE_MANUAL_LIMITE ( 
                                            P_LOGID         IN     NUMBER,
                                            P_RESULTADO     OUT VARCHAR2 ) IS
                                            
   /*******************************************************************/
   /* Nombre Funcion: Delete_CLiente_Manual_Limite                    */
   /* Fecha: 21/12/2022 RSLEIVA                                       */
   /*                                                                 */
   /* Descripcion: Con el proceso que corre diariamente a las 8am     */
   /*   se analiza que cliente deja de ser EDP, se crea este proceso  */
   /*   para administrar dicha baja y de paso aplicar la baja a la    */
   /*   fecha limite.                                                 */
   /*                                                                 */
   /* Constantes:                                                     */
   /*                                                                 */
   /* Variables:                                                      */
   /*                                                                 */
   /* Parametros de Entrada:                                          */
   /*          P_LOGID (id para la baja de la fecha limite)           */
   /*                                                                 */
   /* Parametro de Salida:                                            */
   /*          P_RESULTADO                                            */
   /*                                                                 */
   /* Valores de Salida                                               */
   /*      % OK                                                       */
   /*      % ERROR                                                    */
   /*      % No se aplica baja                                        */
   /*                                                                 */
   /*                                                                 */
   /*                                                                 */
   /*                                                                 */
   /*                                                                 */
   /*******************************************************************/                                            

    cursor c_datos is 
        SELECT 
            C.CUENTA, 
            C.LOG_HASTA, 
            (SELECT LOGIDTO FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=C.CUENTA) LOGIDTO, 
            (SELECT CUSTATT16 FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=C.CUENTA) CUSTATT16, 
            (SELECT CUSTATT21 FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=C.CUENTA) CUSTATT21
            ,     (SELECT F_LIMITE FROM GELEC.ED_CLIENTES_MANUALES WHERE CUENTA=C.CUENTA) F_LIMITE
            ,     (SELECT LOG_HASTA FROM GELEC.ED_CLIENTES_MANUALES WHERE CUENTA=C.CUENTA) LOG_HASTA_LIMITE
            ,    (SELECT TRIM(ESTADO) FROM NEXUS_CCYB.CLIENTES_CCYB WHERE CUENTA = C.CUENTA) ESTADO_CCYB
        FROM GELEC.ED_CLIENTES C 
        WHERE 
            NVL(C.LOG_HASTA,0)=0 
            AND C.CUENTA NOT IN (SELECT FSCLIENTID FROM NEXUS_GIS.SPRCLIENTS WHERE LOGIDTO=0 AND CUSTATT16='1A' AND CUSTATT21=12521)
        ;
        
    V_BAJA_CLIENTES NUMBER;
    V_BAJA_LIMITES  NUMBER;

BEGIN

    FOR F_DATOS IN C_DATOS LOOP
        P_RESULTADO:=NULL;
        V_BAJA_CLIENTES:=0;
        V_BAJA_LIMITES:=0;
        DBMS_OUTPUT.PUT_LINE('cuenta: '||F_DATOS.CUENTA||'| gelec.log_hasta: '||NVL(F_DATOS.LOG_HASTA,-1)||'| nexus.logidto: '||F_DATOS.LOGIDTO||'| custatt16: '||F_DATOS.CUSTATT16||'| custatt21: '||F_DATOS.CUSTATT21||'| fecha_limite: '||F_DATOS.F_LIMITE||' log_hasta en limites: '||f_datos.log_hasta_limite||'| estado_ccyb: '||F_DATOS.ESTADO_CCYB);
        
        --APLICAMOS LAS BAJAS CORRESPONDIENTES    
        IF F_DATOS.F_LIMITE IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('>>No esta en Limites. Corresponde solo baja en GELEC.');
            V_BAJA_CLIENTES:=1;
            V_BAJA_LIMITES:=0;
        ELSIF F_DATOS.F_LIMITE IS NOT NULL THEN
            IF F_DATOS.LOG_HASTA_LIMITE IS NULL AND (F_DATOS.CUSTATT16='1A' AND F_DATOS.CUSTATT21=12521) THEN
                DBMS_OUTPUT.PUT_LINE('>>Esta en limites pero se recibio el alta como EDP. Solo se da de baja en limites');
                V_BAJA_CLIENTES:=0;
                V_BAJA_LIMITES:=1;                
            ELSIF F_DATOS.F_LIMITE>SYSDATE THEN
                DBMS_OUTPUT.PUT_LINE('>>Esta en limites pero la fecha esta activa. No se aplica baja');
                V_BAJA_CLIENTES:=0;
                V_BAJA_LIMITES:=0;
            ELSE
                DBMS_OUTPUT.PUT_LINE('>>Se aplica baja y se quita el limite');
                V_BAJA_CLIENTES:=1;
                V_BAJA_LIMITES:=1;               
            END IF;    
        END IF;
        
        --REALIZAMOS LAS ACCIONES
        IF V_BAJA_CLIENTES=1 THEN
            BEGIN
                UPDATE GELEC.ED_CLIENTES C SET C.LOG_HASTA = P_LOGID WHERE C.CUENTA=F_DATOS.CUENTA;
                P_RESULTADO:='OK';
            EXCEPTION
                WHEN OTHERS THEN
                    P_RESULTADO:='ERROR';
            END;            
        END IF;
        
        --APLICAMOS LA BAJA EN LIMITE
        IF V_BAJA_LIMITES=1 AND P_RESULTADO='OK' THEN
            BEGIN
                UPDATE GELEC.ED_CLIENTES_MANUALES SET LOG_HASTA=P_LOGID WHERE CUENTA=F_DATOS.CUENTA AND LOG_HASTA IS NULL;
                P_RESULTADO:='OK';
            EXCEPTION
                WHEN OTHERS THEN
                    P_RESULTADO:='ERROR';
            END;            
        END IF;
        
        --CONFIRMAMOS SI EL RESULTADO ES OK
        IF P_RESULTADO='OK' THEN
            COMMIT;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('P_RESULTADO: '||P_RESULTADO);    
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------------------');
    END LOOP;
    
END DELETE_CLIENTE_MANUAL_LIMITE;