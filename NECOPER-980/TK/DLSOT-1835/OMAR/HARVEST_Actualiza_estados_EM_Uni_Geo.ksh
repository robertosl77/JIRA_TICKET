#!/usr/bin/ksh

# Definicion de variables de entorno
. ~/ScriptsNexusGIS.properties
 
# Definicion de variables de programa

DATE=$( date +%y%m%d%H%M )
FILE_LOG=$LOG_DIR/Actualiza_estados_EM_Uni_Geo.ksh_$DATE.log
FILE_AUX=$LOG_DIR/Actualiza_estados_EM_Uni_Geo.ksh.aux

USER=NEXUS_GIS
PASSWORD=`sh ~/get_password.sh $USER`
 
echo "\n

   ______________________________________________________________________________________________________________

                     EJECUCION DE PROCESO - DATE: $(date '+%d/%m/%y %H:%M:%S') - DATABASE: ${ORACLE_SID}
                                               SCRIPT EJECUTADO: ${0}

   ______________________________________________________________________________________________________________

    * $(date '+%d/%m/%y %H:%M:%S') - Iniciando ejecucion ............... \n" >>$FILE_LOG

sqlplus -s /nolog << ENDSQL > $FILE_AUX
connect $USER/$PASSWORD
set serveroutput on
set pagesize 0
set linesize 200
set verify off
set feed off
----------------------------
-- Start your script here --
----------------------------

--------------------------------------
-- Datos proceso ---------------------
--------------------------------------

--Autor:		Martin Rosito
--Fecha:		03/10/2017
--CRQ		5625 
--Descripción:		Actualiza los estados de EM del MT Geograficos segun Unifilar
-------------------------------------
--Historial de modificaciones--------
-------------------------------------

-------------------------------------
-------------------------------------

DECLARE
--Fuera del MI
--1
   CURSOR cur_em_dupli_uni(pid_per NUMBER) 
   IS
      select valid_code
        from NEXUS_GIS.NUG_EM_unifilar emu
        where id_periodo = pid_per and emu.id_tipo=1 and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%') --se extraen los puentes
        group by valid_code
        having count(1) > 1;
--1  
  CURSOR cur_em_dupli_uni_u (pid_per NUMBER,p_valid_code varchar2)
  IS 
     select objectid,valid_code,sprid,normalstate,realstate
        from NEXUS_GIS.NUG_EM_unifilar emu
        where id_periodo = pid_per and emu.id_tipo=1 and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%') --se extraen los puentes
        and valid_code=p_valid_code;
--2  
  CURSOR cur_em_dupli_geo(pid_per NUMBER) 
   IS
      select LINKVALUE
        from NEXUS_GIS.NUG_EM_geografico emg
        where id_periodo = pid_per and emg.id_tipo=1
        group by LINKVALUE
        having count(1) > 1;
--2  
  CURSOR cur_em_dupli_geo_u (pid_per NUMBER,p_LINKVALUE varchar2)
  IS 
     select objectid,linkvalue,sprid,normalstate,realstate
        from NEXUS_GIS.NUG_EM_geografico emg
        where id_periodo = pid_per and emg.id_tipo=1
        and LINKVALUE=p_LINKVALUE;
--3  
  CURSOR cur_em_uni_no_geo(pid_per NUMBER)
  IS
    select emu.objectid objectid_u,valid_code valid_code_u,sprid sprid_u,normalstate normalstate_u,realstate realstate_u 
    from NEXUS_GIS.NUG_EM_unifilar emu
    where emu.id_periodo = pid_per and emu.id_tipo=1 and (linkvalue not like 'PTE%' and linkvalue not like 'PUENTE%') --se extraen los puentes
    and not exists(
    select 1
    from  NEXUS_GIS.NUG_EM_geografico emg
    where emg.id_periodo = pid_per and emg.id_tipo in(1,2)--el EMFMD puede estar en GFyD MI
    and emu.id_periodo = emg.id_periodo
    and emu.linkvalue = emg.linkvalue);
--4     
  CURSOR cur_em_geo_no_uni(pid_per NUMBER)
  IS
    select emg.objectid objectid_g,linkvalue linkvalue_g,sprid sprid_g,normalstate normalstate_g,realstate realstate_g 
    from NEXUS_GIS.NUG_EM_geografico emg
    where emg.id_periodo = pid_per and emg.id_tipo=1 
    and not exists(
    select 1
    from  NEXUS_GIS.NUG_EM_unifilar emu
    where emu.id_periodo = pid_per  and emu.id_tipo=1 and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%') --se extraen los puentes
    and emu.id_periodo = emg.id_periodo
    and emu.linkvalue = emg.linkvalue);    
--5	
  CURSOR cur_em_unigeo_normal(pid_per NUMBER)
  IS    
    select emu.objectid objectid_u,emu.valid_code valid_code_u,emu.sprid sprid_u,emu.normalstate normalstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.normalstate normalstate_g,emg.datefrom datefrom_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per 
    and emu.id_tipo=1 and emg.id_tipo in(1,2)--el EMFMD puede estar en GFyD MI
    and emu.normalstate != emg.normalstate
	and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%');--se extraen los puentes
--6
  CURSOR cur_em_unigeo_real(pid_per NUMBER)
  IS
      select emu.objectid objectid_u,emu.valid_code valid_code_u,emu.sprid sprid_u,emu.realstate realstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.realstate realstate_g,emg.datefrom datefrom_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per 
    and emu.id_tipo=1 and emg.id_tipo in(1,2)--el EMFMD puede estar en GFyD MI
    and emu.realstate != emg.realstate
	and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%');--se extraen los puentes
