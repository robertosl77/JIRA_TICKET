--Actualiza ct cliente y estado a partir del nro de cuenta  y nro doc.
CREATE OR REPLACE FUNCTION ACTUALIZA_CLIENTE_DOC (p_id_documento number,p_cuenta varchar2,p_ct_clie varchar2, p_estado_clie varchar2, p_solucion_provisoria varchar2, p_usuario varchar2)
   RETURN NUMBER
IS
   v_id_documento       NUMBER(10);
   v_cuenta             VARCHAR2(30);
   v_ct_clie            VARCHAR2(20);
   v_estado_clie        VARCHAR2(30);
   v_ct_clie_act        VARCHAR2(20);
   v_estado_clie_act    VARCHAR2(30); 
   v_solucion_provisoria VARCHAR2(30);
   v_solucion_provisoria_act VARCHAR2(30);
   v_id_doc_cliente_old NUMBER(10);
   v_id_doc_cliente_new NUMBER(10);
   v_detalle            VARCHAR2(100);
   v_usuario            VARCHAR2(50);
   v_logid              NUMBER;
      
BEGIN
   v_id_documento:=p_id_documento;
   v_cuenta:=p_cuenta;
   v_ct_clie:=p_ct_clie;
   v_estado_clie:=p_estado_clie;
   v_usuario:=p_usuario;
   v_solucion_provisoria:=p_solucion_provisoria;
    
     select id_doc_cliente,ct_clie,estado_clie,solucion_provisoria
     into  v_id_doc_cliente_old,v_ct_clie_act,v_estado_clie_act,v_solucion_provisoria_act
     from GELEC.ED_DET_DOCUMENTOS_CLIENTES 
     where id_documento= v_id_documento
     and  cuenta=v_cuenta
     and log_hasta is null;
     
     
            if v_ct_clie_act != v_ct_clie or v_estado_clie_act!=v_estado_clie or v_solucion_provisoria_act!=v_solucion_provisoria then 
                    v_detalle:= 'Actualiza Cuenta del Documento';     
                    v_logid := GELEC.INSERT_LOG(v_detalle,v_usuario);
            
                    UPDATE GELEC.ED_DET_DOCUMENTOS_CLIENTES
                    set LOG_HASTA =  v_logid
                    where  id_doc_cliente = v_id_doc_cliente_old; 

                    select nvl(max(ID_DOC_CLIENTE),0)+1
                    into   v_id_doc_cliente_new
                    from GELEC.ED_DET_DOCUMENTOS_CLIENTES;



                    INSERT INTO GELEC.ED_DET_DOCUMENTOS_CLIENTES
                       (ID_DOC_CLIENTE,ID_DOCUMENTO,CUENTA,CT_CLIE,ESTADO_CLIE,SOLUCION_PROVISORIA,
                        RECLAMO_CLIE,REITERACION_CLIE,FECHA_INICIO_RECL,LOG_DESDE,LOG_HASTA)
                    SELECT v_id_doc_cliente_new,ID_DOCUMENTO,CUENTA,v_ct_clie,v_estado_clie,v_solucion_provisoria,
                        RECLAMO_CLIE,REITERACION_CLIE,FECHA_INICIO_RECL,v_logid,null
                    FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES
                    WHERE ID_DOC_CLIENTE = v_id_doc_cliente_old;
        
                    INSERT INTO gelec.ed_auditoria (AUDITORIA_LOG,
                                                  ACCION,
                                                  VALOR,
                                                  FECHA,
                                                  USUARIO)
                       VALUES (
                                  v_logid,
                                  'Actualiza cliente Documento',
                                  (SELECT v_id_doc_cliente_new
									   ||'|'||ID_DOCUMENTO
									   ||'|'||CUENTA
									   ||'|'||v_ct_clie
									   ||'|'||v_estado_clie
									   ||'|'||v_solucion_provisoria
									   ||'|'||RECLAMO_CLIE
									   ||'|'||REITERACION_CLIE
									   ||'|'||FECHA_INICIO_RECL
									   ||'|'||v_logid
									   ||'|'||null
								  FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES
								  WHERE ID_DOC_CLIENTE = v_id_doc_cliente_old),
                                  SYSDATE,
                                  p_usuario);

            end if;

  COMMIT;
  RETURN v_id_doc_cliente_new;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      RETURN -1;
END;

