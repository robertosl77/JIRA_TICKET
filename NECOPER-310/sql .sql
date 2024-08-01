set serveroutput on
DECLARE
/*
  --P_RESULTADO                OUT NUMBER;
*/  
  P_USUARIO                    VARCHAR2(30):='rsleiva2';
  P_SOLUCION_PROVISORIA        VARCHAR2(30):='Autonomia';
  P_ESTADO_CLIE                VARCHAR2(30):='con suministro';  
  P_CUENTA                     VARCHAR2(10):='8913735327';
  P_ID_DOCUMENTO               NUMBER:=9084671;
  P_FECHA_FIN_EDITABLE         DATE:=TO_DATE ('2022-01-01', 'YYYY-MM-DD');

      V_ID_DOC_CLIENTE                 NUMBER (10);
      V_ESTADO_CLIE_ACT                VARCHAR2 (30);
      V_SOLUCION_PROVISORIA_ACT        VARCHAR2 (30);
      V_ID_AUDITORIA                   NUMBER;
      V_RESULTADO                      NUMBER (1);
      V_FECHA_FIN_EDITABLE_ACT         DATE;
      V_FECHA_FIN_EDITABLE_INGRESADA   DATE;
   BEGIN
      --busca los datos actuales de la cuenta
      SELECT ID_DOC_CLIENTE, ESTADO_CLIE, SOLUCION_PROVISORIA, DC.FECHA_FIN_EDITABLE
      INTO V_ID_DOC_CLIENTE, V_ESTADO_CLIE_ACT, V_SOLUCION_PROVISORIA_ACT, V_FECHA_FIN_EDITABLE_ACT
      FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
      WHERE     ID_DOCUMENTO = P_ID_DOCUMENTO
          AND CUENTA = P_CUENTA
          AND LOG_HASTA IS NULL;

      --toma la fecha de fin y la deja por defecto, si corresponde mas adelante se aplicara null o sysdate
      V_FECHA_FIN_EDITABLE_INGRESADA := P_FECHA_FIN_EDITABLE;

      -- Si el usuario pone estado normalizado o con suministro automaticamente pongo fecha fin editable
      IF     (   UPPER (NVL (P_ESTADO_CLIE, '')) = 'NORMALIZADO'
              OR UPPER (NVL (P_ESTADO_CLIE, '')) = 'CON SUMINISTRO')
         AND V_FECHA_FIN_EDITABLE_ACT IS NULL
         AND P_FECHA_FIN_EDITABLE IS NULL
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := SYSDATE;
         dbms_output.put_line('A');
      END IF;

      -- Si el usuario pone un estado diferente a normalizado o con suministro, pongo fecha de fin en null
      IF (    UPPER (NVL (P_ESTADO_CLIE, '')) != 'NORMALIZADO'
          AND UPPER (NVL (P_ESTADO_CLIE, '')) != 'CON SUMINISTRO')
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := NULL;
         dbms_output.put_line('B');
      END IF;

      -- Cubro el caso de que cambie de normalizado a con suministro o viceversa
      IF     UPPER (NVL (P_ESTADO_CLIE, '')) IN
                ('NORMALIZADO', 'CON SUMINISTRO')
         AND V_FECHA_FIN_EDITABLE_INGRESADA IS NULL
      THEN
         V_FECHA_FIN_EDITABLE_INGRESADA := V_FECHA_FIN_EDITABLE_ACT;
         dbms_output.put_line('C');
      END IF;

      IF  V_ESTADO_CLIE_ACT != P_ESTADO_CLIE 
          OR NVL (V_SOLUCION_PROVISORIA_ACT, ' ') != NVL (P_SOLUCION_PROVISORIA, ' ') 
          OR NVL (V_FECHA_FIN_EDITABLE_ACT, TO_DATE ('1901-01-01', 'YYYY-MM-DD')) != NVL (V_FECHA_FIN_EDITABLE_INGRESADA,TO_DATE ('1901-01-01', 'YYYY-MM-DD'))
      THEN
          dbms_output.put_line('D');
          
           UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
              SET ESTADO_CLIE = NVL (P_ESTADO_CLIE, V_ESTADO_CLIE_ACT),
                  SOLUCION_PROVISORIA = NVL (P_SOLUCION_PROVISORIA, V_SOLUCION_PROVISORIA_ACT),
                  DC.FECHA_FIN_EDITABLE = V_FECHA_FIN_EDITABLE_INGRESADA,
                  OPERACION = 'M',
                  USUARIO = P_USUARIO,
                  ultima_modificacion = SYSDATE
            WHERE ID_DOC_CLIENTE = V_ID_DOC_CLIENTE;
          
          --rollback;
          
      ELSE
         V_RESULTADO := 0;
          dbms_output.put_line('E');
      END IF;

      --P_RESULTADO := V_RESULTADO;


   END;
   

   
/*
SELECT * FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES WHERE CUENTA='8913735327' AND id_documento=9084671;

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


*/