--7    
  CURSOR cur_em_unigeo_i(pid_per NUMBER)    
  IS
    select emu.objectid objectid_u,emu.valid_code valid_code_u,emu.sprid sprid_u,emu.normalstate normalstate_u,emu.realstate realstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.normalstate normalstate_g,emg.realstate realstate_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per 
    and emu.id_tipo=1 and emg.id_tipo in(1,2)--el EMFMD puede estar en GFyD MI
    and emu.normalstate = emg.normalstate
    and emu.realstate = emg.realstate
	and (VALID_CODE not like 'PTE%' and VALID_CODE not like 'PUENTE%');--se extraen los puentes
-------------------MI
--8
  CURSOR cur_mi_dupli_uni(pid_per NUMBER) 
   IS
      select valid_code
        from NEXUS_GIS.NUG_EM_unifilar emu
        where id_periodo = pid_per and emu.id_tipo=2
        group by valid_code
        having count(1) > 1;
--8  
  CURSOR cur_mi_dupli_uni_u (pid_per NUMBER,p_valid_code varchar2)
  IS 
     select objectid,valid_code,sprid,normalstate,realstate
        from NEXUS_GIS.NUG_EM_unifilar emu
        where id_periodo = pid_per and emu.id_tipo=2
        and valid_code=p_valid_code;
--9  
  CURSOR cur_mi_dupli_geo(pid_per NUMBER) 
   IS
      select LINKVALUE
        from NEXUS_GIS.NUG_EM_geografico emg
        where id_periodo = pid_per and emg.id_tipo=2
        group by LINKVALUE
        having count(1) > 1;
--9  
  CURSOR cur_mi_dupli_geo_u (pid_per NUMBER,p_LINKVALUE varchar2)
  IS 
     select objectid,linkvalue,sprid,normalstate,realstate
        from NEXUS_GIS.NUG_EM_geografico emg
        where id_periodo = pid_per and emg.id_tipo=2
        and LINKVALUE=p_LINKVALUE;
--10  
  CURSOR cur_mi_uni_no_geo(pid_per NUMBER)
  IS
    select emu.objectid objectid_u,valid_code linkvalue_u,sprid sprid_u,normalstate normalstate_u,realstate realstate_u 
    from NEXUS_GIS.NUG_EM_unifilar emu
    where emu.id_periodo = pid_per and emu.id_tipo=2
    and not exists(
    select 1
    from  NEXUS_GIS.NUG_EM_geografico emg
    where emg.id_periodo = pid_per and emg.id_tipo=2
    and emu.id_periodo = emg.id_periodo
    and emu.linkvalue = emg.linkvalue);
--11     
  CURSOR cur_mi_geo_no_uni(pid_per NUMBER)
  IS
    select emg.objectid objectid_g,linkvalue linkvalue_g,sprid sprid_g,normalstate normalstate_g,realstate realstate_g 
    from NEXUS_GIS.NUG_EM_geografico emg
    where emg.id_periodo = pid_per and emg.id_tipo=2
    and not exists(
    select 1
    from  NEXUS_GIS.NUG_EM_unifilar emu
    where emu.id_periodo = pid_per  and emu.id_tipo in(1,2,3)--Elem GMI puede estar en Elem UFyDMD
    and emu.id_periodo = emg.id_periodo
    and emu.linkvalue = emg.linkvalue);    
--12
  CURSOR cur_mi_unigeo_normal(pid_per NUMBER)
  IS    
    select emu.objectid objectid_u,emu.valid_code linkvalue_u,emu.sprid sprid_u,emu.normalstate normalstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.normalstate normalstate_g,emg.datefrom datefrom_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per
    and emu.id_tipo in(1,2,3) and emg.id_tipo=2 --Elem GMI puede estar en Elem UFyDMD
    and emu.normalstate != emg.normalstate;
--13
  CURSOR cur_mi_unigeo_real(pid_per NUMBER)
  IS
    select emu.objectid objectid_u,emu.valid_code linkvalue_u,emu.sprid sprid_u,emu.realstate realstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.realstate realstate_g,emg.datefrom datefrom_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per 
    and emu.id_tipo in(1,2,3) and emg.id_tipo=2 --Elem GMI puede estar en Elem UFyDMD
    and emu.realstate != emg.realstate;
--14    
  CURSOR cur_mi_unigeo_i(pid_per NUMBER)    
  IS
    select emu.objectid objectid_u,emu.valid_code linkvalue_u,emu.sprid sprid_u,emu.normalstate normalstate_u,emu.realstate realstate_u, 
    emg.objectid objectid_g,emg.linkvalue linkvalue_g,emg.sprid sprid_g,emg.normalstate normalstate_g,emg.realstate realstate_g
    from NEXUS_GIS.NUG_EM_unifilar emu,NEXUS_GIS.NUG_EM_geografico emg
    where emu.id_periodo = emg.id_periodo
    and emu.valid_code = emg.linkvalue
    and emu.id_periodo = pid_per 
    and emu.id_tipo in(1,2,3) and emg.id_tipo=2 --Elem GMI puede estar en Elem UFyDMD
    and emu.normalstate = emg.normalstate
    and emu.realstate = emg.realstate;
-------------------fin
vcountgis1 number(10);
vcountgis2 number(10);
vcountgis3 number(10);
vcountgis4 number(10);
vcountgis5 number(10);
vcountgis6 number(10);
vcountgis7 number(10);
vcountgis8 number(10);
vcountgis9 number(10);
vcountgis10 number(10);
vcountgis11 number(10);
vcountgis12 number(10);
vcountgis13 number(10);
vcountgis14 number(10);
vid_per   number(10);
v_valid_code VARCHAR2(100);
v_LINKVALUE VARCHAR2(100);
v_result5 VARCHAR2(100);
v_result6 VARCHAR2(100);
v_result12 VARCHAR2(100);
v_result13 VARCHAR2(100);
v_operationid number(10);
v_tipo_estado VARCHAR2(1);
v_logid_creado number(1);
v_logid number(10);
vconsolidado number(1);
v_eventdata VARCHAR2(200);
v_fecha_periodo VARCHAR2(100);
v_estado_real_u   VARCHAR2(50);
v_estado_normal_u   VARCHAR2(50);
v_estado_real_g   VARCHAR2(50);
v_estado_normal_g   VARCHAR2(50);
BEGIN


       SELECT MAX(id_periodo)  
       INTO vid_per
       from nexus_gis.NUG_PERIODO;

       SELECT consolidado  
       INTO vconsolidado
       from nexus_gis.NUG_PERIODO where id_periodo= vid_per;
       
