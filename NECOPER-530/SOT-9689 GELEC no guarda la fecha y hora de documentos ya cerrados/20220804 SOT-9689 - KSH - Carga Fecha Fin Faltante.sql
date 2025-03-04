DECLARE
    
    V_LAST_IDDOC        GELEC.ED_DOCUMENTOS.ID_DOCUMENTO%TYPE:='';
    
BEGIN
    --RECORRO CADA CUENTA PARA ACTUALIZAR
    FOR F IN (
          SELECT D.ID_DOCUMENTO, D.NRO_DOCUMENTO, D.FECHA_INICIO_DOC, D.FECHA_FIN_DOC, C.ID_DOC_CLIENTE, C.CUENTA, C.FECHA_INICIO_CORTE, C.FECHA_FIN_CORTE, C.FECHA_FIN_EDITABLE
          FROM GELEC.ED_DOCUMENTOS D, GELEC.ED_DET_DOCUMENTOS_CLIENTES C
          WHERE D.ID_DOCUMENTO=C.ID_DOCUMENTO AND D.FECHA_FIN_DOC IS NOT NULL AND C.FECHA_FIN_CORTE IS NULL
          ORDER BY D.ID_DOCUMENTO, C.ID_DOC_CLIENTE
    ) LOOP
        --TOMO EL DOCUMENTO PARA AGRUPAR POR DOC
        IF V_LAST_IDDOC=F.ID_DOCUMENTO THEN
            NULL;
        ELSE
            DBMS_OUTPUT.PUT_LINE('--'||F.NRO_DOCUMENTO||'---------------------------------------------------------------------------------------------------------------------------------------------------------');
            V_LAST_IDDOC:=F.ID_DOCUMENTO;
        END IF;
        --MOSTRAMOS Y ACTUALIZAMOS
        DBMS_OUTPUT.PUT_LINE(F.ID_DOC_CLIENTE);
        DBMS_OUTPUT.PUT_LINE(F.ID_DOCUMENTO||','||F.FECHA_INICIO_DOC||','||F.FECHA_FIN_DOC||','||F.ID_DOC_CLIENTE||','||F.CUENTA||','||F.FECHA_INICIO_CORTE||','||F.FECHA_FIN_CORTE||','||F.FECHA_FIN_EDITABLE);
        --
        UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES SET FECHA_FIN_CORTE=F.FECHA_FIN_DOC WHERE ID_DOC_CLIENTE=F.ID_DOC_CLIENTE;
        -- SI FECHA FIN MANUAL ES NULA ACTUALIZO TAMBIEN
        IF F.FECHA_FIN_EDITABLE IS NULL THEN
            UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES SET FECHA_FIN_EDITABLE=F.FECHA_FIN_DOC WHERE ID_DOC_CLIENTE=F.ID_DOC_CLIENTE;
        END IF;
        --BUSCO EL ID_DOC_CLIENTE Y LO MUESTRO
        FOR CL IN (
            SELECT D.ID_DOCUMENTO, D.NRO_DOCUMENTO, D.FECHA_INICIO_DOC, D.FECHA_FIN_DOC, C.ID_DOC_CLIENTE, C.CUENTA, C.FECHA_INICIO_CORTE, C.FECHA_FIN_CORTE, C.FECHA_FIN_EDITABLE
            FROM GELEC.ED_DOCUMENTOS D, GELEC.ED_DET_DOCUMENTOS_CLIENTES C
            WHERE D.ID_DOCUMENTO=C.ID_DOCUMENTO AND D.FECHA_FIN_DOC IS NOT NULL AND C.ID_DOC_CLIENTE=F.ID_DOC_CLIENTE 
            ORDER BY D.ID_DOCUMENTO, C.ID_DOC_CLIENTE
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(CL.ID_DOCUMENTO||','||CL.FECHA_INICIO_DOC||','||CL.FECHA_FIN_DOC||','||CL.ID_DOC_CLIENTE||','||CL.CUENTA||','||CL.FECHA_INICIO_CORTE||','||CL.FECHA_FIN_CORTE||','||CL.FECHA_FIN_EDITABLE);
        END LOOP;    

    END LOOP;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    
    COMMIT;
END;



--ROLLBACK;







