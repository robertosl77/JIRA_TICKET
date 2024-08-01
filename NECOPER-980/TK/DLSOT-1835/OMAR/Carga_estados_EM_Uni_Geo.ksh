#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa
# LOG_DIR=/stage/gis/imple/procesos/TMT/trans/TPR/batch/logs
DATE=$( date +%y%m%d%H%M )
FILE_LOG=$LOG_DIR/Carga_estados_EM_Uni_Geo.ksh_$DATE.log
FILE_AUX=$LOG_DIR/Carga_estados_EM_Uni_Geo.ksh.aux

USER=NEXUS_GIS
PASSWORD=`sh ~/get_password.sh $USER`
 
echo "\n
   ______________________________________________________________________________________________________________

                     EJECUCION DE PROCESO - DATE: $(date '+%d/%m/%y %H:%M:%S') - DATABASE: ${ORACLE_SID}
                                               SCRIPT EJECUTADO: ${0}

   ______________________________________________________________________________________________________________

    * $(date '+%d/%m/%y %H:%M:%S') - Iniciando ejecucion ............... \n" >>$FILE_LOG

sqlplus -s /nolog << ENDSQL > $FILE_AUX
SPOOL ${ARCH_SPOOL}
connect $USER/$PASSWORD
set serveroutput on
set pagesize 0
set linesize 200
set verify off
set feed off
set timing on
set time ON

----------------------------
-- Start your script here --
----------------------------
--------------------------------------
-- Datos proceso ---------------------
--------------------------------------

--Autor:		Martin Rosito
--Fecha:		23/08/2017
--CRQ		5625 
--Descripción:		Cargar las tablas nug con los EM de Unifilar y MT Geografico		
-------------------------------------
--Historial de modificaciones--------
-------------------------------------

-------------------------------------
-------------------------------------

DECLARE

CURSOR cur_em_uni_2
   IS
     select b.objectnameid,b.objectid,b.sprid,1 as id_tipo,trim(a.linkvalue) linkvalue,b.normaldate,b.normalstate,b.realdate,b.realstate,
     Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) as VALID_CODE,b.datefrom
   FROM nexus_gis.SPRLINKS a, nexus_gis.SPROBJECTS b, nexus_gis.ENTITIESGROUPENTS d, nexus_gis.SPRLINKS e, nexus_gis.SPRENTITIES f,nexus_gis.SPRLINKS N
     WHERE a.linkid = 1018                       -- UNI Nombre
      AND Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
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
      AND n.linkvalue like 'DE%';
	  
	  
	  
   CURSOR cur_em_uni
   IS
     select b.objectnameid,b.objectid,b.sprid,1 as id_tipo,trim(a.linkvalue) linkvalue,b.normaldate,b.normalstate,b.realdate,b.realstate,
     Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) as VALID_CODE,b.datefrom
   FROM nexus_gis.SPRLINKS a, nexus_gis.SPROBJECTS b, nexus_gis.ENTITIESGROUPENTS d, nexus_gis.SPRLINKS e, nexus_gis.SPRENTITIES f,nexus_gis.SPRLINKS N
     WHERE a.linkid = 1018                       -- UNI Nombre
      AND Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
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
      AND n.linkvalue like 'DE%'
     Union 
     (select b2.objectnameid,b2.objectid,b2.sprid,3 as id_tipo,trim(a2.linkvalue) linkvalue,b2.normaldate,b2.normalstate,b2.realdate,b2.realstate,
     trim(a2.linkvalue) as VALID_CODE,b2.datefrom
     FROM nexus_gis.SPRLINKS a2, nexus_gis.SPROBJECTS b2
     WHERE a2.linkid = 1018                       -- UNI Nombre
     AND b2.sprid in (1317,1321,1322,1318,1524,1319,1315)  --(1317,1321,1322,1320,1318)
      AND a2.logidto = 0                         -- Vivos
      AND b2.logidto = 0
      AND b2.objectid = a2.objectid 
     minus
     select b.objectnameid,b.objectid,b.sprid,3 as id_tipo,trim(a.linkvalue) linkvalue,b.normaldate,b.normalstate,b.realdate,b.realstate,
     trim(a.linkvalue) as VALID_CODE,b.datefrom
     FROM nexus_gis.SPRLINKS a, nexus_gis.SPROBJECTS b, nexus_gis.ENTITIESGROUPENTS d, nexus_gis.SPRLINKS e, nexus_gis.SPRENTITIES f,nexus_gis.SPRLINKS N
     WHERE a.linkid = 1018                       -- UNI Nombre
      AND Edenor_Cartografia.EM_VALID_CODE(a.linkvalue) is not null
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
      AND n.linkvalue like 'DE%');

                    

   CURSOR cur_em_geo
   IS
     SELECT o.objectnameid,o.objectid,o.sprid,1 as id_tipo,trim(m.linkvalue) as g_linkvalue,o.normaldate,o.normalstate,o.realdate,o.realstate,o.datefrom
     FROM nexus_gis.SPRLINKS m, nexus_gis.sprobjects o 
     WHERE m.linkid = 551 
      AND o.sprid in (400,396,395,798,446,397,398,399,1525)  --(436,1118,400,396,395,798,446,397,398,399)           --linkid de codigos de EM
      AND m.logidto = 0
      AND o.logidto = 0
      AND o.objectid = m.objectid;

	CURSOR cur_mi_uni 
    IS
		select o1.objectnameid,o1.objectid,o1.sprid,2 as id_tipo,trim(m1.linkvalue) as linkvalue,o1.normaldate,o1.normalstate,o1.realdate,o1.realstate,
		--RTRIM(SUBSTR (m1.linkvalue, instr(m1.linkvalue,'-')+1))||'-'||RTRIM(SUBSTR (m1.linkvalue,1,instr(m1.linkvalue,'-')-1)) as VALID_CODE
		trim(m1.linkvalue) as VALID_CODE,o1.datefrom   
          FROM nexus_gis.SPRLINKS m1, nexus_gis.sprobjects o1 
          WHERE m1.linkid = 1018
          and o1.sprid in (1296,1297,1299,1301,1302,1303,1298,1300)    --(1296,1297,1299,1301,1302,1303,1304)           --linkid de codigos de EM
          AND m1.logidto = 0
          AND o1.logidto = 0
          AND o1.objectid = m1.objectid; 

   CURSOR cur_mi_geo
   IS	
	SELECT o2.objectnameid,o2.objectid,o2.sprid,2 as id_tipo,trim(m2.linkvalue) as g_linkvalue,o2.normaldate,o2.normalstate,o2.realdate,o2.realstate,o2.datefrom     
          FROM nexus_gis.SPRLINKS m2, nexus_gis.sprobjects o2 
          WHERE m2.linkid = 551 
          and o2.sprid in(1159,1161,1163,1164,1167,1197,1202,1455)           --linkid de codigos de EM
          AND m2.logidto = 0
          AND o2.logidto = 0
          AND o2.objectid = m2.objectid;   
	  
 CURSOR cur_egu
   IS
      SELECT *
        FROM nexus_gis.NUG_EM_UNIFILAR
       WHERE 1 = 0;

   reg_egu   cur_egu%ROWTYPE;    
    
 CURSOR cur_egg
   IS
      SELECT *
        FROM nexus_gis.NUG_EM_GEOGRAFICO
       WHERE 1 = 0;

   reg_egg   cur_egg%ROWTYPE;        
