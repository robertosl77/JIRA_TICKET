SET SERVEROUTPUT ON
DECLARE

    V_LOGID        NUMBER;
    V_CUENTA       GELEC.ED_CLIENTES.CUENTA%TYPE:='7492815047';
    
BEGIN
    V_LOGID := GELEC.INSERT_LOG ('Inserta Cliente Manual', 'root');
    
    IF NVL(V_LOGID,0) =0 THEN
        NULL;
        DBMS_OUTPUT.PUT_LINE('No se genero un id log correcto');
    ELSE
        --select * from gelec.ed_clientes where cuenta='7492815047';
        UPDATE GELEC.ED_CLIENTES SET LOG_DESDE=V_LOGID WHERE CUENTA=V_CUENTA;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Se inserto en la cuenta '||V_CUENTA||' el log id '||V_LOGID);
    END IF;
END;