if vconsolidado = 0    then
		
		select to_char(periodo,'DD/MM/YYYY HH24:MI:SS')
		into v_fecha_periodo
		from nexus_gis.nug_periodo where id_periodo= vid_per;
--1    
BEGIN

   DBMS_OUTPUT.put_line ('Numero y Fecha de corrida del proceso: '||vid_per||' - '||v_fecha_periodo);  
   DBMS_OUTPUT.put_line (' ');
   
   DBMS_OUTPUT.put_line ('1) Elementos de Maniobras del Unifilar con nombres Duplicados');        
   vcountgis1:=0;
   
   FOR cemdu IN cur_em_dupli_uni(vid_per)
   LOOP
        v_valid_code:= cemdu.valid_code;
        FOR cemduu IN cur_em_dupli_uni_u (vid_per,v_LINKVALUE)
        LOOP
                
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,ID_TIPO_LOG)
                VALUES (vid_per,cemduu.objectid,cemduu.valid_code,cemduu.sprid,cemduu.normalstate,cemduu.realstate,1);
                
				select decode(trim(cemduu.normalstate),'15', 'Cerrado','0','Abierto', null) estado_normal, decode(trim(cemduu.realstate),'15', 'Cerrado','0','Abierto', null) estado_real
				into v_estado_normal_u,v_estado_real_u
				from dual;
				--Informo 
				if vcountgis1 = 0 then
                        
                        
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cemduu.objectid||'    '||cemduu.valid_code||'    '||cemduu.sprid||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis1 := vcountgis1 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cemduu.objectid||'    '||cemduu.valid_code||'    '||cemduu.sprid||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis1 := vcountgis1 + 1;
                end if;            
        END LOOP;          
   END LOOP;
    commit;
 
   IF vcountgis1 = 0
   THEN
     DBMS_OUTPUT.put_line ('***     NO HAY Elementos de maniobra del Unifilar con nombres Duplicados       ***');
     DBMS_OUTPUT.put_line ('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Unifilar con nombres Duplicados: '||vcountgis1||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;
END;
--2   
BEGIN
   DBMS_OUTPUT.put_line ('2) Elementos de Maniobras del geografico con nombres Duplicados');        
   vcountgis2:=0;
   
   FOR cemdg IN cur_em_dupli_geo(vid_per)
   LOOP
        v_linkvalue:= cemdg.linkvalue;
        FOR cemdgu IN cur_em_dupli_geo_u (vid_per,v_linkvalue)
        LOOP
                
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cemdgu.objectid,cemdgu.linkvalue,cemdgu.sprid,cemdgu.normalstate,cemdgu.realstate,2);
                
				select decode(trim(cemdgu.normalstate),'15', 'Cerrado','0','Abierto', null) estado_normal, decode(trim(cemdgu.realstate),'15', 'Cerrado','0','Abierto', null) estado_real
				into v_estado_normal_g,v_estado_real_g
				from dual;
				--Informo 
                if vcountgis2 = 0 then
                        
                        
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cemdgu.objectid||'    '||cemdgu.linkvalue||'    '||cemdgu.sprid||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis2 := vcountgis2 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cemdgu.objectid||'    '||cemdgu.linkvalue||'    '||cemdgu.sprid||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis2 := vcountgis2 + 1;
                end if;            
        END LOOP;          
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis2 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Geografico con nombres Duplicados       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del geografico con nombres Duplicados: '||vcountgis2||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************'); 
   END IF; 
END;   
 --3  
BEGIN
   DBMS_OUTPUT.put_line ('3) Elementos de Maniobras del Unifilar que no estan ni fuera ni dentro del MI en el Geografico');        
   vcountgis3:=0;
   
   FOR cemung IN cur_em_uni_no_geo(vid_per)
   LOOP        
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,ID_TIPO_LOG)
                VALUES (vid_per,cemung.objectid_u,cemung.valid_code_u,cemung.sprid_u,cemung.normalstate_u,cemung.realstate_u,3);
				
				select decode(trim(cemung.normalstate_u),'15', 'Cerrado','0','Abierto', null) estado_normal, decode(trim(cemung.realstate_u),'15', 'Cerrado','0','Abierto', null) estado_real
				into v_estado_normal_u,v_estado_real_u
				from dual;               
			   --Informo 
                if vcountgis3 = 0 then
                        
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cemung.objectid_u||'    '||cemung.valid_code_u||'    '||cemung.sprid_u||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis3 := vcountgis3 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cemung.objectid_u||'    '||cemung.valid_code_u||'    '||cemung.sprid_u||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis3 := vcountgis3 + 1;
                end if;            
         
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis3 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Unifilar que no esten en el geografico       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Unifilar que no estan en el Geografico: '||vcountgis3||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;     
END;
 --4  
 BEGIN
   DBMS_OUTPUT.put_line ('4) Elementos de Maniobras fuera o dentro del MI del Geografico que no estan en el Unifilar');        
   vcountgis4:=0;
   
   FOR cemgnu IN cur_em_geo_no_uni(vid_per)
   LOOP        
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cemgnu.objectid_g,cemgnu.linkvalue_g,cemgnu.sprid_g,cemgnu.normalstate_g,cemgnu.realstate_g,4);
               
				select decode(trim(cemgnu.normalstate_g),'15', 'Cerrado','0','Abierto', null) estado_normal, decode(trim(cemgnu.realstate_g),'15', 'Cerrado','0','Abierto', null) estado_real
				into v_estado_normal_g,v_estado_real_g
				from dual;  
				
			   --Informo 
                if vcountgis4 = 0 then
                        
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cemgnu.objectid_g||'    '||cemgnu.linkvalue_g||'    '||cemgnu.sprid_g||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis4 := vcountgis4 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cemgnu.objectid_g||'    '||cemgnu.linkvalue_g||'    '||cemgnu.sprid_g||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis4 := vcountgis4 + 1;
                end if;            
         
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis4 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Geografico que no esten en el Unifilar       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Geografico que no estan en el Unifilar: '||vcountgis4||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;  
END;   
 --5 ok
