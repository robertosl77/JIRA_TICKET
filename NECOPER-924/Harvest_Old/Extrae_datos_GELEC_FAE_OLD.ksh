#!/usr/bin/ksh


# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa
# LOG_DIR=/stage/gis/imple/procesos/TMT/trans/TPR/batch/logs
# DATE=$( date +%y%m%d%H%M )
DATE=$( date +%d%m%Y )
FILE_LOG=$LOG_DIR/Extrae_datos_GELEC_FAE.ksh_$DATE.log
FILE_AUX=$LOG_DIR/Extrae_datos_GELEC_FAE.ksh.aux

USER=GELEC
ARCH_SPOOL=$OUT_DIR/datosfae.csv
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
set linesize 500
set verify off
set feed off
set trimspool on

-- Inicia el proceso aqui --
-- GESTDEM-696
-- NECOPER-382
----------------------------

DECLARE
	
	CURSOR repo_fae IS
		select 
			  fc.cuenta, 
			  (select upper(trim(nombre||chr(32)||apellido)) from GELEC.ed_paciente_cliente where cuenta=fc.cuenta and rownum=1) paciente,
			  upper(trim(cc.calle||chr(32)||cc.nro||chr(32)||trim(cc.piso_dpto))||chr(32)||chr(40)||trim(cc.localidad)||chr(41)) direccion, 
			  cc.medidor, 
			  CC.REGION, 
			  upper((SELECT z.zona FROM NEXUS_GIS.SPRCLIENTS s, nexus_gis.partido_zona z where s.fsclientid=cc.cuenta and s.leveltwoareaid=z.areaid)) zona,
			  cc.ct, 
			  fe.serie, 
			  fe.potencia, 
			  fe.capacidad, 
			  fc.instalacion, 
			  fc.retiro, 
			  'ORD-'||to_char(fo.inicio,'YYYY-MM')||'-'||lpad(fo.id,5,0) nro_orden,
			  ot.descripcion tipo, 
			  fo.usuario, 
			  fo.inicio, 
			  FO.FIN, 
			  eo.descripcion estado, 
			  fo.abonada, 
			  fo.fecha_abonada
		from 
			  GELEC.ed_fae_cliente fc, 
			  GELEC.ed_ordenes fo, 
			  GELEC.ed_clientes cc, 
			  GELEC.ed_equipo_fae fe, 
			  GELEC.ed_tipo_orden ot, 
			  GELEC.ED_ESTADO_FAE EF,
			  GELEC.ED_ESTADO_ORDENES EO
		where
			  1=1
			  and fc.id=fo.id_fae_cliente
			  and fc.cuenta=cc.cuenta
			  and fc.id_fae=fe.id(+)
			  and fo.id_tipo=ot.id
			  AND FO.ID_ESTADO=EF.ID
			  and fo.id_estado=eo.id
		order by
			  fc.cuenta, 
			  fo.inicio
		;
	
BEGIN
		
	dbms_output.put_line('CUENTA|PACIENTE|DIRECCION|MEDIDOR|REGION|ZONA|CT|SERIE|POTENCIA|CAPACIDAD|INSTALACION|RETIRO|NRO_ORDEN|TIPO|USUARIO|INICIO|FIN|ESTADO|ABONADA|FECHA_ABONADA');

	for fae in repo_fae loop
		begin                        
				DBMS_OUTPUT.PUT_LINE(
					fae.cuenta|| '|' ||fae.paciente|| '|' ||fae.direccion|| '|' ||fae.medidor|| '|' ||fae.region|| '|' ||fae.zona|| '|' ||
					fae.ct|| '|' ||fae.serie|| '|' ||fae.potencia|| '|' ||fae.capacidad|| '|' ||fae.instalacion|| '|' ||fae.retiro|| '|' ||
					fae.nro_orden|| '|' ||fae.tipo|| '|' ||fae.usuario|| '|' ||fae.inicio|| '|' ||fae.fin|| '|' ||fae.estado|| '|' ||
					fae.abonada|| '|' ||fae.fecha_abonada);
		end;
	end loop;
	
	--DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso Finalizado CORRECTAMENTE.');
	
EXCEPTION
        WHEN others THEN
            DBMS_OUTPUT.PUT_LINE('RESULTADO: Proceso Finalizado con ERROR.'||SQLERRM);
END;
/
spool OFF;
----------------------------
-- End your script here   --
----------------------------
ENDSQL

echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Detalle Ejecucion proceso ............... \n" >>$FILE_LOG

cat $FILE_AUX >>$FILE_LOG

echo "\n
    * $(date '+%d/%m/%y %H:%M:%S') - Fin Ejecucion proceso ............... \n" >>$FILE_LOG

rm $FILE_AUX

exit_error=`cat $FILE_LOG | grep 'ORA-' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 9
fi

exit_error=`cat $FILE_LOG | grep 'ERROR' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 10
fi

#exit_error=`cat $FILE_LOG | grep 'CASOS' | wc -l | awk -F" " '{print $1}'`
#if [[ ${exit_error} -gt 0 ]]; then
#exit 0
#fi
