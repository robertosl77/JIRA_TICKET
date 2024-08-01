#!/usr/bin/ksh

# Seteo de variables de entorno
. ~/ScriptsNexusGIS.properties

# Definicion de variables de programa

DATE=$( date +%d%m%y%H%M )
FILE_LOG=$LOG_DIR/DLSOT-1689_Modifica_campo_Mail.ksh_$DATE.log
FILE_AUX=$LOG_DIR/DLSOT-1689_Modifica_campo_Mail.ksh.log

USER=GELEC
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
set linesize 120
set verify off
set feed off
----------------------------
-- Start your script here --
--NECOPER-923>DLSOT-1689: se requiere modificar la cantidad de caracteres del campo MAIL de la tabla GELEC.ED_CONTRATISTAS
----------------------------
/* Formatted on 25/01/2023 16:14 (QP5 v5.294) */
declare

begin 

    begin
        execute immediate
            'alter table gelec.ed_contratistas modify mail varchar(100 char)';
            
        commit;
        
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (2, 'Empresa 2','CDD2', 'centro_de_diagnostico@edenor.com', null); 
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (3, 'Empresa 3','CDD3', 'centro_de_diagnostico@edenor.com', null);
        insert into gelec.ed_contratistas (id, nombre, grupo, mail, telefono) values 
            (4, 'Empresa 4','CDD4', 'centro_de_diagnostico@edenor.com', null); 
        
        commit;
    exception
        when others then
            dbms_output.put_line('Se detecto error al modificar el proceso');
    end;        
    
end;
/
 

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

exit_error=`cat $FILE_LOG | grep 'ERRORES' | wc -l | awk -F" " '{print $1}'`
if [[ ${exit_error} -gt 0 ]]; then
exit 10
fi