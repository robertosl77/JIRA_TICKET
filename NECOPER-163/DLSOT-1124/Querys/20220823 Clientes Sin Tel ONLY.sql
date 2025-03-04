SELECT C.CUENTA, C.RAZON_SOCIAL, (CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=0 THEN 'No' ELSE 'Si' END) BAJA_POTENCIAL FROM GELEC.ED_CLIENTES C,  NEXUS_GIS.SPRCLIENTS SC WHERE C.CUENTA=SC.FSCLIENTID AND CUSTATT21='12521' AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA=C.CUENTA AND NVL(LOG_HASTA,0)=0)=0;    

SELECT 
  C.CUENTA, 
  C.RAZON_SOCIAL, 
  (CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=0 THEN 'No' ELSE 'Si' END) BAJA_POTENCIAL 
FROM 
  GELEC.ED_CLIENTES C, 
  NEXUS_GIS.SPRCLIENTS SC 
WHERE 
  C.CUENTA=SC.FSCLIENTID 
  AND CUSTATT21='12521' 
  AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA=C.CUENTA AND NVL(LOG_HASTA,0)=0)=0
;

SELECT 
  C.CUENTA, 
  C.RAZON_SOCIAL, 
  (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1) BAJA_POTENCIAL 
FROM 
  GELEC.ED_CLIENTES C, 
  NEXUS_GIS.SPRCLIENTS SC 
WHERE 
  C.CUENTA=SC.FSCLIENTID 
  AND CUSTATT21='12521' 
  AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE CUENTA=C.CUENTA AND NVL(LOG_HASTA,0)=0)=0
;   

SELECT 
  C.CUENTA, 
  C.RAZON_SOCIAL, 
  'SIN TELEFONO' ESTADO
FROM 
  GELEC.ED_CLIENTES C
WHERE
  C.CUENTA IN (SELECT FSCLIENTID FROM NEXUS_GIS.SPRCLIENTS WHERE CUSTATT21='12521')
  AND C.CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0)
;

SELECT * FROM GELEC.ED_MARCA_CLIENTE;
SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0;


SELECT 
C.CUENTA, 
C.RAZON_SOCIAL, 
(SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1) BAJA_POTENCIAL 
FROM GELEC.ED_CLIENTES C 
WHERE 
C.CUENTA IN (SELECT FSCLIENTID FROM NEXUS_GIS.SPRCLIENTS WHERE CUSTATT21='12521') 
AND C.CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0);


SELECT C.CUENTA, C.RAZON_SOCIAL, (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1) BAJA_POTENCIAL FROM GELEC.ED_CLIENTES C WHERE NVL(C.LOG_HASTA,0)=0 AND C.CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0);



SELECT 
C.CUENTA, 
C.RAZON_SOCIAL, 
(SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1) BAJA_POTENCIAL 
FROM GELEC.ED_CLIENTES C 
WHERE 
NVL(C.LOG_HASTA,0)=0 
AND C.CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0);



SELECT 
C.CUENTA, 
C.RAZON_SOCIAL, 
(SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1) BAJA_POTENCIAL 
FROM 
GELEC.ED_CLIENTES C 
WHERE 
NVL(C.LOG_HASTA,0)=0 
AND C.CUENTA NOT IN (SELECT CUENTA FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0);


SELECT 
C.CUENTA, 
C.RAZON_SOCIAL, 
CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=1 THEN 'Si' ELSE 'No' END BAJA_POTENCIAL
FROM 
GELEC.ED_CLIENTES C 
WHERE 
NVL(C.LOG_HASTA,0)=0 
AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0 AND CUENTA=C.CUENTA)=0
;


SELECT C.CUENTA, C.RAZON_SOCIAL, CASE WHEN (SELECT COUNT(1) FROM GELEC.ED_MARCA_CLIENTE WHERE CUENTA=C.CUENTA AND ID_MARCA=1)=1 THEN 'Si' ELSE 'No' END BAJA_POTENCIAL FROM GELEC.ED_CLIENTES C WHERE NVL(C.LOG_HASTA,0)=0 AND (SELECT COUNT(1) FROM GELEC.ED_CONTACTOS_CLIENTES WHERE NVL(LOG_HASTA,0)=0 AND CUENTA=C.CUENTA)=0









