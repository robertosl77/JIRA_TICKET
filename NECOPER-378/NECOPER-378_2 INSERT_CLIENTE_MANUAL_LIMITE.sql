create or replace 
PROCEDURE       INSERT_CLIENTE_MANUAL_LIMITE ( 
                                            P_CUENTA        IN     VARCHAR2,
                                            P_USUARIO       IN     VARCHAR2,
                                            P_Resultado     OUT VARCHAR2 )
IS
   /*******************************************************************/
   /* Nombre Funcion: Insert_CLiente_Manual_Limite                    */
   /* Fecha: 19/12/2022 RSLEIVA                                       */
   /*                                                                 */
   /* Descripcion: Posterior a insertar un cliente manual,            */
   /*      el proceso tambien insertara en la tabla                   */
   /*      gelec.ed_clientes_manuales para indicar hasta que fecha    */
   /*      permanecera activo dicho cliente en GELEC                  */
   /*                                                                 */
   /* Constantes:                                                     */
   /*          V_MESES (dias de aplazo)                               */
   /*                                                                 */
   /* Variables:                                                      */
   /*          V_LIMITE (fecha limite para mantener al cliente)       */
   /*                                                                 */
   /* Parametros de Entrada:                                          */
   /*          P_CUENTA (numero del cliente a insertar)               */
   /*          P_USUARIO (usuario que realiza el insert)              */
   /*                                                                 */
   /* Parametro de Salida: P_Resultado                                */
   /*                                                                 */
   /* Valores de Salida                                               */
   /*      % OK                                                       */
   /*      % Es cliente EDP                                           */
   /*      % Cliente Existe con fecha activa                          */
   /*      % No Se Encontro Cliente en NEXUS                          */
   /*      % Error al obtener fecha limite                            */
   /*      % Error al insertar fecha limite                           */
   /*                                                                 */
   /*******************************************************************/

  --variables de limite
  V_MESES     NUMBER:=3;
  V_LIMITE    DATE;
  --variables de control
  V_ESNEXUS   NUMBER;
  V_ESEDP     NUMBER;
  V_ESACTIVO  NUMBER;
  --variable de log
  V_LOG       NUMBER;

BEGIN
    --se intenta obtener la fecha limite con una constante de 30 dias
    BEGIN
        SELECT ADD_MONTHS(SYSDATE, V_MESES) AS FECHA_LIMITE INTO V_LIMITE FROM DUAL;
        DBMS_OUTPUT.PUT_LINE('Se establecio como fecha limite el '||V_LIMITE);
    EXCEPTION
        WHEN OTHERS THEN
            V_LIMITE:=NULL;
            P_Resultado:= 'Error al obtener fecha limite';
            DBMS_OUTPUT.PUT_LINE('Se genero un error al obtener una fecha limite');
    END;
    
    --se verifica que la cuenta exista 
    --se verifica si es edp    
    --se verifica que la cuenta no este insertada en la tabla y este activa
    IF V_LIMITE IS NOT NULL THEN
        SELECT 
            (SELECT COUNT(1) FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=P_CUENTA AND LOGIDTO=0) EXISTE, 
            (SELECT COUNT(1) FROM NEXUS_GIS.SPRCLIENTS WHERE FSCLIENTID=P_CUENTA AND LOGIDTO=0 AND CUSTATT16='1A' AND CUSTATT21=12521) ESEDP,
            (SELECT COUNT(1) FROM GELEC.ED_CLIENTES_MANUALES WHERE CUENTA=P_CUENTA AND F_LIMITE>SYSDATE AND NVL(LOG_HASTA,0)=0) ESACTIVO
        INTO
            V_ESNEXUS,
            V_ESEDP,
            V_ESACTIVO
        FROM DUAL;
        
        --analizo resultados de la consulta 
        IF V_ESNEXUS=0 THEN
            P_RESULTADO:='No Se Encontro Cliente en NEXUS';
            DBMS_OUTPUT.PUT_LINE('Cuenta '||P_CUENTA||' no existe en Nexus');
        ELSIF V_ESEDP>0 THEN
            P_RESULTADO:='Es cliente EDP';
            DBMS_OUTPUT.PUT_LINE('Cuenta '||P_CUENTA||' corresponde a cliente Electrodependiente');
        ELSIF V_ESACTIVO>0 THEN
            P_RESULTADO:='Cliente Existe con fecha activa';
            DBMS_OUTPUT.PUT_LINE('Cuenta '||P_CUENTA||' esta insertada como cliente, y con fecha limite activa');
        ELSE
            --se busca el id desde
            begin
            V_LOG :=GELEC.INSERT_LOG (
                'Se inserta fecha limite para cliente manual [cuenta: '||P_CUENTA||', fecha:'||V_LIMITE||']',
                P_USUARIO);            
            exception
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('xxx');
            end;        
            
            --se inserta la fecha limite
            BEGIN
                INSERT INTO GELEC.ED_CLIENTES_MANUALES (
                                                        CUENTA, 
                                                        F_LIMITE, 
                                                        LOG_DESDE, 
                                                        LOG_HASTA)
                VALUES (
                    P_CUENTA, 
                    V_LIMITE, 
                    V_LOG, 
                    NULL
                );
                
				COMMIT;
                P_RESULTADO:='OK';
                
            EXCEPTION 
                WHEN OTHERS THEN
                    P_RESULTADO:='Error al insertar fecha limite';
                    DBMS_OUTPUT.PUT_LINE('Se produjo un error al insertar la fecha limite');
            END;
        END IF;
    END IF;
END INSERT_CLIENTE_MANUAL_LIMITE;