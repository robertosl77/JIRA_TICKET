SET SERVEROUTPUT ON
DECLARE

P_ORIGEN    GELEC.ED_CLIENTES.CUENTA%TYPE:='3883479936';
P_DESTINO   GELEC.ED_CLIENTES.CUENTA%TYPE:='8655839590';
P_RESULTADO VARCHAR(20);

BEGIN
  
    FOR TEL IN ( 
                SELECT DISTINCT UPPER(NVL(CC.NOMBRE,'MIGRADO')) NOMBRE, CC.TELEFONO, CC.TIPO_CONTACTO
                FROM GELEC.ED_CONTACTOS_CLIENTES CC
                WHERE 
                    CUENTA=P_ORIGEN
                    AND NVL(CC.LOG_HASTA,0)=0
                    AND CC.TIPO_CONTACTO='Celular'
                    AND (SELECT COUNT(1) FROM GELEC.ED_NOTAS WHERE CUENTA=CC.CUENTA AND IDDESTINO=CC.ID_TEL AND EFECTIVO>0)>0   --Filtra los que no tengan efectividad
                    AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA=P_DESTINO AND TELEFONO=CC.TELEFONO)=0    --Filtra los que ya esten cargados en destino
    ) LOOP
    
          DBMS_OUTPUT.PUT_LINE(P_ORIGEN||','||P_DESTINO||','||TEL.NOMBRE||','||TEL.TELEFONO||','||TEL.TIPO_CONTACTO);
          
          GELEC.PKG_OTROS.INSERTA_TELEFONO (  
                                        'DA DE ALTA EL CONTACTO DE UNA CUENTA',
                                        'Migracion',
                                        P_DESTINO,
                                        TEL.NOMBRE,
                                        TEL.TELEFONO,
                                        TEL.TIPO_CONTACTO,
                                        P_RESULTADO);    
                                  
          DBMS_OUTPUT.PUT_LINE(P_RESULTADO);                        
    
    END LOOP;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Sin Telefono para migrar');
END;