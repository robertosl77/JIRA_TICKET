CREATE OR REPLACE PACKAGE BODY GELEC.pkg_fae AS

    PROCEDURE a_fae_cliente (
        p_cuenta    IN    VARCHAR2,
        p_usuario   IN    VARCHAR2,
        p_id        OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;

      -- Agregar validaciones?
        v_log_id   NUMBER;
        v_id       NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Crea FAE_Cliente', p_usuario);
        v_id := gelec.seq_cliente_fae.nextval();
        INSERT INTO gelec.ed_fae_cliente fc (
            fc.cuenta,
            fc.id,
            fc.id_estado,
            fc.log_desde,
            fc.fecha
        )
           VALUES (
            p_cuenta,
            v_id,
            1,
            v_log_id,
            SYSDATE);

        COMMIT;
        p_id := v_id;
    END;

   PROCEDURE m_fae_cliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_estado        IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Modifica FAE_Cliente con id: '
                                     || p_id_fae_cliente
                                     || ' al estado: '
                                     || p_id_estado, p_usuario);

        UPDATE gelec.ed_fae_cliente fc
        SET
            fc.id_estado = p_id_estado
        WHERE
            fc.id = p_id_fae_cliente;

        COMMIT;
        p_respuesta := 1;
    END;

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

    PROCEDURE a_orden (
        p_cuenta           IN    VARCHAR2,
        p_id_fae_cliente   IN    NUMBER,
        p_id_tipo          IN    NUMBER,
        p_id_responsable   IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_nota             IN    VARCHAR2,
        p_fecha_inicio     IN    DATE,
        p_id               OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id    NUMBER;
        v_id        NUMBER;
        v_id_nota   NUMBER;
        v_asociar   VARCHAR2(15 CHAR);
        v_ordenesSinFechaFin NUMBER;
    BEGIN

        select count(*)
        into v_ordenesSinFechaFin
        from gelec.ed_ordenes o
        where cuenta = p_cuenta
        and id_tipo = p_id_tipo
        and o.ID_FAE_CLIENTE = p_id_fae_cliente
        and fin is null;

        IF(v_ordenesSinFechaFin != 0)
        THEN
        p_id := 0;
        RETURN;
        END IF;

        v_log_id := gelec.insert_log('Crea Orden', p_usuario);
        v_id := gelec.seq_ordenes.nextval();
        INSERT INTO gelec.ed_ordenes o (
            o.id,
            o.cuenta,
            o.id_fae_cliente,
            o.id_estado,
            o.id_tipo,
            o.id_responsable,
            o.log_desde,
            o.inicio,
            o.usuario
        ) VALUES (
            v_id,
            p_cuenta,
            p_id_fae_cliente,
            1,
            p_id_tipo,
            p_id_responsable,
            v_log_id,
            p_fecha_inicio,
            p_usuario
        );

        v_id_nota := gelec.seq_notas.nextval();
        INSERT INTO gelec.ed_notas n (
            n.id_nota,
            n.id_tipo_nota,
            n.fechahora,
            n.observaciones,
            n.log_desde,
            n.usuario
        ) VALUES (
            v_id_nota,
            2,
            SYSDATE,
            p_nota,
            v_log_id,
            p_usuario
        );

        COMMIT;
        gelec.pkg_notas.asociar_nota(NULL, p_cuenta, p_usuario, v_id_nota, v_asociar);
        COMMIT;
        p_id := v_id;
    END;

    PROCEDURE abonar_orden (
        p_id_orden    IN    NUMBER,
        p_abono       IN    NUMBER,
        p_usuario     IN    VARCHAR2,
        p_fecha       IN    DATE,
        p_respuesta   OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log_id NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Modifica orden con id: '
                                     || p_id_orden
                                     || ' abonada: '
                                     || p_abono, p_usuario);

        UPDATE gelec.ed_ordenes o
        SET
            o.abonada = p_abono,
            o.fecha_abonada = p_fecha
        WHERE
            o.id = p_id_orden;

        COMMIT;
        p_respuesta := 1;
    END;

    PROCEDURE m_orden (
        p_id_orden    IN    NUMBER,
        p_id_estado   IN    NUMBER,
        p_fecha_ini   IN    DATE,
        p_fecha_fin   IN    DATE,
        p_usuario     IN    VARCHAR2,
        p_respuesta   OUT   NUMBER
    ) IS

        PRAGMA autonomous_transaction;
        v_log_id                      NUMBER;
        v_tipo_orden                  NUMBER;
        v_id_fae_cliente              NUMBER;
        v_fecha_fin                   DATE;
        v_estado_actual               NUMBER;
        v_estado_actual_fae_cliente   NUMBER;
        v_nuevo_estado_fae_cliente    NUMBER;
    BEGIN
        v_log_id := gelec.insert_log('Modifica Orden con id: '
                                     || p_id_orden
                                     || ' al estado: '
                                     || p_id_estado
                                     || ' fecha_ini: '
                                     || p_fecha_ini
                                     || ' fecha_fin: '
                                     || p_fecha_fin, p_usuario);

      -- Me fijo la fecha de fin original

        SELECT
            o.fin
        INTO v_fecha_fin
        FROM
            gelec.ed_ordenes o
        WHERE
            o.id = p_id_orden;


    -- Solo updateo estado si p_estado != 0

        IF ( p_id_estado != 0 ) THEN
            UPDATE gelec.ed_ordenes o
            SET
                o.id_estado = nvl(p_id_estado, o.id_estado),
                o.inicio = nvl(p_fecha_ini, o.inicio),
                o.fin = p_fecha_fin
            WHERE
                o.id = p_id_orden;

        END IF;

      -- Me fijo el tipo de orden, idFaeCliente y estado actual

        SELECT
            o.id_tipo,
            o.id_fae_cliente,
            o.id_estado
        INTO
            v_tipo_orden,
            v_id_fae_cliente,
            v_estado_actual
        FROM
            gelec.ed_ordenes o
        WHERE
            o.id = p_id_orden;

      -- Si confirman orden o cambian la fecha de fin a una orden confirmada

        IF ( ( nvl(p_id_estado, 0) = 2 OR v_estado_actual = 2 ) AND ( p_fecha_fin IS NOT NULL AND p_fecha_fin != nvl(v_fecha_fin, TO_DATE

        ('01/01/1990', 'DD/MM/YYYY')) ) ) THEN
         -- Si es tipo 1 (instalacion) o tipo 4 (retiro) tengo que cambiar la fecha de instalacion o retiro
            IF ( v_tipo_orden = 1 ) THEN
                UPDATE gelec.ed_fae_cliente fc
                SET
                    fc.instalacion = p_fecha_fin,
                    fc.id_estado = 5
                WHERE
                    fc.id = v_id_fae_cliente;

            ELSE
                IF ( v_tipo_orden = 4 ) THEN
                    UPDATE gelec.ed_fae_cliente fc
                    SET
                        fc.retiro = p_fecha_fin,
                        fc.id_estado = 6
                    WHERE
                        fc.id = v_id_fae_cliente;

                END IF;
            END IF;
        END IF;

      -- Si reactivan orden

      -- Si ID_ESTADO = 0, solamente deshago el abono y fecha de abono

        IF ( p_id_estado = 0 ) THEN
            UPDATE gelec.ed_ordenes o
            SET
                o.abonada = NULL,
                o.fecha_abonada = NULL
            WHERE
                o.id = p_id_orden;

        END IF;

        IF ( p_id_estado = 1 ) THEN
         -- Si es tipo 1 (instalacion) o tipo 4 (retiro) tengo que cambiar la fecha de instalacion o retiro
            IF ( v_tipo_orden = 1 ) THEN
                UPDATE gelec.ed_fae_cliente fc
                SET
                    fc.instalacion = NULL
                WHERE
                    fc.id = v_id_fae_cliente;

            ELSE
                IF ( v_tipo_orden = 4 ) THEN
                    UPDATE gelec.ed_fae_cliente fc
                    SET
                        fc.retiro = NULL
                    WHERE
                        fc.id = v_id_fae_cliente;

                END IF;
            END IF;
        END IF;

      -- Logica de cambio de estado de fae cliente

      --Tipo de ordenes:
      --1 Pendiente
      --2 Pendiente de visita
      --3 Falta adecuar
      --4 Falta documentacion
      --5 Finalizada
      --6 Cancelada
      --7 Falta adecuar (c/FAE)
      --8 Visita fallida
      --9 Rechazada
      --10 EDP en tramite

      -- Estados ordenes:
      --1 Pendiente
      --2 Finalizado
      --3 Fallida

      -- instalacion

        SELECT
            fc.id_estado
        INTO v_estado_actual_fae_cliente
        FROM
            gelec.ed_fae_cliente fc
        WHERE
            fc.id = v_id_fae_cliente;

        IF ( v_tipo_orden = 1 ) THEN
            CASE ( nvl(p_id_estado, 0) )
                WHEN 1 THEN
                    v_nuevo_estado_fae_cliente := 1;
                WHEN 2 THEN
                    v_nuevo_estado_fae_cliente := 5;
                WHEN 3 THEN
                    v_nuevo_estado_fae_cliente := 8;
                ELSE
                    v_nuevo_estado_fae_cliente := v_estado_actual_fae_cliente;
            END CASE;
        END IF;

      -- Preventivo FAE, Correctivo

        IF ( v_tipo_orden IN (
            3,
            6
        ) ) THEN
            CASE ( nvl(p_id_estado, 0) )
                WHEN 3 THEN
                    v_nuevo_estado_fae_cliente := 8;
                ELSE
                    v_nuevo_estado_fae_cliente := v_estado_actual_fae_cliente;
            END CASE;
        END IF;

      -- retiro

        IF ( v_tipo_orden = 4 ) THEN
            CASE ( nvl(p_id_estado, 0) )
                WHEN 2 THEN
                    v_nuevo_estado_fae_cliente := 6;
                WHEN 3 THEN
                    v_nuevo_estado_fae_cliente := 8;
                ELSE
                    v_nuevo_estado_fae_cliente := v_estado_actual_fae_cliente;
            END CASE;
        END IF;

        IF ( v_estado_actual_fae_cliente != v_nuevo_estado_fae_cliente ) THEN
            UPDATE gelec.ed_fae_cliente fc
            SET
                fc.id_estado = v_nuevo_estado_fae_cliente
            WHERE
                fc.id = v_id_fae_cliente;

        END IF;

        COMMIT;
        p_respuesta := 1;
    END;

    PROCEDURE m_equipo_stock (
        p_usuario     IN    VARCHAR2,
        p_serie       IN    VARCHAR2,
        p_deposito    IN    VARCHAR2,
        p_potencia    IN    NUMBER,
        p_capacidad   IN    FLOAT,
        p_ingreso     IN    DATE,
        p_id_modelo   IN    NUMBER,
        p_idfae       IN    NUMBER,
        p_respuesta   OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log   NUMBER;
        v_id    NUMBER;
    BEGIN
        v_log := gelec.insert_log('Modifica equipo FAE con id: ' || p_idfae, p_usuario);
        UPDATE gelec.ed_equipo_fae
        SET
            serie = p_serie,
            deposito = p_deposito,
            potencia = p_potencia,
            capacidad = p_capacidad,
            ingreso = p_ingreso,
            id_modelo = p_id_modelo
        WHERE
            id = p_idfae;

        COMMIT;
        p_respuesta := 1;
    END;

    PROCEDURE a_equipo (
        p_usuario     IN    VARCHAR2,
        p_serie       IN    VARCHAR2,
        p_deposito    IN    VARCHAR2,
        p_potencia    IN    NUMBER,
        p_capacidad   IN    FLOAT,
        p_ingreso     IN    DATE,
        p_id_modelo   IN    NUMBER,
        p_respuesta   OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log   NUMBER;
        v_id    NUMBER;
    BEGIN
        v_id := gelec.seq_equipo_fae.nextval();
        v_log := gelec.insert_log('Da de alta nuevo equipo FAE con id: ' || v_id, p_usuario);
        INSERT INTO gelec.ed_equipo_fae (
            id,
            serie,
            deposito,
            potencia,
            capacidad,
            ingreso,
            id_modelo,
            log_desde
        ) VALUES (
            v_id,
            p_serie,
            p_deposito,
            p_potencia,
            p_capacidad,
            p_ingreso,
            p_id_modelo,
            v_log
        );

        COMMIT;
        p_respuesta := 1;
    END;

    PROCEDURE m_equipo (
        p_id          IN    NUMBER,
        p_capacidad   IN    FLOAT,
        p_usuario     IN    VARCHAR2,
        p_respuesta   OUT   NUMBER
    ) IS
        PRAGMA autonomous_transaction;
        v_log NUMBER;
    BEGIN
        v_log := gelec.insert_log('Modifica capacidad de equipo FAE id: '
                                  || p_id
                                  || ' capacidad: '
                                  || p_capacidad, p_usuario);

        UPDATE gelec.ed_equipo_fae e
        SET
            e.capacidad = p_capacidad
        WHERE
            e.id = p_id;

        p_respuesta := 1;
        COMMIT;
    END;

END pkg_fae;
/