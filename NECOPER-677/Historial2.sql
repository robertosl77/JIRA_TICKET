SET SERVEROUTPUT ON
DECLARE

    cursor c_cruzados is 
        SELECT CUENTA, CT_CLIE CT, ID_DOCUMENTO, FECHA_INICIO_CORTE, FECHA_FIN_CORTE, ULTIMA_MODIFICACION FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES WHERE FECHA_INICIO_CORTE>FECHA_FIN_CORTE;

    CURSOR C_TIEMPOS (P_DOCUMENTO NUMBER, P_FECHA VARCHAR2) IS
        SELECT * FROM NEXUS_GIS.OMS_AFFECT_RESTORE_OPERATION ARO
        WHERE
            1=1
            AND ARO.OPERATION_ID IS NOT NULL
            AND ARO.DOCUMENT_ID=p_documento
            AND ARO.LAST_MODIFIED_DATE= TO_DATE(p_fecha)
            
        ;

BEGIN
    for f_cruzados in c_cruzados loop
    
        for f_tiempos in c_tiempos(f_cruzados.id_documento, f_cruzados.fecha_inicio_corte) loop
        
            DBMS_OUTPUT.PUT_LINE(
                F_CRUZADOS.CUENTA
                ||','||F_CRUZADOS.CT
                ||','||F_CRUZADOS.ID_DOCUMENTO
                ||','||F_CRUZADOS.CT
                ||','||F_CRUZADOS.CT
                ||','||F_CRUZADOS.CT
                );
        
        end loop;
    
    
    end loop;

end;








