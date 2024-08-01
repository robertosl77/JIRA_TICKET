CREATE OR REPLACE PACKAGE GELEC.pkg_fae AS
    PROCEDURE a_fae_cliente (
        p_cuenta    IN    VARCHAR2,
        p_usuario   IN    VARCHAR2,
        p_id        OUT   NUMBER
    );

    PROCEDURE m_fae_cliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_estado        IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    );

    PROCEDURE asociarfaecliente (
        p_id_fae_cliente   IN    NUMBER,
        p_id_fae           IN    NUMBER,
        p_usuario          IN    VARCHAR2,
        p_respuesta        OUT   NUMBER
    );

    PROCEDURE a_orden (
        p_cuenta           IN    VARCHAR2,
        p_id_fae_cliente   IN    NUMBER,
        p_id_tipo          IN    NUMBER,
        p_id_responsable   IN    NUMBER,
        p_usuario          IN     VARCHAR2,
        p_nota             IN    VARCHAR2,
        p_fecha_inicio     IN    DATE,
        p_id               OUT   NUMBER
    );

    PROCEDURE m_orden (
        p_id_orden    IN    NUMBER,
        p_id_estado   IN    NUMBER,
        p_fecha_ini   IN    DATE,
        p_fecha_fin   IN    DATE,
        p_usuario     IN    VARCHAR2,
        p_respuesta   OUT   NUMBER
    );

    PROCEDURE abonar_orden (
        p_id_orden    IN    NUMBER,
        p_abono       IN    NUMBER,
        p_usuario     IN    VARCHAR2,
        p_fecha       IN    DATE,
        p_respuesta   OUT   NUMBER
    );

    PROCEDURE a_equipo (
        p_usuario     IN    VARCHAR2,
        p_serie       IN    VARCHAR2,
        p_deposito    IN    VARCHAR2,
        p_potencia    IN    NUMBER,
        p_capacidad   IN    FLOAT,
        p_ingreso     IN    DATE,
        p_id_modelo   IN    NUMBER,
        p_respuesta   OUT   NUMBER
    );

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
    );

    PROCEDURE m_equipo (
        p_id          IN    NUMBER,
        p_capacidad   IN    FLOAT,
        p_usuario     IN    VARCHAR2,
        p_respuesta   OUT   NUMBER
    );

END pkg_fae;
/