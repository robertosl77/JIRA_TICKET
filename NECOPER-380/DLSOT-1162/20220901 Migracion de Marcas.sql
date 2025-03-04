SET SERVEROUTPUT ON
DECLARE

P_ORIGEN    GELEC.ED_CLIENTES.CUENTA%TYPE:='3883479936';
P_DESTINO   GELEC.ED_CLIENTES.CUENTA%TYPE:='8655839590';
P_RESULTADO VARCHAR(20);
V_CANT NUMBER;
P_USUARIO   GELEC.ED_LOG.USUARIO%TYPE:='rsleiva';

BEGIN
    --BAJA POTENCIAL
    SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
    WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=1;
    --
    IF V_CANT=0 THEN
        GELEC.PKG_OTROS.INSERTAR_MARCA (
            P_USUARIO, 1, 4,
            P_ORIGEN,
            '[Marca: Baja Potencial | Submarca: MIGRACION]',
            P_RESULTADO);  
    END IF;
    --CLIENTE MULTIPLE EN ORIGEN
    SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
    WHERE CUENTA=P_ORIGEN AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;
    --
    IF V_CANT=1 THEN
        --CLIENTE MULTIPLE EN DESTINO
        SELECT COUNT(1) MARCAS  INTO V_CANT FROM GELEC.ED_MARCA_CLIENTE 
        WHERE CUENTA=P_DESTINO AND NVL(LOG_HASTA,0)=0 AND ID_MARCA=9 AND ID_SUBMARCA=21;    
        --
        IF V_CANT=0 THEN
            GELEC.PKG_OTROS.INSERTAR_MARCA (
                P_USUARIO, 9, 21,
                P_DESTINO,
                '[Marca: Baja Potencial | Submarca: MIGRACION]',
                P_RESULTADO);  
        END IF;
    END IF;
          


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Sin Telefono para migrar');
END;