BEGIN
   DBMS_OUTPUT.put_line ('5) Elementos de Maniobras del Unifilar y del Geografico fuera o dentro del MI, con distintos estados Normales');        
   vcountgis5:=0;
   v_logid_creado:=0;
   v_tipo_estado:='N'; 
   FOR cemugnor IN cur_em_unigeo_normal(vid_per)
   LOOP        
                   --Creo un nuevo logid
                     if v_logid_creado=0 then
                            v_eventdata:='Actualiza estado de Nacimiento Normal MT Geografico';
                            v_logid := edenor_rutinascomunes.getnextid (edenor_rutinascomunes.tabla_sprlog);
                            INSERT INTO sprlog VALUES (v_logid, SYSDATE, 0, 1185, 32, cemugnor.datefrom_g, 1, v_eventdata);
                            v_operationid:=actualizar_estado_objeto(cemugnor.objectid_g,cemugnor.normalstate_u,v_logid,v_tipo_estado);
                            v_logid_creado:=v_logid_creado+1;
                     else
                            v_operationid:=actualizar_estado_objeto(cemugnor.objectid_g,cemugnor.normalstate_u,v_logid,v_tipo_estado);
                     end if;
                        
                    if v_operationid != -1 then 
                        v_result5:= 'OK - OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    else
                        v_result5:= 'ERROR- OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    end if;    
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,ID_TIPO_LOG, PROCESS_DATE,PROCESS_RESULT)
                VALUES (vid_per,cemugnor.objectid_u,cemugnor.valid_code_u,cemugnor.sprid_u,cemugnor.normalstate_u,cemugnor.objectid_g,cemugnor.linkvalue_g,cemugnor.sprid_g,cemugnor.normalstate_g,5,sysdate,v_result5);
                --Informo 
				/*select decode(trim(cemugnor.normalstate_g),'15', 'Cerrado','0','Abierto', null) estado_normal_g,decode(trim(cemugnor.normalstate_u),'15', 'Cerrado','0','Abierto', null) estado_normal_u
				into v_estado_normal_g,v_estado_normal_u
				from dual; 
				
			                if vcountgis5 = 0 then
			                            DBMS_OUTPUT.put_line ('OBJECTID_U    NOMBRE_U    SPRID_U    NORMALSTATE_U    OBJECTID_G    NOMBRE_G    SPRID_G    NORMALSTATE_G        RESULTADO');
			                            DBMS_OUTPUT.put_line ('----------------------------------------------------------------------------------------------------------------------------------------------');
			                            DBMS_OUTPUT.put_line (cemugnor.objectid_u||'    '||cemugnor.valid_code_u||'    '||cemugnor.sprid_u||'    '||v_estado_normal_u||'    '||cemugnor.objectid_g||'    '||cemugnor.linkvalue_g||'    '||cemugnor.sprid_g||'    '||v_estado_normal_g||'        '||v_result5);
			                            vcountgis5 := vcountgis5 + 1;
			                else
			                            DBMS_OUTPUT.put_line (cemugnor.objectid_u||'    '||cemugnor.valid_code_u||'    '||cemugnor.sprid_u||'    '||v_estado_normal_u||'    '||cemugnor.objectid_g||'    '||cemugnor.linkvalue_g||'    '||cemugnor.sprid_g||'    '||v_estado_normal_g||'        '||v_result5);
			                            vcountgis5 := vcountgis5 + 1;
			                end if;
				*/
				vcountgis5 := vcountgis5 + 1;
   END LOOP;
   UPDATE sprlog SET eventstatus = 0 WHERE logid = v_logid;
   commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis5 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Unifilar y Geografico que tengas estados Normales distintos       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Unifilar y del Geografico con distintos estados Normales: '||vcountgis5||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;  
EXCEPTION
   WHEN OTHERS THEN
   UPDATE sprlog SET eventstatus = 2 WHERE logid = v_logid;
   commit;
END;
 --6  ok
