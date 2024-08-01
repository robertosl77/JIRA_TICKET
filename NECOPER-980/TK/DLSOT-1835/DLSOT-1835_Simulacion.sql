SET SERVEROUTPUT ON
declare

    CURSOR CUR_MI_GEO_NO_UNI(PID_PER NUMBER) IS
        select emg.objectid objectid_g,linkvalue linkvalue_g,sprid sprid_g,normalstate normalstate_g,realstate realstate_g
        from NEXUS_GIS.NUG_EM_geografico emg
        where emg.id_periodo = PID_PER and emg.id_tipo=2
        and not exists(
            select 1 from  (
                SELECT B.OBJECTNAMEID,B.OBJECTID,B.SPRID,1 AS ID_TIPO,TRIM(A.LINKVALUE) LINKVALUE,B.NORMALDATE,B.NORMALSTATE,B.REALDATE,B.REALSTATE,
                nexus_GIS.Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) as VALID_CODE,b.datefrom, PID_PER id_periodo
                FROM nexus_gis.SPRLINKS a, nexus_gis.SPROBJECTS b, nexus_gis.ENTITIESGROUPENTS d, nexus_gis.SPRLINKS e, nexus_gis.SPRENTITIES f,nexus_gis.SPRLINKS N
                WHERE A.LINKID = 1018                       -- UNI Nombre
                AND nexus_GIS.Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
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
                --
                UNION 
                --
                (SELECT B2.OBJECTNAMEID,B2.OBJECTID,B2.SPRID,3 AS ID_TIPO,TRIM(A2.LINKVALUE) LINKVALUE,B2.NORMALDATE,B2.NORMALSTATE,B2.REALDATE,B2.REALSTATE,
                trim(a2.linkvalue) as VALID_CODE,b2.datefrom, PID_PER id_periodo
                FROM nexus_gis.SPRLINKS a2, nexus_gis.SPROBJECTS b2
                WHERE A2.LINKID = 1018                       -- UNI Nombre
                AND b2.sprid in (1317,1321,1322,1318,1524,1319,1315,1320)  --(1317,1321,1322,1320,1318)
                AND a2.logidto = 0                         -- Vivos
                AND b2.logidto = 0
                AND B2.OBJECTID = A2.OBJECTID 
                --
                MINUS
                --
                SELECT B.OBJECTNAMEID,B.OBJECTID,B.SPRID,3 AS ID_TIPO,TRIM(A.LINKVALUE) LINKVALUE,B.NORMALDATE,B.NORMALSTATE,B.REALDATE,B.REALSTATE,
                trim(a.linkvalue) as VALID_CODE,b.datefrom, PID_PER id_periodo
                FROM nexus_gis.SPRLINKS a, nexus_gis.SPROBJECTS b, nexus_gis.ENTITIESGROUPENTS d, nexus_gis.SPRLINKS e, nexus_gis.SPRENTITIES f,nexus_gis.SPRLINKS N
                WHERE A.LINKID = 1018                       -- UNI Nombre
                AND nexus_GIS.Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
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
                AND N.LOGIDTO = 0
                AND N.LINKVALUE LIKE 'DE%')
                --
                UNION 
                --
                select o1.objectnameid,o1.objectid,o1.sprid,2 as id_tipo,trim(m1.linkvalue) as linkvalue,o1.normaldate,o1.normalstate,o1.realdate,o1.realstate,
                --RTRIM(SUBSTR (m1.linkvalue, instr(m1.linkvalue,'-')+1))||'-'||RTRIM(SUBSTR (m1.linkvalue,1,instr(m1.linkvalue,'-')-1)) as VALID_CODE
                trim(m1.linkvalue) as VALID_CODE,o1.datefrom   , PID_PER id_periodo
                FROM nexus_gis.SPRLINKS m1, nexus_gis.sprobjects o1 
                WHERE m1.linkid = 1018
                and o1.sprid in (1296,1297,1299,1301,1302,1303,1298,1300)    --(1296,1297,1299,1301,1302,1303,1304)           --linkid de codigos de EM
                AND m1.logidto = 0
                AND O1.LOGIDTO = 0
                AND o1.objectid = m1.objectid
            
            ) emu
            where emu.id_periodo = PID_PER  and emu.id_tipo in(1,2,3)--Elem GMI puede estar en Elem UFyDMD
            AND EMU.ID_PERIODO = EMG.ID_PERIODO
            AND EMU.LINKVALUE = EMG.LINKVALUE
        );    

    VID_PER   NUMBER(10);
    VCOUNTGIS11 NUMBER(10);
    v_estado_real_g   VARCHAR2(50);
    V_ESTADO_NORMAL_G   VARCHAR2(50);    
    
BEGIN
    DBMS_OUTPUT.put_line ('11) Elementos de Maniobras del Mundo Interno del Geografico que no estan en el Unifilar');        
    VCOUNTGIS11:=0;
    vid_per:=2220;
    
    FOR cmignu IN cur_mi_geo_no_uni(vid_per) LOOP        
        --Actualizo la tabla Log
--        insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
--        VALUES (vid_per,cmignu.objectid_g,cmignu.linkvalue_g,cmignu.sprid_g,cmignu.normalstate_g,cmignu.realstate_g,11);
        --Informo 
        select decode(trim(cmignu.normalstate_g),'15', 'Cerrado','0','Abierto', null) estado_normal_g,decode(trim(cmignu.realstate_g),'15', 'Cerrado','0','Abierto', null) estado_real_g
        into v_estado_normal_g,v_estado_real_g
        from dual; 
        
            if vcountgis11 = 0 then
                DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                DBMS_OUTPUT.put_line (cmignu.objectid_g||'    '||cmignu.linkvalue_g||'    '||cmignu.sprid_g||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                vcountgis11 := vcountgis11 + 1;
            else
                DBMS_OUTPUT.put_line (cmignu.objectid_g||'    '||cmignu.linkvalue_g||'    '||cmignu.sprid_g||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                vcountgis11 := vcountgis11 + 1;
            end if;            
         
    END LOOP;

















END;

    