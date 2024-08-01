SELECT
    c.cuenta,
    substr(l.linkvalue,0,instr(l.linkvalue,'-')-1) CT,
    AE.ID ID_AFECTACION, 
    aro.document_id,
    ARO.TIME FECHA_INICIO, 
    (select a.time from nexus_gis.oms_affect_restore_operation a, nexus_gis.oms_affected_element b where a.id=b.restore_id and b.id=ae.id) Fecha_Restauracion
    , ROW_NUMBER() OVER (ORDER BY aro.time) AS num_fila
FROM 
    NEXUS_GIS.SPRLINKS L, 
    NEXUS_GIS.SPROBJECTS O, 
    NEXUS_GIS.OMS_AFFECTED_ELEMENT AE, 
    NEXUS_GIS.OMS_AFFECT_RESTORE_OPERATION ARO, 
    gelec.ed_clientes c
WHERE
    L.LOGIDTO=0
    AND L.LINKID=1018
    AND L.OBJECTID=O.OBJECTID
    AND O.LOGIDTO=0
    AND O.OBJECTNAMEID=AE.ELEMENT_ID
    AND AE.AFFECT_ID=ARO.ID
    AND ARO.IS_RESTORE=0
    AND ARO.OPERATION_ID IS NOT NULL
    AND SUBSTR(L.LINKVALUE,0,INSTR(L.LINKVALUE,'-')-1)=C.CT
    AND ARO.DOCUMENT_ID=10420973
    AND C.CUENTA='0521400227'
ORDER BY
    aro.time asc
; 