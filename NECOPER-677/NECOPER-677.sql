         ---------------------------------------------------------------------
         --rsleiva 
         --NECOPER-677
         --se agregaron las variables v_tmp_fini y v_tmp_ffin
         --al cursor c_documentos_afectados se le agrego un nuevo campo 'id_afectacion', este se relaciona OMS_AFFECTED_ELEMENT.ID con NBM_MON_ELEMENT.ID
         --si la fecha de inicio es superior a la fecha de fin y si el nuevo campo id_afectacion es >0
         IF DOCUMENTO.FECHA_INICIO>DOCUMENTO.FECHA_RESTAURACION then
            IF DOCUMENTO.ID_AFECTACION=-1 THEN
                DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y origen: afectacion por cliente');
            ELSIF DOCUMENTO.ID_AFECTACION=-2 THEN
                DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y origen: afectacion por reclamo');
            ELSIF DOCUMENTO.ID_AFECTACION>0 THEN
                BEGIN
                    --busco la fecha de inicio
                    SELECT ARO.TIME 
                    INTO V_TMP_FINI
                    FROM NEXUS_GIS.OMS_AFFECTED_ELEMENT AE, NEXUS_GIS.OMS_AFFECT_RESTORE_OPERATION	ARO 
                    where ae.affect_id=aro.id and aro.document_id=documento.documento and ae.id=documento.id_afectacion and aro.is_restore=0 and aro.operation_id is not null;
                    --reemplazolas fechas del cursor documento por las que se acaban de obtener
                    DOCUMENTO.FECHA_INICIO:= V_TMP_FINI;
                    
                    DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y se reemplazo la fecha de inicio por '||V_TMP_FINI);
                    
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y se ha producido un error con la fecha de inicio '||V_TMP_FINI);
                END;
                BEGIN
                    --busco la fecha de restauracion
                    SELECT ARO.TIME
                    INTO V_TMP_FFIN
                    FROM NEXUS_GIS.OMS_AFFECTED_ELEMENT AE, NEXUS_GIS.OMS_AFFECT_RESTORE_OPERATION	ARO 
                    WHERE AE.AFFECT_ID=ARO.ID AND ARO.DOCUMENT_ID=documento.documento AND AE.ID=documento.id_afectacion AND ARO.IS_RESTORE=1 AND ARO.OPERATION_ID IS NOT NULL;
                    --reemplazolas fechas del cursor documento por las que se acaban de obtener
                    DOCUMENTO.FECHA_RESTAURACION:=V_TMP_FFIN;
                    
                    DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y se reemplazo la fecha de restauracion por '||V_TMP_FFIN);
                    
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('Fecha de inicio ('||DOCUMENTO.FECHA_INICIO||') superior a fecha de fin('||DOCUMENTO.FECHA_RESTAURACION||'), en documento '||DOCUMENTO.DOCUMENTO||' y se ha producido un error con la fecha de restauracion '||V_TMP_FFIN);
                END;
            end if;    
         END IF;
         ---------------------------------------------------------------------
