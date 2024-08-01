SELECT * FROM GELEC.ED_DET_DOCUMENTOS_CLIENTES WHERE ID_DOCUMENTO=9085813;

update ed_det_documentos_clientes set fecha_fin_corte=null where id_doc_cliente=71243;
update ed_det_documentos_clientes set fecha_fin_corte= to_date('30/01/2021 17:00:00') where id_doc_cliente=71244;
update ed_det_documentos_clientes set fecha_fin_corte= to_date('30/01/2021 17:00:00') where id_doc_cliente=71245;
update ed_det_documentos_clientes set estado_clie='Seguimiento' where id_doc_cliente=71246;
select * from gelec.ed_reclamos;
--update gelec.ed_reclamos set id_documento=9085813, cuenta='8832006706' where id_reclamo=18413870;
update gelec.ed_reclamos set id_documento=9085813, cuenta='8832006706' where id_reclamo=18435349;

SET SERVEROUTPUT ON
DECLARE
  P_USER_ID VARCHAR2(200);
  P_RESULTADO VARCHAR2(200);    
BEGIN
  P_USER_ID := NULL;
  P_RESULTADO := NULL;

  PKG_BATCH.buscar_doc_edp_afectados_nuevo (  P_USER_ID => P_USER_ID, P_RESULTADO => P_RESULTADO) ;  
  
  DBMS_OUTPUT.PUT_LINE(P_RESULTADO );
END;