--Variables
   cont      NUMBER (7)     := 0;
   vfecha    DATE;
   val_p     NUMBER;
   p_error   BOOLEAN        := FALSE;
   v_msg     VARCHAR2 (150);
   
   ----------------------------------------------
   vid_per       NUMBER (6);
   vfecha_per    DATE;
   viter_per     NUMBER (2);
   vtipo_per     VARCHAR (1);
   v_tipo_desc   VARCHAR (50);
   vcountgis     NUMBER        := 0;
   vcountscada   NUMBER        := 0;
   vcountdif     NUMBER        := 0;
   vcount        NUMBER        := 0;
   v_desc        VARCHAR (150);
BEGIN

    --definir el periodo a calcular    
   vfecha := sysdate;
   val_p := nexus_gis.nug_calcula_periodo (vfecha);

-- 1-Inserta mundo NUG_EM_UNIFILAR
   FOR cemu IN cur_em_uni
   LOOP
      reg_egu.objectnameid := cemu.objectnameid;
      reg_egu.objectid := cemu.objectid;
      reg_egu.sprid := cemu.sprid;
      reg_egu.linkvalue := cemu.linkvalue;
      reg_egu.normaldate := cemu.normaldate;
      reg_egu.normalstate := cemu.normalstate;
      reg_egu.realdate := cemu.realdate;
      reg_egu.realstate :=cemu.realstate;
      reg_egu.VALID_CODE := cemu.VALID_CODE;
      reg_egu.datefrom := cemu.datefrom;
      reg_egu.id_tipo:= cemu.id_tipo;
      reg_egu.id_periodo := val_p;

      BEGIN
      --DBMS_OUTPUT.put_line ('objectnameid: '||cemu.objectnameid);
         INSERT INTO nexus_gis.NUG_EM_UNIFILAR
              VALUES reg_egu;

         cont := cont + 1;

         IF cont > 1000
         THEN
            COMMIT;
            cont := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error := TRUE;
            v_msg := SUBSTR (SQLERRM, 1, 150);
            DBMS_OUTPUT.put_line ('El proceso finalizo con ERROR ' || v_msg);
      END;
   END LOOP; 
   
 commit;