BEGIN
   DBMS_OUTPUT.put_line ('6) Elementos de Maniobras del Unifilar y del Geografico con distintos estados Reales');        
   vcountgis6:=0;
   v_logid_creado:=0;
   v_tipo_estado:='S'; 
   FOR cemugreal IN cur_em_unigeo_real(vid_per)
   LOOP        
                
                   --Creo un nuevo logid
                    if v_logid_creado=0 then
							v_eventdata:='Actualiza estado de Nacimiento Real MT Geografico';	
                            v_logid := edenor_rutinascomunes.getnextid (edenor_rutinascomunes.tabla_sprlog);
							INSERT INTO sprlog VALUES (v_logid, SYSDATE, 0, 1185, 32, cemugreal.datefrom_g, 1, v_eventdata);
							v_operationid:=actualizar_estado_objeto(cemugreal.objectid_g,cemugreal.realstate_u,v_logid,v_tipo_estado); 
                            v_logid_creado:=v_logid_creado+1;
					else
							v_operationid:=actualizar_estado_objeto(cemugreal.objectid_g,cemugreal.realstate_u,v_logid,v_tipo_estado); 
                    end if;

                    if v_operationid != -1 then 
                        v_result6:= 'OK - OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    else
                        v_result6:= 'ERROR - OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    end if;    
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,REALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,REALSTATE_G,ID_TIPO_LOG, PROCESS_DATE,PROCESS_RESULT)
                VALUES (vid_per,cemugreal.objectid_u,cemugreal.valid_code_u,cemugreal.sprid_u,cemugreal.realstate_u,cemugreal.objectid_g,cemugreal.linkvalue_g,cemugreal.sprid_g,cemugreal.realstate_g,6,sysdate,v_result6);
                --Informo 
				/*select decode(trim(cemugreal.realstate_u),'15', 'Cerrado','0','Abierto', null) estado_real_u,decode(trim(cemugreal.realstate_g),'15', 'Cerrado','0','Abierto', null) estado_real_g
				into v_estado_real_u,v_estado_real_g
				from dual; 
                
				if vcountgis6 = 0 then
			                            DBMS_OUTPUT.put_line ('OBJECTID_U    NOMBRE_U    SPRID_U    REALSTATE_U    OBJECTID_G    NOMBRE_G    SPRID_G    REALSTATE_G        RESULTADO');
			                            DBMS_OUTPUT.put_line ('-----------------------------------------------------------------------------------------------------------------------------');
			                            DBMS_OUTPUT.put_line (cemugreal.objectid_u||'    '||cemugreal.valid_code_u||'    '||cemugreal.sprid_u||'    '||v_estado_real_u||'    '||cemugreal.objectid_g||'    '||cemugreal.linkvalue_g||'    '||cemugreal.sprid_g||'    '||v_estado_real_g||'        '||v_result6);
			                            vcountgis6 := vcountgis6 + 1;
			                else
			                            DBMS_OUTPUT.put_line (cemugreal.objectid_u||'    '||cemugreal.valid_code_u||'    '||cemugreal.sprid_u||'    '||v_estado_real_u||'    '||cemugreal.objectid_g||'    '||cemugreal.linkvalue_g||'    '||cemugreal.sprid_g||'    '||v_estado_real_g||'        '||v_result6);
			                            vcountgis6 := vcountgis6 + 1;
			                end if;          
				*/	
				vcountgis6 := vcountgis6 + 1;		
   END LOOP;
   UPDATE sprlog SET eventstatus = 0 WHERE logid = v_logid;
   commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis6 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Unifilar y Geografico que tengas estados Reales distintos       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Unifilar y del Geografico con distintos estados Reales: '||vcountgis6||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF; 
EXCEPTION
   WHEN OTHERS THEN
   UPDATE sprlog SET eventstatus = 2 WHERE logid = v_logid;
   commit;   
END;
 --7 ok
BEGIN 
   DBMS_OUTPUT.put_line ('7) Elementos de Maniobras del Unifilar y del Geografico con iguales estados Normales y Reales');        
   vcountgis7:=0;
   
   FOR cemugi IN cur_em_unigeo_i(vid_per)
   LOOP        
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cemugi.objectid_u,cemugi.valid_code_u,cemugi.sprid_u,cemugi.normalstate_u,cemugi.realstate_u,cemugi.objectid_g,cemugi.linkvalue_g,cemugi.sprid_g,cemugi.normalstate_g,cemugi.realstate_g,7);
                --Informo 
               /* if vcountgis7 = 0 then
                        
                            DBMS_OUTPUT.put_line ('ID_PERIODO    OBJECTID_U    LINKVALUE_U    SPRID_U    NORMALSTATE_U    REALSTATE_U    OBJECTID_G    LINKVALUE_G    SPRID_G    NORMALSTATE_G    REALSTATE_G');
                            DBMS_OUTPUT.put_line ('----------------------------------------------------------------------------------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (vid_per||'    '||cemugi.objectid_u||'    '||cemugi.valid_code_u||'    '||cemugi.sprid_u||'    '||cemugi.normalstate_u||'    '||cemugi.realstate_u||'    '||cemugi.objectid_g||'    '||cemugi.linkvalue_g||'    '||cemugi.sprid_g||'    '||cemugi.normalstate_g||'    '||cemugi.realstate_g);
                            vcountgis7 := vcountgis7 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (vid_per||'    '||cemugi.objectid_u||'    '||cemugi.valid_code_u||'    '||cemugi.sprid_u||'    '||cemugi.normalstate_u||'    '||cemugi.realstate_u||'    '||cemugi.objectid_g||'    '||cemugi.linkvalue_g||'    '||cemugi.sprid_g||'    '||cemugi.normalstate_g||'    '||cemugi.realstate_g);
                            vcountgis7 := vcountgis7 + 1;
                end if;            
			*/
			 vcountgis7 := vcountgis7 + 1;
   END LOOP;
    commit;
  -- DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis7 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Unifilar y Geografico que tengas estados Normales y Reales iguales       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Unifilar y del Geografico con iguales estados Normales y Reales:'||vcountgis7||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;  
