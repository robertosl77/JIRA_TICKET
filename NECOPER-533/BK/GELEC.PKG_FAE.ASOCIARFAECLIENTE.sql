    PROCEDURE ASOCIARFAECLIENTE (
        P_ID_FAE_CLIENTE   IN    NUMBER,
        P_ID_FAE           IN    NUMBER,
        P_USUARIO          IN    VARCHAR2,
        P_RESPUESTA        OUT   NUMBER
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        V_LOG_ID NUMBER;
		
		--rsleiva 09/08/2022
		V_CUENTA GELEC.ED_CLIENTES.CUENTA%TYPE;
    V_MARCA NUMBER;
    V_RESULTADO VARCHAR2(20);
		--fin de actualizacion
    BEGIN
        V_LOG_ID := GELEC.INSERT_LOG('Asocia FAE_Cliente con id: '
                                     || P_ID_FAE_CLIENTE
                                     || ' al equipo: '
                                     || P_ID_FAE, P_USUARIO);

		--Actualiza Fae asociada al cliente
        UPDATE GELEC.ED_FAE_CLIENTE FC
        SET
            FC.ID_FAE = P_ID_FAE
        WHERE
            FC.ID = P_ID_FAE_CLIENTE;
			
			--rsleiva 09/08/2022 Actualiza Marca "Posee FAE", activandola o desactivandola
            DECLARE
                --busco la cuenta desde el p_id_fae_cliente
                --convoco el proceso que activa o desactiva la marca. 
            
            BEGIN
                SELECT CUENTA INTO V_CUENTA FROM GELEC.ED_FAE_CLIENTE WHERE ID=P_ID_FAE_CLIENTE;
                SELECT COUNT(1) INTO V_MARCA FROM GELEC.ED_MARCA_CLIENTE WHERE ID_MARCA=7 AND ID_SUBMARCA=18 AND CUENTA=V_CUENTA;
                IF P_ID_FAE>0 AND V_MARCA=0 THEN
                    GELEC.PKG_OTROS.INSERTAR_MARCA(P_USUARIO, '7', '18',V_CUENTA,'[Marca: Cliente | Submarca: POSEE FAE]',V_RESULTADO);
                ELSIF V_MARCA>0 THEN
                    GELEC.PKG_OTROS.INSERTAR_MARCA(P_USUARIO, '7', '18',V_CUENTA,'[Marca: Cliente | Submarca: POSEE FAE]',V_RESULTADO);
                END IF;  
            EXCEPTION
              WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE(V_RESULTADO);
                  
            END;
			--Fin ultima actualizacion

        COMMIT;
        P_RESPUESTA := 1;
    END;
