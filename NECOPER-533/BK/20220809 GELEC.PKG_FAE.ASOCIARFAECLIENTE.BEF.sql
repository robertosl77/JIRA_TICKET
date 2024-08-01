    PROCEDURE asociarfaecliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_fae           IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Asocia FAE_Cliente con id: '
                                     || p_id_fae_cliente
                                     || ' al equipo: '
                                     || p_id_fae, p_usuario);

        UPDATE gelec.ed_fae_cliente fc
        SET
            fc.id_fae = p_id_fae
        WHERE
            fc.id = p_id_fae_cliente;

        COMMIT;
        p_respuesta := 1;
    END;