END;   
-------Comienzo
--8  ok
BEGIN
   DBMS_OUTPUT.put_line ('8) Elementos de Maniobras del Mundo Interno del Unifilar con nombres Duplicados');        
   vcountgis8:=0;
   
   FOR cmid IN cur_mi_dupli_uni(vid_per)
   LOOP
        v_LINKVALUE:= cmid.valid_code;
        FOR cmidu IN cur_mi_dupli_uni_u (vid_per,v_LINKVALUE)
        LOOP
                
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,ID_TIPO_LOG)
                VALUES (vid_per,cmidu.objectid,cmidu.valid_code,cmidu.sprid,cmidu.normalstate,cmidu.realstate,8);
                --Informo 
				select decode(trim(cmidu.normalstate),'15', 'Cerrado','0','Abierto', null) estado_normal_u,decode(trim(cmidu.realstate),'15', 'Cerrado','0','Abierto', null) estado_real_u
				into v_estado_normal_u,v_estado_real_u
				from dual; 
				
                if vcountgis8 = 0 then
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cmidu.objectid||'    '||cmidu.valid_code||'    '||cmidu.sprid||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis8 := vcountgis8 + 1;
                else
                            DBMS_OUTPUT.put_line (cmidu.objectid||'    '||cmidu.valid_code||'    '||cmidu.sprid||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis8 := vcountgis8 + 1;
                end if;            
        END LOOP;          
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis8 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Unifilar con nombres Duplicados       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del Unifilar con nombres Duplicados:'||vcountgis8||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;
END;
--9  ok
BEGIN
   DBMS_OUTPUT.put_line ('9) Elementos de Maniobras del Mundo Interno del geografico con nombres Duplicados');        
   vcountgis9:=0;
   
   FOR cmidg IN cur_mi_dupli_geo(vid_per)
   LOOP
        v_linkvalue:= cmidg.linkvalue;
        FOR cmidgu IN cur_mi_dupli_geo_u (vid_per,v_linkvalue)
        LOOP
                
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cmidgu.objectid,cmidgu.linkvalue,cmidgu.sprid,cmidgu.normalstate,cmidgu.realstate,9);
                --Informo 
				select decode(trim(cmidgu.normalstate),'15', 'Cerrado','0','Abierto', null) estado_normal_g,decode(trim(cmidgu.realstate),'15', 'Cerrado','0','Abierto', null) estado_real_g
				into v_estado_normal_g,v_estado_real_g
				from dual; 
                
				if vcountgis9 = 0 then
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cmidgu.objectid||'    '||cmidgu.linkvalue||'    '||cmidgu.sprid||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis9 := vcountgis9 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cmidgu.objectid||'    '||cmidgu.linkvalue||'    '||cmidgu.sprid||'    '||v_estado_normal_g||'    '||v_estado_real_g);
                            vcountgis9 := vcountgis9 + 1;
                end if;            
        END LOOP;          
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis9 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Geografico con nombres Duplicados       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del geografico con nombres Duplicados:'||vcountgis9||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF; 
END;   
 --10   ok
 BEGIN
   DBMS_OUTPUT.put_line ('10) Elementos de Maniobras de Mundo Interno del Unifilar que no estan en el Geografico');        
   vcountgis10:=0;
   
   FOR cmiung IN cur_mi_uni_no_geo(vid_per)
   LOOP        
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,ID_TIPO_LOG)
                VALUES (vid_per,cmiung.objectid_u,cmiung.linkvalue_u,cmiung.sprid_u,cmiung.normalstate_u,cmiung.realstate_u,10);
                --Informo
				select decode(trim(cmiung.normalstate_u),'15', 'Cerrado','0','Abierto', null) estado_normal_u,decode(trim(cmiung.realstate_u),'15', 'Cerrado','0','Abierto', null) estado_real_u
				into v_estado_normal_u,v_estado_real_u
				from dual; 
				
                if vcountgis10 = 0 then
                        
                            DBMS_OUTPUT.put_line ('OBJECTID    NOMBRE    SPRID    NORMALSTATE    REALSTATE    ');
                            DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
                            DBMS_OUTPUT.put_line (cmiung.objectid_u||'    '||cmiung.linkvalue_u||'    '||cmiung.sprid_u||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis10 := vcountgis10 + 1;
                else
                        
                
                            DBMS_OUTPUT.put_line (cmiung.objectid_u||'    '||cmiung.linkvalue_u||'    '||cmiung.sprid_u||'    '||v_estado_normal_u||'    '||v_estado_real_u);
                            vcountgis10 := vcountgis10 + 1;
                end if;            
         
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis10 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Unifilar que no esten en el geografico       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras de Mundo Interno del Unifilar que no estan en el Geografico:'||vcountgis10||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;     
END;
 --11  ok
BEGIN
   DBMS_OUTPUT.put_line ('11) Elementos de Maniobras del Mundo Interno del Geografico que no estan en el Unifilar');        
   vcountgis11:=0;
   
   FOR cmignu IN cur_mi_geo_no_uni(vid_per)
   LOOP        
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cmignu.objectid_g,cmignu.linkvalue_g,cmignu.sprid_g,cmignu.normalstate_g,cmignu.realstate_g,11);
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
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis11 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del mundo Interno del Geografico que no esten en el Unifilar       ***');
	  DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del Geografico que no estan en el Unifilar:'||vcountgis11||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;     
END;
 --12 ok
