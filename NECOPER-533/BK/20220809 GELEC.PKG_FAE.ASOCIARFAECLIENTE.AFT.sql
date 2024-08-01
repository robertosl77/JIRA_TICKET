    PROCEDURE asociarfaecliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_fae           IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id NUMBER;
		
		--rsleiva 09/08/2022
		v_cuenta gelec.ed_clientes.cuenta%type;
		--fin de actualizacion
    BEGIN
        v_log_id := gelec.insert_log('Asocia FAE_Cliente con id: '
                                     || p_id_fae_cliente
                                     || ' al equipo: '
                                     || p_id_fae, p_usuario);

		--Actualiza Fae asociada al cliente
        UPDATE gelec.ed_fae_cliente fc
        SET
            fc.id_fae = p_id_fae
        WHERE
            fc.id = p_id_fae_cliente;
			
		--rsleiva 09/08/2022
		--Actualiza Marca "Posee FAE", activandola o desactivandola
		
		--busco la cuenta desde el p_id_fae_cliente
		select cuenta into v_cuenta from gelec.ed_fae_cliente where id=p_id_fae_cliente;
		
		--convoco el proceso que activa o desactiva la marca. 
		GELEC.PKG_OTROS.INSERTAR_MARCA(P_USUARIO, 7, 18,v_cuenta,'PRUEBA');
		
		
		--Fin ultima actualizacion

        COMMIT;
        p_respuesta := 1;
    END;