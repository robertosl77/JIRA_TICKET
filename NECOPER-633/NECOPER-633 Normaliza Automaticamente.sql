--select * from gelec.ed_documentos where nro_documento='D-21-10-000003';
--select * from gelec.ed_det_documentos_clientes where id_documento=9143748;
--update gelec.ed_det_documentos_clientes set fecha_fin_corte= to_date('17/11/2022 15:45:04') where id_doc_cliente=2074;
--update gelec.ed_det_documentos_clientes set ESTADO_CLIE='Pendiente', log_hasta=null, fecha_fin_editable=null where id_doc_cliente=2074;
--SELECT * FROM GELEC.ED_NOTAS N, GELEC.ED_CLIENTE_NOTA CN WHERE N.ID_NOTA=CN.ID_NOTA ORDER BY N.ID_NOTA DESC;

SET SERVEROUTPUT ON
DECLARE

    CURSOR C_NORMALES IS 
        SELECT
            (SELECT NRO_DOCUMENTO FROM GELEC.ED_DOCUMENTOS WHERE ID_DOCUMENTO=DC.ID_DOCUMENTO) NRO_DOCUMENTO, 
            DC.ID_DOCUMENTO, 
            DC.ID_DOC_CLIENTE,
            DC.CUENTA, 
            DC.CT_CLIE CT, 
            dc.fecha_inicio_corte, 
            DC.FECHA_FIN_CORTE, 
            DC.LOG_HASTA
        FROM 
            GELEC.ED_DET_DOCUMENTOS_CLIENTES DC
        WHERE 
            NVL(DC.LOG_HASTA,0)=0                                                   --solo afectaciones activas
            AND DC.FECHA_FIN_CORTE IS NOT NULL                                      --con fecha de fin no nula
            AND UPPER(ESTADO_CLIE) ='PENDIENTE'                                            --solo con estado Pendiente
            AND (SELECT TIPO_CORTE FROM GELEC.ED_DOCUMENTOS WHERE ID_DOCUMENTO=DC.ID_DOCUMENTO) IN ('Forzado AT', 'Programado AT', 'Forzado MT', 'Programado MT')   --solo para estos tipos de corte
            AND (SELECT COUNT(1) FROM GELEC.ED_RECLAMOS WHERE ID_DOCUMENTO=DC.ID_DOCUMENTO AND CUENTA=DC.CUENTA and descripcion not like '%Created by event Last Gasp%')= 0         --si no realizo reclamos
--            AND (SELECT COUNT(1) FROM GELEC.ED_NOTAS N, GELEC.ED_CLIENTE_NOTA CN WHERE N.ID_NOTA=CN.ID_NOTA AND CN.CUENTA=DC.CUENTA AND N.FECHAALERTA IS NOT NULL AND N.ID_TIPO_NOTA=6 AND NVL(N.LOG_HASTA,0)=0)=0                    --sin alertas
            AND DC.FECHA_INICIO_CORTE<=DC.FECHA_FIN_CORTE                           --con fecha de inicio inferior a la de fin
            AND TRUNC((DC.FECHA_FIN_CORTE-DC.FECHA_INICIO_CORTE)*60*24)<20          --afectaciones con duracion menor a x tiempo
            and rownum<=5
    ;
        
    CURSOR C_ALERTAS (P_DOCUMENTO NUMBER, P_CUENTA VARCHAR2) IS
        SELECT N.ID_NOTA 
        FROM GELEC.ED_NOTAS N, GELEC.ED_CLIENTE_NOTA CN 
        WHERE N.ID_NOTA=CN.ID_NOTA 
        AND N.FECHAALERTA IS NOT NULL 
        AND N.ID_TIPO_NOTA=6 
        AND NVL(N.LOG_HASTA,0)=0 
        AND CN.ID_DOCUMENTO=P_DOCUMENTO 
        AND CN.CUENTA=P_CUENTA
    ; 
    
    
    --variable de control de errores    
    V_ERROR NUMBER;    
    --variable para insertar en ed_notas
    P_USER_ID VARCHAR2(200);
    P_NOTA VARCHAR2(200);
    P_ID_DESTINO VARCHAR2(200);
    P_EFECTIVO VARCHAR2(200);
    P_ID_TIPO_NOTA VARCHAR2(200);
    P_ID_SUBTIPO_NOTA VARCHAR2(200);
    P_ID_FECHA_ALERTA DATE;
    P_DESCRIPCION_LOG VARCHAR2(200);
    P_ORIGEN VARCHAR2(200);
    P_ID_NOTA VARCHAR2(200);
    P_LOG_DESDE VARCHAR2(200);         
    --variable para insertar en ed_cliente_nota
    P_ID_DOCUMENT VARCHAR2(200);
    P_CUENTA VARCHAR2(200);
--    P_USER_ID VARCHAR2(200);
--    P_ID_NOTA VARCHAR2(200);
    P_RESULTADO VARCHAR2(200);  
    --variable para cerrar alertas
--    P_ID_NOTA VARCHAR2(200);
    P_LOGHASTA NUMBER;
    P_USUARIO VARCHAR2(200);
--    P_RESULTADO VARCHAR2(200);      
  