BEGIN
   DBMS_OUTPUT.put_line ('12) Elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con distintos estados Normales');        
   vcountgis12:=0;
   v_logid_creado:=0;
   v_tipo_estado:='N'; 
   FOR cmiugnor IN cur_mi_unigeo_normal(vid_per)
   LOOP        
                   --Creo un nuevo logid
                     if v_logid_creado=0 then
							v_eventdata:='Actualiza estado de Nacimiento Normal MT Geografico';
                            v_logid := edenor_rutinascomunes.getnextid (edenor_rutinascomunes.tabla_sprlog);
							INSERT INTO sprlog VALUES (v_logid, SYSDATE, 0, 1185, 32, cmiugnor.datefrom_g, 1, v_eventdata);
							v_operationid:=actualizar_estado_objeto(cmiugnor.objectid_g,cmiugnor.normalstate_u,v_logid,v_tipo_estado); 
                            v_logid_creado:=v_logid_creado+1;
					 else
							v_operationid:=actualizar_estado_objeto(cmiugnor.objectid_g,cmiugnor.normalstate_u,v_logid,v_tipo_estado); 
                     end if;

					 if v_operationid != -1 then 
                        v_result12:= 'OK - OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    else
                        v_result12:= 'ERROR - OPERATIONID: '||v_operationid||' - Logid: '||v_logid;
                    end if;    
                    
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,ID_TIPO_LOG, PROCESS_DATE,PROCESS_RESULT)
                VALUES (vid_per,cmiugnor.objectid_u,cmiugnor.linkvalue_u,cmiugnor.sprid_u,cmiugnor.normalstate_u,cmiugnor.objectid_g,cmiugnor.linkvalue_g,cmiugnor.sprid_g,cmiugnor.normalstate_g,12,sysdate,v_result12);
                --Informo 
				/*select decode(cmiugnor.normalstate_u,'15', 'Cerrado','0','Abierto', null) estado_normal_u,decode(cmiugnor.normalstate_g,'15', 'Cerrado','0','Abierto', null) estado_normal_g
				into v_estado_normal_u,v_estado_normal_g
				from dual; 
				
			                if vcountgis12 = 0 then
			                        
			                            DBMS_OUTPUT.put_line ('OBJECTID_U    NOMBRE_U    SPRID_U    NORMALSTATE_U    OBJECTID_G    NOMBRE_G    SPRID_G    NORMALSTATE_G        RESULTADO');
			                            DBMS_OUTPUT.put_line ('----------------------------------------------------------------------------------------------------------------------------------------------');
			                            DBMS_OUTPUT.put_line (cmiugnor.objectid_u||'    '||cmiugnor.linkvalue_u||'    '||cmiugnor.sprid_u||'    '||v_estado_normal_u||'    '||cmiugnor.objectid_g||'    '||cmiugnor.linkvalue_g||'    '||cmiugnor.sprid_g||'    '||v_estado_normal_g||'        '||v_result12);
			                            vcountgis12 := vcountgis12 + 1;
			                else
			                        
			                
			                            DBMS_OUTPUT.put_line (cmiugnor.objectid_u||'    '||cmiugnor.linkvalue_u||'    '||cmiugnor.sprid_u||'    '||v_estado_normal_u||'    '||cmiugnor.objectid_g||'    '||cmiugnor.linkvalue_g||'    '||cmiugnor.sprid_g||'    '||v_estado_normal_g||'        '||v_result12);
			                            vcountgis12 := vcountgis12 + 1;
			                end if;     
				*/	
				vcountgis12 := vcountgis12 + 1;
   END LOOP;
    UPDATE sprlog SET eventstatus = 0 WHERE logid = v_logid;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis12 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Unifilar y Geografico que tengan estados Normales distintos       ***');
      DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con distintos estados Normales:'||vcountgis12||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
   UPDATE sprlog SET eventstatus = 2 WHERE logid = v_logid;
   commit;
END;   
 --13  ok
