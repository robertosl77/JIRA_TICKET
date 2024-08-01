create or replace 
FUNCTION       CANTIDAD_LLAMADAS (P_FECHA   IN VARCHAR2,
                                                    P_TIPO    IN VARCHAR2)
   RETURN NUMBER
AS
   v_cant   NUMBER;
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   IF (P_FECHA IS NOT NULL)
   THEN
      SELECT COUNT (*)
        INTO v_cant
        FROM GELEC.ED_NOTAS n
             INNER JOIN GELEC.ED_CLIENTE_NOTA cn ON cn.ID_NOTA = n.ID_NOTA
             INNER JOIN GELEC.ED_DOCUMENTOS d
                ON d.ID_DOCUMENTO = cn.ID_DOCUMENTO
       WHERE     n.EFECTIVO IS NOT NULL
             AND n.ID_TIPO_NOTA = 4
             AND TO_CHAR (d.fecha_inicio_doc, 'dd/mm/yyyy') = p_fecha
             AND d.TIPO_CORTE = p_tipo;
   ELSE
      SELECT COUNT (*)
        INTO v_cant
        FROM GELEC.ED_NOTAS n
             INNER JOIN GELEC.ED_CLIENTE_NOTA cn ON cn.ID_NOTA = n.ID_NOTA
             INNER JOIN GELEC.ED_DOCUMENTOS d
                ON d.ID_DOCUMENTO = cn.ID_DOCUMENTO
       WHERE     n.EFECTIVO IS NOT NULL
             AND n.ID_TIPO_NOTA = 4
             AND d.FECHA_INICIO_DOC BETWEEN TRUNC (SYSDATE - 7)
                                        AND TRUNC (SYSDATE + 1)
             AND d.TIPO_CORTE = p_tipo;
   END IF;

   RETURN v_cant;
END CANTIDAD_LLAMADAS;