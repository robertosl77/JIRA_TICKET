SELECT MAX(id_periodo) from nexus_gis.NUG_PERIODO;  --2206

select 
    EMG.OBJECTID OBJECTID_G,
    LINKVALUE LINKVALUE_G,
    SPRID SPRID_G,
    NORMALSTATE NORMALSTATE_G,
    realstate realstate_g 
FROM 
    NEXUS_GIS.NUG_EM_GEOGRAFICO EMG
WHERE 
    EMG.ID_PERIODO = 2206 
    AND EMG.ID_TIPO=2
    AND NOT EXISTS(
                  SELECT 1 
                  FROM  NEXUS_GIS.NUG_EM_UNIFILAR EMU 
                  WHERE 
                      EMU.ID_PERIODO = 2206  
                      AND EMU.ID_TIPO IN(1,2,3)--Elem GMI puede estar en Elem UFyDMD
                      AND EMU.ID_PERIODO = EMG.ID_PERIODO
                      AND EMU.LINKVALUE = EMG.LINKVALUE
    );  

SELECT * FROM NEXUS_GIS.NUG_EM_GEOGRAFICO where id_periodo=2206;

     SELECT o.objectnameid,o.objectid,o.sprid,1 as id_tipo,trim(m.linkvalue) as g_linkvalue,o.normaldate,o.normalstate,o.realdate,o.realstate,o.datefrom
     FROM nexus_gis.SPRLINKS m, nexus_gis.sprobjects o 
     WHERE m.linkid = 551 
      AND o.sprid in (400,396,395,798,446,397,398,399,1525)  --(436,1118,400,396,395,798,446,397,398,399)           --linkid de codigos de EM
      AND m.logidto = 0
      AND o.logidto = 0
      AND O.OBJECTID = M.OBJECTID;


     SELECT o.objectnameid,o.objectid,o.sprid,1 as id_tipo,trim(m.linkvalue) as g_linkvalue,o.normaldate,o.normalstate,o.realdate,o.realstate,o.datefrom
     FROM nexus_gis.SPRLINKS m, nexus_gis.sprobjects o 
     WHERE m.linkid = 551 
      AND o.sprid in (400,396,395,798,446,397,398,399,1525)  --(436,1118,400,396,395,798,446,397,398,399)           --linkid de codigos de EM
      AND m.logidto = 0
      AND O.LOGIDTO = 0
      AND o.objectid = m.objectid;
      
      
      SELECT * 
      FROM NEXUS_GIS.SPRENTITIES 
      where sprid in (400,396,395,798,446,397,398,399,1525);



	SELECT o2.objectnameid,o2.objectid,o2.sprid,2 as id_tipo,trim(m2.linkvalue) as g_linkvalue,o2.normaldate,o2.normalstate,o2.realdate,o2.realstate,o2.datefrom     
          FROM nexus_gis.SPRLINKS m2, nexus_gis.sprobjects o2 
          WHERE m2.linkid = 551 
          and o2.sprid in(1159,1161,1163,1164,1167,1197,1202,1455)           --linkid de codigos de EM
          AND m2.logidto = 0
          AND o2.logidto = 0
          AND O2.OBJECTID = M2.OBJECTID;   


      SELECT * 
      FROM NEXUS_GIS.SPRENTITIES 
      where sprid in (1159,1161,1163,1164,1167,1197,1202,1455);



select 
    B.OBJECTNAMEID,
    B.OBJECTID,
    B.SPRID,
    1 AS ID_TIPO,
    TRIM(A.LINKVALUE) LINKVALUE,
    B.NORMALDATE,
    B.NORMALSTATE,
    B.REALDATE,
    B.REALSTATE,
    0 valid_code, --EDENOR_CARTOGRAFIA.EM_VALID_CODE(A.LINKVALUE) AS VALID_CODE,
    B.DATEFROM
    , N.LINKVALUE
    , A.LINKVALUE
FROM 
    NEXUS_GIS.SPRLINKS A, 
    NEXUS_GIS.SPROBJECTS B, 
    NEXUS_GIS.ENTITIESGROUPENTS D, 
    NEXUS_GIS.SPRLINKS E, 
    NEXUS_GIS.SPRENTITIES F,
    nexus_gis.SPRLINKS N
WHERE 
    a.linkid = 1018                       -- UNI Nombre
--    AND Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
    AND a.logidto = 0                         -- Vivos
    AND e.logidto = 0 
    AND b.logidto = 0
    AND b.objectid = a.objectid
    AND d.sprid = b.sprid
    AND d.entitiesgroupid = 176               -- Grupo de entidades CONF - IEMG
    AND e.objectid = b.objectid
    AND e.linkid = 1019                       -- Tipo constructivo GIS (alias)
    AND RPAD(f.alias, 30) = e.linkvalue
    AND f.categid = 34
    AND f.nettypeid = 5
    AND n.objectid = b.objectid
    AND n.linkid = 1198
    AND n.logidto = 0
    AND N.LINKVALUE LIKE 'DE%'
;
UNION 

    (
    select 
        B2.OBJECTNAMEID,
        B2.OBJECTID,
        B2.SPRID,
        3 AS ID_TIPO,
        TRIM(A2.LINKVALUE) LINKVALUE,
        B2.NORMALDATE,
        B2.NORMALSTATE,
        B2.REALDATE,
        b2.realstate,
        TRIM(A2.LINKVALUE) AS VALID_CODE,
        b2.datefrom
    FROM 
        NEXUS_GIS.SPRLINKS A2, 
        nexus_gis.SPROBJECTS b2
    WHERE 
        a2.linkid = 1018                       -- UNI Nombre
        AND b2.sprid in (1317,1321,1322,1318,1524,1319,1315)  --(1317,1321,1322,1320,1318)
        AND a2.logidto = 0                         -- Vivos
        AND b2.logidto = 0
        AND b2.objectid = a2.objectid 
    
    MINUS
    
    SELECT 
        B.OBJECTNAMEID,
        B.OBJECTID,
        B.SPRID,
        3 AS ID_TIPO,
        TRIM(A.LINKVALUE) LINKVALUE,
        B.NORMALDATE,
        B.NORMALSTATE,
        B.REALDATE,
        b.realstate,
        TRIM(A.LINKVALUE) AS VALID_CODE,
        b.datefrom
    FROM 
        NEXUS_GIS.SPRLINKS A, 
        NEXUS_GIS.SPROBJECTS B, 
        NEXUS_GIS.ENTITIESGROUPENTS D, 
        NEXUS_GIS.SPRLINKS E, 
        NEXUS_GIS.SPRENTITIES F,
        NEXUS_GIS.SPRLINKS N
    WHERE 
        A.LINKID = 1018                       -- UNI Nombre
        --AND Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
        AND a.logidto = 0                         -- Vivos
        AND e.logidto = 0
        AND b.logidto = 0
        AND b.objectid = a.objectid
        AND d.sprid = b.sprid
        AND d.entitiesgroupid = 176               -- Grupo de entidades CONF - IEMG
        AND e.objectid = b.objectid
        AND e.linkid = 1019                       -- Tipo constructivo GIS (alias)
        AND RPAD(f.alias, 30) = e.linkvalue
        AND f.categid = 34
        AND f.nettypeid = 5
        AND n.objectid = b.objectid
        AND n.linkid = 1198
        AND n.logidto = 0
        AND N.LINKVALUE LIKE 'DE%'
    )
    ;
