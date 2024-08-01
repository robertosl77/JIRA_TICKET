SET SERVEROUTPUT ON
DECLARE

P_ORIGEN    GELEC.ED_CLIENTES.CUENTA%TYPE:='0370730501';
P_DESTINO   GELEC.ED_CLIENTES.CUENTA%TYPE:='8655839590';
P_RESULTADO VARCHAR(20);
V_CANT NUMBER;
P_USUARIO   GELEC.ED_LOG.USUARIO%TYPE:='rsleiva*';
V_LOG   NUMBER;

BEGIN

      V_LOG :=
         GELEC.INSERT_LOG (
               'Muda cuenta origen: '
            || P_ORIGEN
            || ' a cuenta destino: '
            || P_DESTINO,
            P_USUARIO);
            
            
    FOR P IN (
            SELECT DISTINCT DNI FROM GELEC.ED_PACIENTE_CLIENTE
            WHERE 
                CUENTA= P_ORIGEN
                AND LOG_HASTA IS NULL
    ) LOOP
        
        DBMS_OUTPUT.PUT_LINE(P.DNI);
        DBMS_OUTPUT.PUT_LINE(V_LOG);
        GELEC.PKG_PACIENTES.B_PACIENTE (
                                P_ORIGEN,
                                P.DNI,
                                V_LOG,
                                P_RESULTADO) ;  
    END LOOP;          


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Sin Telefono para migrar');
END;

