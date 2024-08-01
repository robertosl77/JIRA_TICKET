CREATE OR REPLACE PACKAGE GELEC.PKG_OTROS
AS
   PROCEDURE A_CONTACTO_INTERNO (P_NOMBRE      IN     VARCHAR2,
                                 P_CARGO       IN     VARCHAR2,
                                 P_REGION      IN     VARCHAR2,
                                 P_TELEFONO    IN     VARCHAR2,
                                 P_EMAIL       IN     VARCHAR2,
                                 P_LOCALIDAD   IN     VARCHAR2,
                                 P_PARTIDO     IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2);

   PROCEDURE B_CONTACTO_INTERNO (P_ID          IN     VARCHAR2,
                                 P_LOG_ID      IN     VARCHAR2,
                                 P_RESULTADO      OUT VARCHAR2);

   PROCEDURE MIGRAR_CLIENTE (P_CUENTA      IN     VARCHAR2,
                             P_ORIGEN      IN     VARCHAR2,
                             P_DESTINO     IN     VARCHAR2,
                             P_LOG         IN     VARCHAR2,
                             P_ACCION      IN     VARCHAR2,
                             P_USUARIO     IN     VARCHAR2,
                             P_RESULTADO      OUT VARCHAR2);

   PROCEDURE MIGRAR_CUENTA (P_ORIGEN      IN     VARCHAR2,
                            P_DESTINO     IN     VARCHAR2,
                            P_USUARIO     IN     VARCHAR2,
                            P_RESULTADO      OUT VARCHAR2);

   PROCEDURE A_TELEFONO_CENSO (P_CUENTA     IN VARCHAR2,
                               P_TELEFONO   IN VARCHAR2,
                               P_LOG_ID     IN VARCHAR2);

   PROCEDURE INSERTAR_MARCA (P_USER_ID       IN     VARCHAR2,
                             P_ID_MARCA      IN     VARCHAR2,
                             P_ID_SUBMARCA   IN     VARCHAR2,
                             P_CUENTA        IN     VARCHAR2,
                             P_NOTA          IN     VARCHAR2,
                             P_RESULTADO        OUT VARCHAR2);

   PROCEDURE DELETE_LOGICO_DOCUMENTO (P_ID_DOCUMENT   IN     VARCHAR2,
                                      P_USER_ID       IN     VARCHAR2,
                                      P_RESULTADO        OUT VARCHAR2);

   PROCEDURE ASOCIARDOC_CLIENTE_NUEVO (P_NRO_DOCUMENT   IN     NUMBER,
                                       P_NRO_CLIENTE    IN     VARCHAR2,
                                       P_USER_ID        IN     VARCHAR2,
                                       P_RESULTADO         OUT VARCHAR2);

   PROCEDURE INSERT_DOC_MANUAL (P_NRO_DOCUMENT   IN     VARCHAR2,
                                P_USER_ID        IN     VARCHAR2,
                                P_RESULTADO         OUT VARCHAR2);

   PROCEDURE ACTUALIZA_CONTACTO_CLIENTE (P_ACCION          IN     VARCHAR2,
                                         P_CUENTA          IN     VARCHAR2,
                                         P_NOMBRE          IN     VARCHAR2,
                                         P_TELEFONO        IN     VARCHAR2,
                                         P_TIPO_CONTACTO   IN     VARCHAR2,
                                         P_USUARIO         IN     VARCHAR2,
                                         P_ID_TEL          IN     VARCHAR2,
                                         P_RESULTADO          OUT VARCHAR2);

   PROCEDURE ACTUALIZA_CLIENTE_DOC (P_ID_DOCUMENTO          IN     NUMBER,
                                    P_CUENTA                IN     VARCHAR2,
                                    P_ESTADO_CLIE           IN     VARCHAR2,
                                    P_SOLUCION_PROVISORIA   IN     VARCHAR2,
                                    P_USUARIO               IN     VARCHAR2,
                                    P_FECHA_FIN_EDITABLE    IN     DATE,
                                    P_RESULTADO                OUT NUMBER);

   PROCEDURE ACTUALIZA_DOCUMENTO (P_ID_DOCUMENTO   IN     NUMBER,
                                  P_ZONA           IN     VARCHAR2,
                                  P_REGION         IN     NUMBER,
                                  P_USUARIO        IN     VARCHAR2,
                                  P_RESULTADO         OUT NUMBER);
END PKG_OTROS;
/