BEGIN
   DBMS_OUTPUT.put_line ('13) Elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con distintos estados Reales');        
   vcountgis13:=0;
   v_logid_creado:=0;
   v_tipo_estado:='S';
   FOR cmiugreal IN cur_mi_unigeo_real(vid_per)
   LOOP        
                
                   --Creo un nuevo logid
                     if v_logid_creado=0 then
							v_eventdata:='Actualiza estado de Nacimiento Real MT Geografico';	
                            v_logid := edenor_rutinascomunes.getnextid (edenor_rutinascomunes.tabla_sprlog);
							INSERT INTO sprlog VALUES (v_logid, SYSDATE, 0, 1185, 32, cmiugreal.datefrom_g, 1, v_eventdata);
							v_operationid:=actualizar_estado_objeto(cmiugreal.objectid_g,cmiugreal.realstate_u,v_logid,v_tipo_estado); 
                            v_logid_creado:=v_logid_creado+1;
					 else
							v_operationid:=actualizar_estado_objeto(cmiugreal.objectid_g,cmiugreal.realstate_u,v_logid,v_tipo_estado); 	
                     end if;
                       
                    if v_operationid != -1 then 
                        v_result13:= 'OK - OPERATIONID: '||v_operationid;
                    else
                        v_result13:= 'ERROR';
                    end if;    
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,REALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,REALSTATE_G,ID_TIPO_LOG, PROCESS_DATE,PROCESS_RESULT)
                VALUES (vid_per,cmiugreal.objectid_u,cmiugreal.linkvalue_u,cmiugreal.sprid_u,cmiugreal.realstate_u,cmiugreal.objectid_g,cmiugreal.linkvalue_g,cmiugreal.sprid_g,cmiugreal.realstate_g,13,sysdate,v_result13);
                --Informo 
				/*select decode(cmiugreal.realstate_u,'15', 'Cerrado','0','Abierto', null) estado_real_u,decode(cmiugreal.realstate_g,'15', 'Cerrado','0','Abierto', null) estado_real_g
				into v_estado_real_u,v_estado_real_g
				from dual; 
				
		                if vcountgis13 = 0 then
		                        
		                            DBMS_OUTPUT.put_line ('OBJECTID_U    NOMBRE_U    SPRID_U    REALSTATE_U    OBJECTID_G    NOMBRE_G    SPRID_G    REALSTATE_G        RESULTADO');
		                            DBMS_OUTPUT.put_line ('-----------------------------------------------------------------------------------------------------------------------------');
		                            DBMS_OUTPUT.put_line (cmiugreal.objectid_u||'    '||cmiugreal.linkvalue_u||'    '||cmiugreal.sprid_u||'    '||v_estado_real_u||'    '||cmiugreal.objectid_g||'    '||cmiugreal.linkvalue_g||'    '||cmiugreal.sprid_g||'    '||v_estado_real_g||'        '||v_result13);
		                            vcountgis13 := vcountgis13 + 1;
		                else
		                        
		                
		                            DBMS_OUTPUT.put_line (cmiugreal.objectid_u||'    '||cmiugreal.linkvalue_u||'    '||cmiugreal.sprid_u||'    '||v_estado_real_u||'    '||cmiugreal.objectid_g||'    '||cmiugreal.linkvalue_g||'    '||cmiugreal.sprid_g||'    '||v_estado_real_g||'        '||v_result13);
		                            vcountgis13 := vcountgis13 + 1;
		                end if;            
			*/
			 vcountgis13 := vcountgis13 + 1;
   END LOOP;
    UPDATE sprlog SET eventstatus = 0 WHERE logid = v_logid;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis13 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Unifilar y Geografico que tengas estados Reales distintos       ***');
      DBMS_OUTPUT.put_line('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con distintos estados Reales:'||vcountgis13||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
   UPDATE sprlog SET eventstatus = 2 WHERE logid = v_logid;
   commit;   
END;
 --14 ok
BEGIN
   DBMS_OUTPUT.put_line ('14) Elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con iguales estados Normales y Reales');        
   vcountgis14:=0;
   
   FOR cmiugi IN cur_mi_unigeo_i(vid_per)
   LOOP        
                    
                --Actualizo la tabla Log
                insert into nexus_gis.nug_log (ID_PERIODO,OBJECTID_U,LINKVALUE_U,SPRID_U,NORMALSTATE_U,REALSTATE_U,OBJECTID_G,LINKVALUE_G,SPRID_G,NORMALSTATE_G,REALSTATE_G,ID_TIPO_LOG)
                VALUES (vid_per,cmiugi.objectid_u,cmiugi.linkvalue_u,cmiugi.sprid_u,cmiugi.normalstate_u,cmiugi.realstate_u,cmiugi.objectid_g,cmiugi.linkvalue_g,cmiugi.sprid_g,cmiugi.normalstate_g,cmiugi.realstate_g,14);
                --Informo 
                /*if vcountgis14 = 0 then
                        
			                            DBMS_OUTPUT.put_line ('ID_PERIODO    OBJECTID_U    LINKVALUE_U    SPRID_U    NORMALSTATE_U    REALSTATE_U    OBJECTID_G    LINKVALUE_G    SPRID_G    NORMALSTATE_G    REALSTATE_G');
			                            DBMS_OUTPUT.put_line ('----------------------------------------------------------------------------------------------------------------------------------------------------------');
			                            DBMS_OUTPUT.put_line (vid_per||'    '||cmiugi.objectid_u||'    '||cmiugi.linkvalue_u||'    '||cmiugi.sprid_u||'    '||cmiugi.normalstate_u||'    '||cmiugi.realstate_u||'    '||cmiugi.objectid_g||'    '||cmiugi.linkvalue_g||'    '||cmiugi.sprid_g||'    '||cmiugi.normalstate_g||'    '||cmiugi.realstate_g);
			                            vcountgis14 := vcountgis14 + 1;
			                else
			                        
			                
			                            DBMS_OUTPUT.put_line (vid_per||'    '||cmiugi.objectid_u||'    '||cmiugi.linkvalue_u||'    '||cmiugi.sprid_u||'    '||cmiugi.normalstate_u||'    '||cmiugi.realstate_u||'    '||cmiugi.objectid_g||'    '||cmiugi.linkvalue_g||'    '||cmiugi.sprid_g||'    '||cmiugi.normalstate_g||'    '||cmiugi.realstate_g);
			                            vcountgis14 := vcountgis14 + 1;
			                end if;            
			*/
		vcountgis14 := vcountgis14 + 1;
   END LOOP;
    commit;
   --DBMS_OUTPUT.put_line('---------------------------------------------------------------------------------------------------------------------------');
   IF vcountgis14 = 0
   THEN
      DBMS_OUTPUT.put_line('***     NO HAY Elementos de maniobra del Mundo Interno del Unifilar y Geografico que tengas estados Normales y Reales iguales       ***');
	  DBMS_OUTPUT.put_line ('*******************************************************************************************************************');
	ELSE
	 DBMS_OUTPUT.put_line('***   Cantidad de elementos de Maniobras del Mundo Interno del Unifilar y del Geografico con iguales estados Normales y Reales:'||vcountgis14||'   ***');
     DBMS_OUTPUT.put_line('*******************************************************************************************************************');
   END IF;
END;   
-------    Fin
    -- Consolido el periodo
	update nug_periodo set consolidado = 1 where id_periodo = vid_per;
	-- Elimino el log de periodos mas de 30 días 
	delete from nexus_gis.nug_log where id_periodo in(select id_periodo from nexus_gis.nug_periodo where periodo < sysdate-30);
	delete from nexus_gis.nug_em_unifilar where id_periodo in(select id_periodo from nexus_gis.nug_periodo where periodo < sysdate-30);
    delete from nexus_gis.nug_em_geografico where id_periodo in(select id_periodo from nexus_gis.nug_periodo where periodo < sysdate-30);
	commit;
else
    DBMS_OUTPUT.put_line ('No existen periodos que no esten consolidados');
end if;
   
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.put_line ('ROLLBACK, hay ERROR: '|| SUBSTR (SQLERRM, 1, 100));
      ROLLBACK;
END;  
/

----------------------------
-- End your script here   --
----------------------------
ENDSQL

echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Detalle Ejecucion proceso ............... \n" >>$FILE_LOG
	
mailx -s "Diferencias y actualizacion de Estados Normales y Reales en EM del Geografico MT"  LD_NEXUS_PRODUCCION@edenor.com,diaciancio@edenor.com <$FILE_AUX	
	
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





