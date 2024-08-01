SELECT 
    T.*, 
    (SELECT MAX(FECHAHORA) FROM GELEC.ED_NOTAS WHERE IDDESTINO=T.ID_TEL AND NVL(EFECTIVAS,0)>0) ULTIMO_CONTACTO_EFECTIVO
FROM (
    SELECT 
        C.CUENTA,
        CC.ID_TEL, 
        CC.TELEFONO, 
        SUM(CASE WHEN NVL(N.EFECTIVO,-1)>=0 THEN 1 ELSE 0 END) LLAMADAS, 
        SUM(CASE WHEN NVL(N.EFECTIVO,0)>0 THEN 1 ELSE 0 END) EFECTIVAS, 
        (CASE WHEN NVL(CC.LOG_HASTA,0)>0 THEN 'ACTIVO' ELSE 'BAJA' END) ESTADO_TELEFONO
    FROM 
        GELEC.ED_CLIENTES C,
        GELEC.ED_CONTACTOS_CLIENTES CC,
        GELEC.ED_NOTAS N, 
        NEXUS_GIS.SPRCLIENTS SC            
    WHERE
        1=1
        AND C.CUENTA= SC.FSCLIENTID
        AND SC.CUSTATT21='12521'
        AND C.CUENTA=CC.CUENTA(+)
        AND CC.ID_TEL=N.IDDESTINO(+)
    GROUP BY
        C.CUENTA, 
        CC.ID_TEL, 
        CC.TELEFONO, 
        (CASE WHEN NVL(CC.LOG_HASTA,0)>0 THEN 'ACTIVO' ELSE 'BAJA' END)
    ORDER BY
        C.CUENTA, 
        CC.ID_TEL DESC
) T;