------ 2-- Inserta mundo NUG_EM_GEOGRAFICO
   FOR cemg IN cur_em_geo
   LOOP
      reg_egg.objectnameid := cemg.objectnameid;
      reg_egg.objectid := cemg.objectid;
      reg_egg.sprid := cemg.sprid;
      reg_egg.linkvalue := cemg.g_linkvalue;
      reg_egg.normaldate := cemg.normaldate;
      reg_egg.normalstate := cemg.normalstate;
      reg_egg.realdate := cemg.realdate;
      reg_egg.realstate :=cemg.realstate;
      reg_egg.datefrom := cemg.datefrom;
      reg_egg.id_tipo:= cemg.id_tipo;
      reg_egg.id_periodo := val_p;

      BEGIN
         INSERT INTO nexus_gis.NUG_EM_GEOGRAFICO
              VALUES reg_egg;

         cont := cont + 1;

         IF cont > 1000
         THEN
            COMMIT;
            cont := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error := TRUE;
            v_msg := SUBSTR (SQLERRM, 1, 150);
            DBMS_OUTPUT.put_line ('El proceso finalizo con ERROR ' || v_msg);
      END;
   END LOOP; 
   
 commit;

 -------------

-- 3-Inserta MI NUG_EM_UNIFILAR
   FOR cmiu IN cur_mi_uni
   LOOP
      reg_egu.objectnameid := cmiu.objectnameid;
      reg_egu.objectid := cmiu.objectid;
      reg_egu.sprid := cmiu.sprid;
      reg_egu.linkvalue := cmiu.linkvalue;
      reg_egu.normaldate := cmiu.normaldate;
      reg_egu.normalstate := cmiu.normalstate;
      reg_egu.realdate := cmiu.realdate;
      reg_egu.realstate :=cmiu.realstate;
      reg_egu.VALID_CODE := cmiu.VALID_CODE;
      reg_egu.datefrom := cmiu.datefrom;
      reg_egu.id_tipo:= cmiu.id_tipo;
      reg_egu.id_periodo := val_p;

      BEGIN
      --DBMS_OUTPUT.put_line ('objectnameid: '||cemu.objectnameid);
         INSERT INTO nexus_gis.NUG_EM_UNIFILAR
              VALUES reg_egu;

         cont := cont + 1;

         IF cont > 1000
         THEN
            COMMIT;
            cont := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error := TRUE;
            v_msg := SUBSTR (SQLERRM, 1, 150);
            DBMS_OUTPUT.put_line ('El proceso finalizo con ERROR ' || v_msg);
      END;
   END LOOP; 
   
 commit;

------ 4-- Inserta MI NUG_EM_GEOGRAFICO
   FOR cmig IN cur_mi_geo
   LOOP
      reg_egg.objectnameid := cmig.objectnameid;
      reg_egg.objectid := cmig.objectid;
      reg_egg.sprid := cmig.sprid;
      reg_egg.linkvalue := cmig.g_linkvalue;
      reg_egg.normaldate := cmig.normaldate;
      reg_egg.normalstate := cmig.normalstate;
      reg_egg.realdate := cmig.realdate;
      reg_egg.realstate :=cmig.realstate;
      reg_egg.datefrom := cmig.datefrom;
      reg_egg.id_tipo:= cmig.id_tipo;
      reg_egg.id_periodo := val_p;

      BEGIN
         INSERT INTO nexus_gis.NUG_EM_GEOGRAFICO
              VALUES reg_egg;

         cont := cont + 1;

         IF cont > 1000
         THEN
            COMMIT;
            cont := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error := TRUE;
            v_msg := SUBSTR (SQLERRM, 1, 150);
            DBMS_OUTPUT.put_line ('El proceso finalizo con ERROR ' || v_msg);
      END;
   END LOOP; 
   
 commit;
------------------------ 
END;

/
----------------------------
-- End your script here   --
----------------------------
ENDSQL
 
echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Detalle Ejecucion proceso ............... \n" >>$FILE_LOG
 
ERROR_DB=0
ERROR_DB=`grep -i Agatha $FILE_AUX | wc -l`


	
	cat $FILE_AUX >>$FILE_LOG
 
echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Fin Ejecucion proceso ............... \n" >>$FILE_LOG
 
rm $FILE_AUX

exit_error=`cat $FILE_LOG | grep 'ORA-' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 9
fi

exit_error=`cat $FILE_LOG | grep 'ERRORES' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 10
fi