begin
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------');    
    DBMS_OUTPUT.PUT_LINE('Documento;id_documento;id_doc_cliente;cuenta;ct;fecha_inicio;fecha_fin;log_hasta');
    
    FOR F_NORMALES IN C_NORMALES LOOP
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE(F_NORMALES.NRO_DOCUMENTO||';'||F_NORMALES.ID_DOCUMENTO||';'||F_NORMALES.ID_DOC_CLIENTE||';'||F_NORMALES.CUENTA||';'||F_NORMALES.CT||';'||F_NORMALES.FECHA_INICIO_CORTE||';'||F_NORMALES.FECHA_FIN_CORTE||';'||F_NORMALES.LOG_HASTA);
        
        V_ERROR:=0;
        if v_error=0 then
            --cambia estado de a normalizado y el error lo setea a 1
            begin
                UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES 
                SET 
                    ESTADO_CLIE='Normalizado',                  --normaliza automaticamente
                    FECHA_FIN_EDITABLE= FECHA_FIN_CORTE         --copia la fecha de fin a la de fin editable para que se vea en gelec cuando se normalizo
                WHERE ID_DOC_CLIENTE= F_NORMALES.ID_DOC_CLIENTE AND CUENTA=F_NORMALES.CUENTA;
                v_error:=1;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Se ocasiono un error al intentar normalizar automaticamente el id_doc_cliente '||F_NORMALES.ID_DOC_CLIENTE);
                    v_error:=0;
            END;
        end if;
        
        IF V_ERROR=1 THEN
            BEGIN
                --inserta la nota de la normalizacion automatica en ed_notas
                P_USER_ID :=          'Aplicacion';
                P_NOTA :=             'Normalizacion Automatica por afectacion de menor tiempo.';
                P_ID_DESTINO :=       NULL;
                P_EFECTIVO :=         NULL;
                P_ID_TIPO_NOTA :=     '1';
                P_ID_SUBTIPO_NOTA :=  NULL;
                P_ID_FECHA_ALERTA :=  NULL;
                P_DESCRIPCION_LOG :=  'Normalizacion Automatica por afectacion de menor tiempo.';
                P_ORIGEN :=           'Batch';
                P_ID_NOTA :=          NULL;
                P_LOG_DESDE :=        NULL;
                
                GELEC.PKG_NOTAS.INSERTAR_NOTA (  
                    P_USER_ID => P_USER_ID,
                    P_NOTA => P_NOTA,
                    P_ID_DESTINO => P_ID_DESTINO,
                    P_EFECTIVO => P_EFECTIVO,
                    P_ID_TIPO_NOTA => P_ID_TIPO_NOTA,
                    P_ID_SUBTIPO_NOTA => P_ID_SUBTIPO_NOTA,
                    P_ID_FECHA_ALERTA => P_ID_FECHA_ALERTA,
                    P_DESCRIPCION_LOG => P_DESCRIPCION_LOG,
                    P_ORIGEN => P_ORIGEN,
                    P_ID_NOTA => P_ID_NOTA,
                    P_LOG_DESDE => P_LOG_DESDE) ;  
                
                v_error:=2;    
                
                DBMS_OUTPUT.PUT_LINE('ID_Nota: '||P_ID_NOTA);
                DBMS_OUTPUT.PUT_LINE('ID_Log_Desde: '||P_LOG_DESDE);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Se ocasiono un error al insertar la nota. '||F_NORMALES.ID_DOC_CLIENTE);
                    V_ERROR:=0;                    
            END;                
        END IF;
        
        IF V_ERROR=2 THEN
            BEGIN
                --inserta la nota de la normalizacion automatica en ed_cliente_nota
                P_ID_DOCUMENT :=  F_NORMALES.ID_DOCUMENTO;
                P_CUENTA :=       F_NORMALES.CUENTA;
--                P_USER_ID :=      'Aplicacion';
--                P_ID_NOTA :=    NULL;
                P_RESULTADO :=    NULL;

                PKG_NOTAS.ASOCIAR_NOTA (  
                    P_ID_DOCUMENT => P_ID_DOCUMENT,
                    P_CUENTA => P_CUENTA,
                    P_USER_ID => P_USER_ID,
                    P_ID_NOTA => P_ID_NOTA,
                    P_RESULTADO => P_RESULTADO) ;  
                    
                DBMS_OUTPUT.PUT_LINE('Resultado de insertar la nota: '||P_RESULTADO);    
                V_ERROR:=3;

            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Se ocasiono un error al insertar la nota del id_doc_clie: '||F_NORMALES.ID_DOC_CLIENTE);
                    V_ERROR:=0;                    
            END;
        END IF;
        
        IF V_ERROR=3 THEN
            BEGIN
                --cierra las alertas activas
                for f_alertas in C_ALERTAS(f_normales.id_documento, f_normales.cuenta) loop
                
                    P_ID_NOTA := f_alertas.id_nota;
                    P_LOGHASTA := GELEC.INSERT_LOG (P_DESCRIPCION_LOG, 'Aplicacion');
                    P_USUARIO := 'Aplicacion';
                    P_RESULTADO := NULL;

                    GELEC.PKG_NOTAS.DELETE_ALERTA (  
                        P_ID_NOTA => P_ID_NOTA,
                        P_LOGHASTA => P_LOGHASTA,
                        P_USUARIO => P_USUARIO,
                        P_RESULTADO => P_RESULTADO) ;  
                        
                    DBMS_OUTPUT.PUT_LINE('Resultado de la Alerta Cerrada: '||P_RESULTADO);    
                    V_ERROR:=4;
                    
                end loop;
                
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Se ocasiono un error al cerrar una alerta del id_doc_clie: '||F_NORMALES.ID_DOC_CLIENTE);
                    V_ERROR:=0;                    
            END;            
        END IF;
        
--        IF V_ERROR=4 THEN
--            DBMS_OUTPUT.PUT_LINE('Se normalizo automaticamente con exito el id_doc_clie: '||F_NORMALES.ID_DOC_CLIENTE);
--            COMMIT;
--        ELSE
--            DBMS_OUTPUT.PUT_LINE('Se aplica rollback para el id_doc_clie: '||F_NORMALES.ID_DOC_CLIENTE);
--            ROLLBACK;
--        END IF;
        
    END LOOP;
END;






