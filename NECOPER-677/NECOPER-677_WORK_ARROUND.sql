SET SERVEROUTPUT ON
DECLARE
    
    CURSOR C_INVERTIDO IS 
        SELECT DISTINCT ID_DOCUMENTO, CUENTA 
        FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES 
        WHERE FECHA_INICIO_CORTE>FECHA_FIN_CORTE 
        --AND CUENTA='3447906531'
        ORDER BY ID_DOCUMENTO, CUENTA      
    ;

    CURSOR C_GELEC (P_CTA VARCHAR2, P_DOC VARCHAR2) IS 
        SELECT ID_DOC_CLIENTE, FECHA_INICIO_CORTE, FECHA_FIN_CORTE, LOG_HASTA 
        FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES 
        WHERE CUENTA=P_CTA AND ID_DOCUMENTO=P_DOC
        ORDER BY ID_DOC_CLIENTE
    ;
    
    CURSOR C_OMS (P_CTA VARCHAR2, P_DOC VARCHAR2) IS
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
            AND ARO.DOCUMENT_ID=P_DOC
            AND C.CUENTA=P_CTA
        ORDER BY
            ARO.TIME ASC
        ;     
    
    V_FILA NUMBER;
    V_MATCH BOOLEAN;
    V_NOTA VARCHAR(300);
    V_ID NUMBER;
    V_FINI DATE;
    V_FFIN DATE;
    
    P_ID_NOTA VARCHAR(100);
    P_LOG_DESDE VARCHAR(100);

BEGIN
    --RECORRO AFECTACIONES CON FECHA INICIO SUPERIOR A FIN
    FOR F_INVERTIDO IN C_INVERTIDO LOOP
        DBMS_OUTPUT.PUT_LINE('CUENTA: '||F_INVERTIDO.CUENTA);
        DBMS_OUTPUT.PUT_LINE('ID_DOC: '||F_INVERTIDO.ID_DOCUMENTO);
        V_FILA:=0;
        --OBTENGO TODAS LAS AFECTACIONES, NO SOLO LAS ERRONEAS
        FOR F_GELEC IN C_GELEC(F_INVERTIDO.CUENTA, F_INVERTIDO.ID_DOCUMENTO) LOOP
            V_MATCH:=FALSE;
            V_FILA:= V_FILA+1;
            V_ID:= F_GELEC.ID_DOC_CLIENTE;
            V_FINI:=NULL;
            V_FFIN:=NULL;
            DBMS_OUTPUT.PUT_LINE('AFECTACION #'||V_ID||' NRO DE FILA: '||V_FILA);
            --OBTENGO LAS FECHA CORRECTAS EN TODAS LAS AFECTACIONES
            FOR F_OMS IN C_OMS(F_INVERTIDO.CUENTA, F_INVERTIDO.ID_DOCUMENTO) LOOP
                IF F_OMS.NUM_FILA=V_FILA THEN
                    V_MATCH:=TRUE;
                    V_FINI:=F_OMS.FECHA_INICIO;
                    V_FFIN:=F_OMS.FECHA_RESTAURACION;
                END IF;
            END LOOP;
            --PREGUNTO SI HUVO MATCH
            IF V_MATCH=TRUE THEN
                --ACTUALIZO POR LAS FECHAS CORRECTAS DE OMS
                V_NOTA:=' INICIO: '||F_GELEC.FECHA_INICIO_CORTE||' POR '||V_FINI||' FIN: '||F_GELEC.FECHA_FIN_CORTE||' POR '||V_FFIN;    
				DBMS_OUTPUT.PUT_LINE('ACTUALIZA>> '||V_NOTA);
				BEGIN
					UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES
					SET 
						FECHA_INICIO_CORTE= V_FINI, 
						FECHA_FIN_CORTE= V_FFIN
					WHERE 
						ID_DOC_CLIENTE= V_ID
					;
				EXCEPTION
					WHEN OTHERS THEN
						DBMS_OUTPUT.PUT_LINE('ID: '||V_ID||' Error al actualizar');
				END;
            ELSE
                --ACTUALIZO POR LAS FECHAS CORRECTAS DE OMS
                V_NOTA:=' '||F_GELEC.FECHA_FIN_CORTE||' POR '||F_GELEC.FECHA_INICIO_CORTE;    
				DBMS_OUTPUT.PUT_LINE('ANULA>> '||V_NOTA);
				BEGIN
					UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES
					SET 
						FECHA_FIN_CORTE= FECHA_INICIO_CORTE
					WHERE 
						ID_DOC_CLIENTE= V_ID
					;            
				EXCEPTION
					WHEN OTHERS THEN
						DBMS_OUTPUT.PUT_LINE('ID: '||V_ID||' Error al actualizar');
				END;
            END IF;
			BEGIN
				--INSERTO NOTA
				GELEC.PKG_NOTAS.INSERTAR_NOTA (  
					P_USER_ID => 'BATCH',
					P_NOTA => 'Se actualizo afectacion #'||V_ID||' > '||V_NOTA, 
					P_ID_DESTINO => NULL,
					P_EFECTIVO => NULL,
					P_ID_TIPO_NOTA => 1,
					P_ID_SUBTIPO_NOTA => 4,
					P_ID_FECHA_ALERTA => NULL,
					P_DESCRIPCION_LOG => 'Modifica Fecha de Afectacion: ',
					P_ORIGEN => 'BATCH',
					P_ID_NOTA => P_ID_NOTA,
					P_LOG_DESDE => P_LOG_DESDE
				) ;  
				DBMS_OUTPUT.PUT_LINE(
					'Insertamos nota>>'||
					' ID_NOTA: '||P_ID_NOTA||
					' LOG_DESDE: '||P_LOG_DESDE
				);   
			EXCEPTION
				WHEN OTHERS THEN
					DBMS_OUTPUT.PUT_LINE('ID: '||V_ID||' Error al crear la nota.');
			END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------');
    END LOOP;

    COMMIT;

END;